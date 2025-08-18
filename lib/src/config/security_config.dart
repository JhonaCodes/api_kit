/// Configuration classes for security features.
library;

/// Rate limiting configuration.
class RateLimitConfig {
  final int maxRequests;
  final Duration window;
  final int maxRequestsPerIP;

  const RateLimitConfig({
    required this.maxRequests,
    required this.window,
    required this.maxRequestsPerIP,
  });

  /// Default production configuration.
  factory RateLimitConfig.production() {
    return const RateLimitConfig(
      maxRequests: 100,
      window: Duration(minutes: 1),
      maxRequestsPerIP: 1000,
    );
  }

  /// Development configuration with relaxed limits.
  factory RateLimitConfig.development() {
    return const RateLimitConfig(
      maxRequests: 1000,
      window: Duration(minutes: 1),
      maxRequestsPerIP: 10000,
    );
  }
}

/// CORS configuration.
class CorsConfig {
  final List<String> allowedOrigins;
  final List<String> allowedMethods;
  final List<String> allowedHeaders;
  final bool credentials;

  const CorsConfig({
    required this.allowedOrigins,
    required this.allowedMethods,
    required this.allowedHeaders,
    required this.credentials,
  });

  /// Default production CORS configuration.
  factory CorsConfig.production() {
    return const CorsConfig(
      allowedOrigins: [], // Must be configured per environment
      allowedMethods: ['GET', 'POST', 'PUT', 'DELETE'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      credentials: true,
    );
  }

  /// Development CORS configuration (permissive).
  factory CorsConfig.development() {
    return const CorsConfig(
      allowedOrigins: ['*'],
      allowedMethods: ['*'],
      allowedHeaders: ['*'],
      credentials: false,
    );
  }
}

/// Main server configuration.
class ServerConfig {
  final RateLimitConfig rateLimit;
  final CorsConfig cors;
  final int maxBodySize;
  final bool enableHttps;
  final List<String> trustedProxies;

  const ServerConfig({
    required this.rateLimit,
    required this.cors,
    required this.maxBodySize,
    required this.enableHttps,
    required this.trustedProxies,
  });

  /// Production server configuration.
  factory ServerConfig.production() {
    return ServerConfig(
      rateLimit: RateLimitConfig.production(),
      cors: CorsConfig.production(),
      maxBodySize: 10 * 1024 * 1024, // 10MB
      enableHttps: true,
      trustedProxies: const ['127.0.0.1', '10.0.0.0/8'],
    );
  }

  /// Development server configuration.
  factory ServerConfig.development() {
    return ServerConfig(
      rateLimit: RateLimitConfig.development(),
      cors: CorsConfig.development(),
      maxBodySize: 50 * 1024 * 1024, // 50MB for dev
      enableHttps: false,
      trustedProxies: const ['*'],
    );
  }
}