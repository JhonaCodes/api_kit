/// Ejemplo de uso de @Param
/// Demuestra el uso genérico de parámetros con diferentes tipos y validaciones
library;

import 'dart:convert';
import 'dart:io';
import 'package:api_kit/api_kit.dart';

void main() async {
  print('🔧 Param Example - General parameter handling');

  final server = ApiServer.create()
    .configureEndpointDisplay(showInConsole: true);

  final result = await server.start(
    host: 'localhost',
    port: 8092,
    projectPath: Directory.current.path,
  );

  result.when(
    ok: (httpServer) {
      print('\n🧪 Test Param endpoints:');
      print('   # Basic parameter validation:');
      print('   curl -X POST -H "Content-Type: application/json" -d \'{"user_id":"123","action":"login"}\' http://localhost:8092/api/validate');
      print('   # Complex parameter handling:');
      print('   curl -X POST -H "Content-Type: application/json" -d \'{"email":"user@example.com","age":25,"preferences":["dark_mode","notifications"]}\' http://localhost:8092/api/settings');
      print('   # Optional parameters:');
      print('   curl -X POST -H "Content-Type: application/json" -d \'{"name":"John","description":"Optional field"}\' http://localhost:8092/api/profile');
      print('\n⚠️  Press Ctrl+C to stop');
    },
    err: (error) {
      print('❌ Error: $error');
    },
  );
}

/// Controller demostrando el uso de @Param
@RestController(basePath: '/api')
class ParamController extends BaseController {

  /// Ejemplo básico: validación de parámetros simples
  @Post(path: '/validate')
  Future<Response> validateAction(
    Request request,
    @Param('user_id', description: 'User identifier', required: true) String userId,
    @Param('action', description: 'Action to validate', required: true) String action,
  ) async {
    
    // Simulación de validación de acción
    final validActions = ['login', 'logout', 'update_profile', 'change_password'];
    final isValidAction = validActions.contains(action);
    
    return jsonResponse(jsonEncode({
      'message': 'Action validation completed',
      'params_received': {
        'user_id': userId,
        'action': action,
      },
      'validation': {
        'user_id_valid': userId.isNotEmpty,
        'action_valid': isValidAction,
        'allowed_actions': validActions,
      },
      'result': {
        'success': userId.isNotEmpty && isValidAction,
        'can_proceed': userId.isNotEmpty && isValidAction,
      },
    }));
  }

  /// Ejemplo complejo: múltiples parámetros con diferentes tipos
  @Post(path: '/settings')
  Future<Response> updateSettings(
    Request request,
    @Param('email', required: true, description: 'User email address') String email,
    @Param('age', required: true, description: 'User age') int age,
    @Param('preferences', required: false, defaultValue: [], description: 'User preferences list') List<String> preferences,
    @Param('theme', required: false, defaultValue: 'light', description: 'UI theme preference') String theme,
    @Param('notifications_enabled', required: false, defaultValue: true, description: 'Enable notifications') bool notificationsEnabled,
  ) async {
    
    // Validaciones complejas
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    final isValidEmail = emailRegex.hasMatch(email);
    final isValidAge = age >= 13 && age <= 120;
    final validThemes = ['light', 'dark', 'auto'];
    final isValidTheme = validThemes.contains(theme);
    
    // Análisis de preferencias
    final availablePreferences = ['dark_mode', 'notifications', 'analytics', 'marketing', 'sync'];
    final validPreferences = preferences.where((pref) => availablePreferences.contains(pref)).toList();
    
    return jsonResponse(jsonEncode({
      'message': 'Settings update processed',
      'received_params': {
        'email': email,
        'age': age,
        'preferences': preferences,
        'theme': theme,
        'notifications_enabled': notificationsEnabled,
      },
      'validations': {
        'email': {
          'valid': isValidEmail,
          'pattern': 'email format',
        },
        'age': {
          'valid': isValidAge,
          'range': '13-120 years',
        },
        'theme': {
          'valid': isValidTheme,
          'allowed': validThemes,
        },
        'preferences': {
          'received': preferences.length,
          'valid': validPreferences.length,
          'available': availablePreferences,
        },
      },
      'processed_settings': {
        'email': isValidEmail ? email : 'invalid_email',
        'age': isValidAge ? age : 0,
        'theme': isValidTheme ? theme : 'light',
        'preferences': validPreferences,
        'notifications_enabled': notificationsEnabled,
      },
      'update_summary': {
        'all_valid': isValidEmail && isValidAge && isValidTheme,
        'can_save': isValidEmail && isValidAge,
        'warnings': !isValidTheme ? ['Invalid theme defaulted to light'] : [],
      },
    }));
  }

  /// Ejemplo con parámetros opcionales y valores por defecto
  @Post(path: '/profile')
  Future<Response> createProfile(
    Request request,
    @Param('name', required: true, description: 'Profile name') String name,
    @Param('description', required: false, description: 'Profile description') String? description,
    @Param('avatar_url', required: false, description: 'Profile avatar URL') String? avatarUrl,
    @Param('is_public', required: false, defaultValue: false, description: 'Public profile visibility') bool isPublic,
    @Param('tags', required: false, defaultValue: [], description: 'Profile tags') List<String> tags,
    @Param('created_by', required: false, defaultValue: 'system', description: 'Profile creator') String createdBy,
  ) async {
    
    // Procesamiento de perfil
    final profileId = 'profile_${DateTime.now().millisecondsSinceEpoch}';
    final processedDescription = description?.trim().isEmpty == true ? null : description;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;
    
    // Validación de tags
    final maxTags = 5;
    final filteredTags = tags.take(maxTags).toList();
    final tagsLimited = tags.length > maxTags;
    
    return jsonResponse(jsonEncode({
      'message': 'Profile created successfully',
      'profile_id': profileId,
      'input_params': {
        'name': name,
        'description': description,
        'avatar_url': avatarUrl,
        'is_public': isPublic,
        'tags': tags,
        'created_by': createdBy,
      },
      'processed_profile': {
        'id': profileId,
        'name': name,
        'description': processedDescription ?? 'No description provided',
        'has_avatar': hasAvatar,
        'avatar_url': hasAvatar ? avatarUrl : null,
        'visibility': isPublic ? 'public' : 'private',
        'tags': filteredTags,
        'created_by': createdBy,
        'created_at': DateTime.now().toIso8601String(),
      },
      'processing_info': {
        'description_provided': processedDescription != null,
        'avatar_provided': hasAvatar,
        'tags_count': filteredTags.length,
        'tags_limited': tagsLimited,
        'max_tags_allowed': maxTags,
      },
      'profile_stats': {
        'complete_fields': [
          name.isNotEmpty,
          processedDescription != null,
          hasAvatar,
          filteredTags.isNotEmpty,
        ].where((field) => field).length,
        'total_fields': 4,
        'completion_percentage': (([
          name.isNotEmpty,
          processedDescription != null,
          hasAvatar,
          filteredTags.isNotEmpty,
        ].where((field) => field).length / 4) * 100).round(),
      },
    }));
  }
}