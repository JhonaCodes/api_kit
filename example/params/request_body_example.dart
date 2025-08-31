/// Ejemplo de uso de @RequestBody
/// Demuestra cómo manejar el body de requests HTTP con diferentes formatos y validaciones
library;

import 'dart:convert';
import 'dart:io';
import 'package:api_kit/api_kit.dart';

void main() async {
  print('📦 RequestBody Example - Handling HTTP request bodies');

  final server = ApiServer.create()
    .configureEndpointDisplay(showInConsole: true);

  final result = await server.start(
    host: 'localhost',
    port: 8093,
    projectPath: Directory.current.path,
  );

  result.when(
    ok: (httpServer) {
      print('\n🧪 Test RequestBody endpoints:');
      print('   # Simple JSON body:');
      print('   curl -X POST -H "Content-Type: application/json" -d \'{"message":"Hello World"}\' http://localhost:8093/api/simple-message');
      print('   # Complex user data:');
      print('   curl -X POST -H "Content-Type: application/json" -d \'{"name":"John Doe","email":"john@example.com","profile":{"age":30,"interests":["tech","music"]}}\' http://localhost:8093/api/users');
      print('   # Form data (optional body):');
      print('   curl -X POST -H "Content-Type: application/json" -d \'{"title":"Optional Title"}\' http://localhost:8093/api/posts');
      print('   # File upload simulation:');
      print('   curl -X POST -H "Content-Type: application/json" -d \'{"filename":"document.pdf","content_type":"application/pdf","size":1024,"metadata":{"description":"Important document"}}\' http://localhost:8093/api/upload');
      print('\n⚠️  Press Ctrl+C to stop');
    },
    err: (error) {
      print('❌ Error: $error');
    },
  );
}

/// Controller demostrando el uso de @RequestBody
@RestController(basePath: '/api')
class RequestBodyController extends BaseController {

  /// Ejemplo básico: body simple requerido
  @Post(path: '/simple-message')
  Future<Response> createSimpleMessage(
    Request request,
    @RequestBody(required: true, description: 'Simple message data') Map<String, dynamic> messageData,
  ) async {
    
    final message = messageData['message'] as String?;
    final timestamp = messageData['timestamp'] as String?;
    
    // Validación básica
    if (message == null || message.isEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Message is required',
        'received_data': messageData,
      }));
    }
    
    return jsonResponse(jsonEncode({
      'status': 'Message created successfully',
      'received_data': messageData,
      'processed_message': {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'content': message,
        'length': message.length,
        'timestamp': timestamp ?? DateTime.now().toIso8601String(),
        'has_timestamp': timestamp != null,
      },
      'validation': {
        'message_valid': message.isNotEmpty,
        'message_length': message.length,
        'max_length': 500,
        'within_limits': message.length <= 500,
      },
    }));
  }

  /// Ejemplo complejo: body con estructura anidada y validaciones
  @Post(path: '/users')
  Future<Response> createUser(
    Request request,
    @RequestBody(required: true, description: 'Complete user data with nested profile') Map<String, dynamic> userData,
  ) async {
    
    // Extraer datos principales
    final name = userData['name'] as String?;
    final email = userData['email'] as String?;
    final profile = userData['profile'] as Map<String, dynamic>?;
    
    // Validaciones principales
    final validationErrors = <String>[];
    
    if (name == null || name.isEmpty) {
      validationErrors.add('Name is required');
    }
    
    if (email == null || email.isEmpty) {
      validationErrors.add('Email is required');
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      validationErrors.add('Invalid email format');
    }
    
    // Validar profile si existe
    Map<String, dynamic>? processedProfile;
    if (profile != null) {
      final age = profile['age'] as int?;
      final interests = profile['interests'] as List<dynamic>?;
      
      if (age != null && (age < 13 || age > 120)) {
        validationErrors.add('Age must be between 13 and 120');
      }
      
      final validInterests = interests?.whereType<String>().toList() ?? [];
      
      processedProfile = {
        'age': age,
        'interests': validInterests,
        'interests_count': validInterests.length,
        'has_valid_age': age != null && age >= 13 && age <= 120,
      };
    }
    
    if (validationErrors.isNotEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Validation failed',
        'validation_errors': validationErrors,
        'received_data': userData,
      }));
    }
    
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    return jsonResponse(jsonEncode({
      'status': 'User created successfully',
      'user_id': userId,
      'received_data': userData,
      'processed_user': {
        'id': userId,
        'name': name,
        'email': email,
        'profile': processedProfile,
        'created_at': DateTime.now().toIso8601String(),
      },
      'data_analysis': {
        'has_profile': profile != null,
        'profile_completeness': processedProfile != null ? 
          ((processedProfile['has_valid_age'] == true ? 1 : 0) + 
           (processedProfile['interests_count'] > 0 ? 1 : 0)) / 2 * 100 : 0,
        'total_fields_provided': [name, email, profile].where((f) => f != null).length,
      },
    }));
  }

  /// Ejemplo con body opcional
  @Post(path: '/posts')
  Future<Response> createPost(
    Request request,
    @RequestBody(required: false, description: 'Optional post data') Map<String, dynamic>? postData,
  ) async {
    
    // Valores por defecto si no se proporciona body
    final title = postData?['title'] as String? ?? 'Untitled Post';
    final content = postData?['content'] as String? ?? '';
    final tags = postData?['tags'] as List<dynamic>? ?? [];
    final isPublic = postData?['is_public'] as bool? ?? false;
    
    final postId = 'post_${DateTime.now().millisecondsSinceEpoch}';
    final processedTags = tags.whereType<String>().take(10).toList();
    
    return jsonResponse(jsonEncode({
      'status': 'Post created successfully',
      'post_id': postId,
      'body_provided': postData != null,
      'received_data': postData ?? {},
      'processed_post': {
        'id': postId,
        'title': title,
        'content': content,
        'content_length': content.length,
        'tags': processedTags,
        'tags_count': processedTags.length,
        'is_public': isPublic,
        'visibility': isPublic ? 'public' : 'private',
        'created_at': DateTime.now().toIso8601String(),
      },
      'defaults_applied': {
        'title': postData?['title'] == null,
        'content': postData?['content'] == null,
        'tags': postData?['tags'] == null,
        'is_public': postData?['is_public'] == null,
      },
      'content_analysis': {
        'has_content': content.isNotEmpty,
        'word_count': content.split(' ').where((w) => w.isNotEmpty).length,
        'estimated_reading_time_minutes': (content.length / 200).ceil(),
      },
    }));
  }

  /// Ejemplo de "upload" simulado con metadata en el body
  @Post(path: '/upload')
  Future<Response> uploadFile(
    Request request,
    @RequestBody(required: true, description: 'File upload metadata and information') Map<String, dynamic> uploadData,
  ) async {
    
    final filename = uploadData['filename'] as String?;
    final contentType = uploadData['content_type'] as String?;
    final size = uploadData['size'] as int?;
    final metadata = uploadData['metadata'] as Map<String, dynamic>?;
    
    // Validaciones de archivo
    final validationErrors = <String>[];
    
    if (filename == null || filename.isEmpty) {
      validationErrors.add('Filename is required');
    }
    
    if (contentType == null || contentType.isEmpty) {
      validationErrors.add('Content type is required');
    }
    
    if (size == null || size <= 0) {
      validationErrors.add('Valid file size is required');
    } else if (size > 50 * 1024 * 1024) { // 50MB
      validationErrors.add('File size cannot exceed 50MB');
    }
    
    // Validar tipo de archivo
    final allowedTypes = [
      'application/pdf',
      'image/jpeg',
      'image/png',
      'text/plain',
      'application/msword',
    ];
    
    if (contentType != null && !allowedTypes.contains(contentType)) {
      validationErrors.add('File type not allowed');
    }
    
    if (validationErrors.isNotEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Upload validation failed',
        'validation_errors': validationErrors,
        'allowed_file_types': allowedTypes,
        'max_file_size_mb': 50,
        'received_data': uploadData,
      }));
    }
    
    final uploadId = 'upload_${DateTime.now().millisecondsSinceEpoch}';
    final sizeInMB = (size! / (1024 * 1024)).toStringAsFixed(2);
    
    return jsonResponse(jsonEncode({
      'status': 'File upload processed successfully',
      'upload_id': uploadId,
      'received_data': uploadData,
      'processed_upload': {
        'id': uploadId,
        'filename': filename,
        'content_type': contentType,
        'size_bytes': size,
        'size_mb': double.parse(sizeInMB),
        'metadata': metadata ?? {},
        'upload_timestamp': DateTime.now().toIso8601String(),
      },
      'file_analysis': {
        'file_extension': filename!.contains('.') ? filename.split('.').last : 'unknown',
        'is_image': contentType!.startsWith('image/'),
        'is_document': ['application/pdf', 'application/msword'].contains(contentType),
        'size_category': size < 1024 * 1024 ? 'small' : 
                        size < 10 * 1024 * 1024 ? 'medium' : 'large',
      },
      'metadata_provided': {
        'has_metadata': metadata != null,
        'metadata_fields': metadata?.keys.length ?? 0,
        'description_provided': metadata?['description'] != null,
      },
      'upload_stats': {
        'validation_passed': true,
        'processing_time_ms': 50, // Simulado
        'storage_location': '/uploads/$uploadId/$filename',
      },
    }));
  }
}