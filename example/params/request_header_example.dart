/// Ejemplo de uso de @RequestHeader
/// Demuestra cómo capturar y validar headers HTTP para autenticación, configuración y metadatos
library;

import 'dart:convert';
import 'dart:io';
import 'package:api_kit/api_kit.dart';

void main() async {
  print('📋 RequestHeader Example - Capturing HTTP headers');

  final server = ApiServer.create()
    .configureEndpointDisplay(showInConsole: true);

  final result = await server.start(
    host: 'localhost',
    port: 8094,
    projectPath: Directory.current.path,
  );

  result.when(
    ok: (httpServer) {
      print('\n🧪 Test RequestHeader endpoints:');
      print('   # Basic authentication header:');
      print('   curl -H "Authorization: Bearer abc123" http://localhost:8094/api/profile');
      print('   # Multiple headers with API key:');
      print('   curl -H "X-API-Key: api_key_123" -H "X-Client-Version: 1.2.3" -H "User-Agent: MyApp/1.0" http://localhost:8094/api/data');
      print('   # Content negotiation:');
      print('   curl -H "Accept: application/json" -H "Accept-Language: en-US,es;q=0.9" -H "X-Timezone: America/New_York" http://localhost:8094/api/localized');
      print('   # Optional headers (some missing):');
      print('   curl -H "X-Request-ID: req_123" http://localhost:8094/api/optional-headers');
      print('\n⚠️  Press Ctrl+C to stop');
    },
    err: (error) {
      print('❌ Error: $error');
    },
  );
}

/// Controller demostrando el uso de @RequestHeader
@RestController(basePath: '/api')
class RequestHeaderController extends BaseController {

  /// Ejemplo básico: header de autorización requerido
  @Get(path: '/profile')
  Future<Response> getUserProfile(
    Request request,
    @RequestHeader('Authorization', required: true, description: 'Bearer token for authentication') String authHeader,
  ) async {
    
    // Validar formato del token Bearer
    if (!authHeader.startsWith('Bearer ')) {
      return Response.unauthorized(jsonEncode({
        'error': 'Invalid authorization format',
        'expected_format': 'Bearer <token>',
        'received': authHeader.length > 20 ? '${authHeader.substring(0, 20)}...' : authHeader,
      }));
    }
    
    final token = authHeader.substring(7); // Remover "Bearer "
    
    // Validación básica del token (simulada)
    if (token.length < 10) {
      return Response.unauthorized(jsonEncode({
        'error': 'Invalid token',
        'message': 'Token too short',
        'minimum_length': 10,
      }));
    }
    
    // Simulación de decodificación de token
    final userId = 'user_${token.hashCode.abs()}';
    
    return jsonResponse(jsonEncode({
      'message': 'Profile retrieved successfully',
      'authentication': {
        'header_received': 'Authorization',
        'token_format': 'Bearer',
        'token_length': token.length,
        'token_valid': true,
      },
      'user_profile': {
        'user_id': userId,
        'name': 'User from Token',
        'email': 'user@example.com',
        'authenticated_at': DateTime.now().toIso8601String(),
      },
      'security_info': {
        'token_expires_in': '1 hour',
        'scopes': ['profile:read', 'data:read'],
        'issued_at': DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
      },
    }));
  }

  /// Ejemplo con múltiples headers requeridos
  @Get(path: '/data')
  Future<Response> getApiData(
    Request request,
    @RequestHeader('X-API-Key', required: true, description: 'API key for service access') String apiKey,
    @RequestHeader('X-Client-Version', required: true, description: 'Client application version') String clientVersion,
    @RequestHeader('User-Agent', required: false, defaultValue: 'Unknown', description: 'Client user agent') String userAgent,
  ) async {
    
    // Validar API key (simulado)
    final validApiKeys = ['api_key_123', 'api_key_456', 'api_key_789'];
    if (!validApiKeys.contains(apiKey)) {
      return Response.forbidden(jsonEncode({
        'error': 'Invalid API key',
        'api_key_received': apiKey.length > 10 ? '${apiKey.substring(0, 10)}...' : apiKey,
        'hint': 'Contact support for a valid API key',
      }));
    }
    
    // Validar versión del cliente
    final versionRegex = RegExp(r'^\d+\.\d+\.\d+$');
    final isValidVersion = versionRegex.hasMatch(clientVersion);
    
    // Parsear versión
    Map<String, dynamic>? versionInfo;
    if (isValidVersion) {
      final parts = clientVersion.split('.');
      versionInfo = {
        'major': int.parse(parts[0]),
        'minor': int.parse(parts[1]),
        'patch': int.parse(parts[2]),
        'is_supported': int.parse(parts[0]) >= 1,
        'requires_update': int.parse(parts[0]) < 2,
      };
    }
    
    return jsonResponse(jsonEncode({
      'message': 'API data retrieved successfully',
      'headers_received': {
        'api_key': '${apiKey.substring(0, 8)}...',
        'client_version': clientVersion,
        'user_agent': userAgent,
      },
      'validation': {
        'api_key_valid': true,
        'version_format_valid': isValidVersion,
        'version_supported': versionInfo?['is_supported'] ?? false,
      },
      'client_info': {
        'version_details': versionInfo,
        'user_agent_analysis': {
          'length': userAgent.length,
          'contains_app_name': userAgent.toLowerCase().contains('myapp'),
          'is_default': userAgent == 'Unknown',
        },
      },
      'api_response': {
        'data': ['item1', 'item2', 'item3'],
        'total_count': 3,
        'api_version': '2.1.0',
        'response_time_ms': 45,
      },
      'deprecation_warnings': versionInfo?['requires_update'] == true ? [
        'Client version $clientVersion is deprecated',
        'Please update to version 2.0.0 or later',
      ] : [],
    }));
  }

  /// Ejemplo de localización y configuración mediante headers
  @Get(path: '/localized')
  Future<Response> getLocalizedContent(
    Request request,
    @RequestHeader('Accept', required: false, defaultValue: 'application/json', description: 'Content type preference') String accept,
    @RequestHeader('Accept-Language', required: false, defaultValue: 'en-US', description: 'Language preference') String acceptLanguage,
    @RequestHeader('X-Timezone', required: false, defaultValue: 'UTC', description: 'User timezone') String timezone,
  ) async {
    
    // Parsear Accept header
    final acceptsJson = accept.contains('application/json');
    final acceptsXml = accept.contains('application/xml');
    final preferredFormat = acceptsJson ? 'json' : (acceptsXml ? 'xml' : 'unknown');
    
    // Parsear Accept-Language (formato: en-US,es;q=0.9,fr;q=0.8)
    final languages = acceptLanguage.split(',').map((lang) {
      final parts = lang.trim().split(';');
      final langCode = parts[0].trim();
      final quality = parts.length > 1 ? 
        double.tryParse(parts[1].replaceAll('q=', '').trim()) ?? 1.0 : 1.0;
      return {'code': langCode, 'quality': quality};
    }).toList();
    
    // Ordenar por calidad (q-value)
    languages.sort((a, b) => (b['quality'] as double).compareTo(a['quality'] as double));
    final preferredLanguage = languages.isNotEmpty ? languages.first['code'] as String : 'en-US';
    
    // Validar timezone
    final validTimezones = [
      'UTC', 'America/New_York', 'Europe/London', 'Asia/Tokyo', 
      'America/Los_Angeles', 'Europe/Madrid', 'Asia/Shanghai'
    ];
    final isValidTimezone = validTimezones.contains(timezone);
    final effectiveTimezone = isValidTimezone ? timezone : 'UTC';
    
    // Simular contenido localizado
    final now = DateTime.now();
    final localizedMessages = {
      'en-US': 'Welcome to our localized API',
      'es': 'Bienvenido a nuestra API localizada',
      'fr': 'Bienvenue dans notre API localisée',
      'de': 'Willkommen bei unserer lokalisierten API',
    };
    
    final message = localizedMessages[preferredLanguage.split('-').first] ?? 
                   localizedMessages['en-US']!;
    
    return jsonResponse(jsonEncode({
      'message': message,
      'localization': {
        'content_format': preferredFormat,
        'language': preferredLanguage,
        'timezone': effectiveTimezone,
        'timestamp': now.toIso8601String(),
      },
      'headers_analysis': {
        'accept': {
          'raw': accept,
          'supports_json': acceptsJson,
          'supports_xml': acceptsXml,
          'preferred_format': preferredFormat,
        },
        'accept_language': {
          'raw': acceptLanguage,
          'parsed_languages': languages,
          'preferred': preferredLanguage,
          'fallback_applied': preferredLanguage == 'en-US' && acceptLanguage != 'en-US',
        },
        'timezone': {
          'requested': timezone,
          'valid': isValidTimezone,
          'effective': effectiveTimezone,
          'fallback_applied': !isValidTimezone,
        },
      },
      'localized_content': {
        'greeting': message,
        'current_time': now.toIso8601String(),
        'date_format': preferredLanguage.startsWith('en') ? 'MM/DD/YYYY' : 'DD/MM/YYYY',
        'number_format': preferredLanguage.startsWith('en') ? '1,234.56' : '1.234,56',
      },
      'available_languages': localizedMessages.keys.toList(),
      'supported_timezones': validTimezones,
    }));
  }

  /// Ejemplo con headers completamente opcionales
  @Get(path: '/optional-headers')
  Future<Response> handleOptionalHeaders(
    Request request,
    @RequestHeader('X-Request-ID', required: false, description: 'Request tracking ID') String? requestId,
    @RequestHeader('X-Debug-Mode', required: false, description: 'Enable debug mode') String? debugMode,
    @RequestHeader('X-Feature-Flags', required: false, description: 'Feature flags list') String? featureFlags,
    @RequestHeader('X-Source-App', required: false, description: 'Source application name') String? sourceApp,
  ) async {
    
    // Generar request ID si no se proporciona
    final effectiveRequestId = requestId ?? 'req_${DateTime.now().millisecondsSinceEpoch}';
    
    // Parsear debug mode
    final debugEnabled = debugMode?.toLowerCase() == 'true' || debugMode == '1';
    
    // Parsear feature flags (formato: "flag1,flag2,flag3")
    final flags = featureFlags?.split(',').map((f) => f.trim()).where((f) => f.isNotEmpty).toList() ?? [];
    
    // Información del source app
    final sourceInfo = sourceApp != null ? {
      'name': sourceApp,
      'provided': true,
      'is_mobile': sourceApp.toLowerCase().contains('mobile'),
      'is_web': sourceApp.toLowerCase().contains('web'),
    } : {
      'name': 'unknown',
      'provided': false,
      'is_mobile': false,
      'is_web': false,
    };
    
    return jsonResponse(jsonEncode({
      'message': 'Optional headers processed',
      'request_tracking': {
        'request_id': effectiveRequestId,
        'request_id_provided': requestId != null,
        'generated': requestId == null,
        'timestamp': DateTime.now().toIso8601String(),
      },
      'debug_info': {
        'debug_mode': debugEnabled,
        'debug_header_provided': debugMode != null,
        'debug_raw_value': debugMode,
      },
      'feature_configuration': {
        'feature_flags': flags,
        'flags_count': flags.length,
        'flags_provided': featureFlags != null,
        'active_features': flags.where((f) => f.startsWith('enable_')).toList(),
      },
      'client_info': sourceInfo,
      'headers_summary': {
        'total_optional_headers': 4,
        'headers_provided': [
          requestId != null,
          debugMode != null, 
          featureFlags != null,
          sourceApp != null,
        ].where((h) => h).length,
        'headers_missing': [
          requestId == null,
          debugMode == null,
          featureFlags == null,
          sourceApp == null,
        ].where((h) => h).length,
      },
      'processing_notes': {
        'request_id_generated': requestId == null,
        'debug_mode_default': !debugEnabled && debugMode == null,
        'no_feature_flags': flags.isEmpty,
        'unknown_source': sourceApp == null,
      },
      'response_data': {
        'items': debugEnabled ? 
          ['debug_item_1', 'debug_item_2', 'debug_metadata'] :
          ['item_1', 'item_2'],
        'debug_info_included': debugEnabled,
        'personalized_for_app': sourceApp != null,
      },
    }));
  }
}