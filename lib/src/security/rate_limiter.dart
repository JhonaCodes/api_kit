import 'package:shelf/shelf.dart';
import 'package:logger_rs/logger_rs.dart';

import '../config/server_config.dart';

/// Rate limiter implementation for API protection.
class RateLimiter {
  final Map<String, List<DateTime>> _requests = {};
  final Map<String, int> _blacklist = {};

  /// Creates rate limiting middleware.
  Middleware create(RateLimitConfig config) {
    return (Handler handler) {
      return (Request request) async {
        final ip = _getClientIp(request);
        
        // Check blacklist
        if (_blacklist.containsKey(ip)) {
          final bannedUntil = _blacklist[ip]!;
          if (DateTime.now().millisecondsSinceEpoch < bannedUntil) {
            Log.w('Blocked request from banned IP: $ip');
            return Response(429, body: 'IP temporarily banned');
          } else {
            _blacklist.remove(ip);
          }
        }

        final now = DateTime.now();
        _requests[ip] ??= [];

        // Clean old requests
        _requests[ip]!.removeWhere(
          (time) => now.difference(time) > config.window,
        );

        // Check rate limit
        if (_requests[ip]!.length >= config.maxRequests) {
          Log.w('Rate limit exceeded for IP: $ip');
          
          // Ban IP for repeated violations
          final violations = _requests['${ip}_violations'] ??= [];
          violations.add(now);
          
          if (violations.length >= 5) {
            // Ban for 1 hour
            _blacklist[ip] = now.add(const Duration(hours: 1)).millisecondsSinceEpoch;
            Log.w('IP banned for 1 hour: $ip');
            return Response(429, body: 'IP banned for 1 hour');
          }

          return Response(
            429,
            headers: {
              'Retry-After': '${config.window.inSeconds}',
              'X-RateLimit-Limit': '${config.maxRequests}',
              'X-RateLimit-Remaining': '0',
              'X-RateLimit-Reset': '${now.add(config.window).millisecondsSinceEpoch}',
            },
            body: 'Rate limit exceeded',
          );
        }

        _requests[ip]!.add(now);

        // Add rate limit headers to response
        final response = await handler(request);
        return response.change(headers: {
          ...response.headers,
          'X-RateLimit-Limit': '${config.maxRequests}',
          'X-RateLimit-Remaining': '${config.maxRequests - _requests[ip]!.length}',
        });
      };
    };
  }

  /// Extracts client IP from request headers.
  String _getClientIp(Request request) {
    // Check headers in order (for reverse proxies)
    return request.headers['x-real-ip'] ??
        request.headers['x-forwarded-for']?.split(',').first.trim() ??
        'unknown';
  }
}