/// Combined Real-World Example
/// Demuestra el uso combinado de todos los tipos de parámetros en escenarios realistas
/// @PathParam, @QueryParam, @RequestHeader, @RequestBody, @Param
library;

import 'dart:convert';
import 'dart:io';
import 'package:api_kit/api_kit.dart';

void main() async {
  print('🌟 Combined Real-World Example - All parameter types in realistic scenarios');

  final server = ApiServer.create()
    .configureEndpointDisplay(showInConsole: true);

  final result = await server.start(
    host: 'localhost',
    port: 8095,
    projectPath: Directory.current.path,
  );

  result.when(
    ok: (httpServer) {
      print('\n🧪 Test Combined Real-World endpoints:');
      
      print('\n   📊 E-commerce Product Management:');
      print('   # Get products in category with pagination:');
      print('   curl -H "Authorization: Bearer shop_token_123" -H "X-Store-ID: store_456" "http://localhost:8095/api/stores/store_456/categories/electronics/products?page=1&limit=5&sort=price&order=asc&in_stock=true"');
      
      print('\n   # Update product with full data:');
      print('   curl -X PUT -H "Authorization: Bearer admin_token_123" -H "Content-Type: application/json" -H "X-Store-ID: store_456" -d \'{"name":"Updated Product","price":299.99,"description":"New description","tags":["electronics","sale"]}\' "http://localhost:8095/api/stores/store_456/products/prod_123?notify_users=true&publish_immediately=false"');
      
      print('\n   💬 Social Media API:');
      print('   # Get user posts with filters:');
      print('   curl -H "Authorization: Bearer user_token_456" -H "Accept: application/json" -H "Accept-Language: en-US,es;q=0.9" "http://localhost:8095/api/users/user_123/posts?page=1&type=public&since=2024-01-01&include_comments=true"');
      
      print('\n   # Create new post:');
      print('   curl -X POST -H "Authorization: Bearer user_token_456" -H "Content-Type: application/json" -H "X-Client-App: mobile-app" -d \'{"content":"Hello world!","visibility":"public","tags":["hello","world"],"location":{"lat":40.7128,"lng":-74.0060}}\' "http://localhost:8095/api/users/user_123/posts?auto_publish=true&schedule_time="');
      
      print('\n   📁 File Management System:');
      print('   # Upload file to folder:');
      print('   curl -X POST -H "Authorization: Bearer file_token_789" -H "Content-Type: application/json" -H "X-Upload-Context: user_upload" -d \'{"filename":"document.pdf","size":1048576,"content_type":"application/pdf","description":"Important document"}\' "http://localhost:8095/api/folders/folder_456/files?create_thumbnails=true&scan_virus=true&notify_owner=false"');
      
      print('\n⚠️  Press Ctrl+C to stop');
    },
    err: (error) {
      print('❌ Error: $error');
    },
  );
}

/// Controller simulando una API de E-commerce real
@RestController(basePath: '/api/stores')
class EcommerceController extends BaseController {

  /// Sistema completo de productos: PathParam + QueryParam + RequestHeader
  @Get(path: '/{storeId}/categories/{categoryName}/products')
  Future<Response> getProductsInCategory(
    Request request,
    // Path parameters
    @PathParam('storeId', description: 'Store identifier') String storeId,
    @PathParam('categoryName', description: 'Product category name') String categoryName,
    
    // Query parameters
    @QueryParam('page', defaultValue: 1, description: 'Page number') int page,
    @QueryParam('limit', defaultValue: 10, description: 'Items per page') int limit,
    @QueryParam('sort', defaultValue: 'name', description: 'Sort field') String sortBy,
    @QueryParam('order', defaultValue: 'asc', description: 'Sort order') String sortOrder,
    @QueryParam('in_stock', required: false, description: 'Filter by stock status') bool? inStockOnly,
    @QueryParam('min_price', required: false, description: 'Minimum price filter') double? minPrice,
    @QueryParam('max_price', required: false, description: 'Maximum price filter') double? maxPrice,
    
    // Headers
    @RequestHeader('Authorization', required: true, description: 'Bearer authentication token') String authHeader,
    @RequestHeader('X-Store-ID', required: true, description: 'Store ID verification header') String storeIdHeader,
    @RequestHeader('Accept-Language', required: false, defaultValue: 'en-US', description: 'Language preference') String language,
  ) async {
    
    // Validaciones de autenticación
    if (!authHeader.startsWith('Bearer ')) {
      return Response.unauthorized(jsonEncode({'error': 'Invalid authorization format'}));
    }
    
    final token = authHeader.substring(7);
    if (token.length < 10) {
      return Response.unauthorized(jsonEncode({'error': 'Invalid token'}));
    }
    
    // Verificar que el store ID del path coincide con el header
    if (storeId != storeIdHeader) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Store ID mismatch',
        'path_store_id': storeId,
        'header_store_id': storeIdHeader,
      }));
    }
    
    // Validar parámetros de paginación
    if (page < 1 || limit < 1 || limit > 100) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Invalid pagination parameters',
        'valid_page': 'page >= 1',
        'valid_limit': '1 <= limit <= 100',
      }));
    }
    
    // Validar filtros de precio
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Invalid price range',
        'min_price': minPrice,
        'max_price': maxPrice,
      }));
    }
    
    // Simular productos filtrados
    final mockProducts = List.generate(limit, (index) {
      final productId = 'prod_${(page - 1) * limit + index + 1}';
      final basePrice = 50.0 + (index * 25.0);
      final actualPrice = minPrice != null ? 
        (basePrice < minPrice ? minPrice : basePrice) : basePrice;
      
      return {
        'id': productId,
        'name': 'Product ${index + 1} in $categoryName',
        'category': categoryName,
        'price': actualPrice,
        'in_stock': inStockOnly ?? (index % 3 != 0), // Simular stock
        'store_id': storeId,
        'description': 'High-quality product in $categoryName category',
      };
    });
    
    // Filtrar por precio si se especifica
    final filteredProducts = mockProducts.where((product) {
      final price = product['price'] as double;
      if (minPrice != null && price < minPrice) return false;
      if (maxPrice != null && price > maxPrice) return false;
      if (inStockOnly == true && product['in_stock'] != true) return false;
      return true;
    }).toList();
    
    // Ordenar productos
    filteredProducts.sort((a, b) {
      late int comparison;
      switch (sortBy) {
        case 'price':
          comparison = (a['price'] as double).compareTo(b['price'] as double);
          break;
        case 'name':
        default:
          comparison = (a['name'] as String).compareTo(b['name'] as String);
          break;
      }
      return sortOrder == 'desc' ? -comparison : comparison;
    });
    
    return jsonResponse(jsonEncode({
      'message': 'Products retrieved successfully',
      'request_context': {
        'store_id': storeId,
        'category': categoryName,
        'authenticated_user': token.hashCode.toString(),
        'language': language,
      },
      'filters_applied': {
        'page': page,
        'limit': limit,
        'sort_by': sortBy,
        'sort_order': sortOrder,
        'in_stock_only': inStockOnly,
        'price_range': {
          'min': minPrice,
          'max': maxPrice,
        },
      },
      'results': {
        'products': filteredProducts,
        'total_found': filteredProducts.length,
        'page': page,
        'per_page': limit,
        'has_next_page': filteredProducts.length >= limit,
      },
      'metadata': {
        'store_verified': storeId == storeIdHeader,
        'filters_count': [inStockOnly, minPrice, maxPrice].where((f) => f != null).length,
        'query_performance_ms': 25,
      },
    }));
  }

  /// Actualización completa: PathParam + QueryParam + RequestHeader + RequestBody
  @Put(path: '/{storeId}/products/{productId}')
  Future<Response> updateProduct(
    Request request,
    // Path parameters
    @PathParam('storeId', description: 'Store identifier') String storeId,
    @PathParam('productId', description: 'Product identifier') String productId,
    
    // Query parameters
    @QueryParam('notify_users', defaultValue: false, description: 'Notify users of changes') bool notifyUsers,
    @QueryParam('publish_immediately', defaultValue: true, description: 'Publish changes immediately') bool publishImmediately,
    @QueryParam('create_backup', defaultValue: true, description: 'Create backup before update') bool createBackup,
    
    // Headers
    @RequestHeader('Authorization', required: true, description: 'Admin authorization token') String authHeader,
    @RequestHeader('X-Store-ID', required: true, description: 'Store ID verification') String storeIdHeader,
    @RequestHeader('Content-Type', required: false, defaultValue: 'application/json', description: 'Request content type') String contentType,
    
    // Body
    @RequestBody(required: true, description: 'Product update data') Map<String, dynamic> productData,
  ) async {
    
    // Validar autorización de admin
    if (!authHeader.startsWith('Bearer admin_')) {
      return Response.forbidden(jsonEncode({
        'error': 'Admin access required',
        'hint': 'Use admin token starting with "Bearer admin_"'
      }));
    }
    
    // Verificar store ID
    if (storeId != storeIdHeader) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Store ID mismatch',
        'expected': storeId,
        'received': storeIdHeader,
      }));
    }
    
    // Validar content type
    if (!contentType.contains('application/json')) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Invalid content type',
        'expected': 'application/json',
        'received': contentType,
      }));
    }
    
    // Validar datos del producto
    final validationErrors = <String>[];
    final name = productData['name'] as String?;
    final price = productData['price'];
    final description = productData['description'] as String?;
    final tags = productData['tags'] as List<dynamic>?;
    
    if (name == null || name.isEmpty) {
      validationErrors.add('Product name is required');
    }
    
    if (price == null) {
      validationErrors.add('Product price is required');
    } else if (price is! num || price <= 0) {
      validationErrors.add('Product price must be a positive number');
    }
    
    if (validationErrors.isNotEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Validation failed',
        'validation_errors': validationErrors,
        'received_data': productData,
      }));
    }
    
    final processedTags = tags?.whereType<String>().toList() ?? [];
    
    // Simular proceso de actualización
    final updateResult = {
      'product_id': productId,
      'store_id': storeId,
      'updated_fields': {
        'name': name,
        'price': price,
        'description': description ?? 'No description',
        'tags': processedTags,
      },
      'updated_at': DateTime.now().toIso8601String(),
      'updated_by': authHeader.substring(7),
    };
    
    // Simular acciones adicionales
    final actions = <String>[];
    if (createBackup) actions.add('backup_created');
    if (notifyUsers) actions.add('users_notified');
    if (publishImmediately) actions.add('changes_published');
    
    return jsonResponse(jsonEncode({
      'message': 'Product updated successfully',
      'update_context': {
        'store_id': storeId,
        'product_id': productId,
        'admin_user': authHeader.substring(7).split('_').last,
      },
      'update_options': {
        'notify_users': notifyUsers,
        'publish_immediately': publishImmediately,
        'create_backup': createBackup,
      },
      'result': updateResult,
      'actions_performed': actions,
      'metadata': {
        'content_type_verified': contentType.contains('application/json'),
        'store_id_verified': storeId == storeIdHeader,
        'tags_processed': processedTags.length,
        'update_duration_ms': 150,
      },
    }));
  }
}

/// Controller simulando una API de Social Media
@RestController(basePath: '/api/users')
class SocialMediaController extends BaseController {

  /// Obtener posts con filtros completos
  @Get(path: '/{userId}/posts')
  Future<Response> getUserPosts(
    Request request,
    // Path parameter
    @PathParam('userId', description: 'User identifier') String userId,
    
    // Query parameters
    @QueryParam('page', defaultValue: 1, description: 'Page number') int page,
    @QueryParam('type', defaultValue: 'all', description: 'Post type filter') String postType,
    @QueryParam('since', required: false, description: 'Date filter (YYYY-MM-DD)') String? sinceDate,
    @QueryParam('include_comments', defaultValue: false, description: 'Include comments in response') bool includeComments,
    
    // Headers
    @RequestHeader('Authorization', required: true, description: 'User authentication token') String authHeader,
    @RequestHeader('Accept', required: false, defaultValue: 'application/json', description: 'Response format preference') String acceptHeader,
    @RequestHeader('Accept-Language', required: false, defaultValue: 'en-US', description: 'Language preference') String language,
  ) async {
    
    // Validar token de usuario
    if (!authHeader.startsWith('Bearer user_')) {
      return Response.unauthorized(jsonEncode({
        'error': 'User authentication required',
        'hint': 'Use user token starting with "Bearer user_"'
      }));
    }
    
    final token = authHeader.substring(7);
    final tokenUserId = token.split('_').last;
    
    // Verificar que el usuario puede acceder a estos posts (mismo usuario o público)
    final canAccess = tokenUserId == userId.split('_').last || postType == 'public';
    if (!canAccess) {
      return Response.forbidden(jsonEncode({
        'error': 'Access denied',
        'message': 'Can only access your own posts or public posts'
      }));
    }
    
    // Validar filtros de fecha
    DateTime? filterDate;
    if (sinceDate != null) {
      try {
        filterDate = DateTime.parse('${sinceDate}T00:00:00Z');
      } catch (e) {
        return Response.badRequest(body: jsonEncode({
          'error': 'Invalid date format',
          'expected_format': 'YYYY-MM-DD',
          'received': sinceDate,
        }));
      }
    }
    
    // Simular posts
    final posts = List.generate(10, (index) {
      final postDate = DateTime.now().subtract(Duration(days: index));
      final shouldInclude = filterDate == null || postDate.isAfter(filterDate);
      
      if (!shouldInclude) return null;
      
      final post = {
        'id': 'post_${userId}_$index',
        'user_id': userId,
        'content': 'This is post #${index + 1} from user $userId',
        'type': postType == 'all' ? (index % 2 == 0 ? 'public' : 'private') : postType,
        'created_at': postDate.toIso8601String(),
        'likes_count': index * 5,
        'shares_count': index * 2,
      };
      
      if (includeComments) {
        post['comments'] = List.generate(3, (commentIndex) => {
          'id': 'comment_${index}_$commentIndex',
          'content': 'Comment $commentIndex on post $index',
          'author': 'user_${commentIndex + 100}',
          'created_at': postDate.add(Duration(minutes: commentIndex * 10)).toIso8601String(),
        });
      }
      
      return post;
    }).where((post) => post != null).toList();
    
    return jsonResponse(jsonEncode({
      'message': 'Posts retrieved successfully',
      'request_context': {
        'user_id': userId,
        'requesting_user': tokenUserId,
        'language': language,
        'response_format': acceptHeader.contains('json') ? 'json' : 'other',
      },
      'filters': {
        'page': page,
        'post_type': postType,
        'since_date': sinceDate,
        'include_comments': includeComments,
      },
      'results': {
        'posts': posts,
        'total_count': posts.length,
        'page': page,
        'comments_included': includeComments,
      },
      'metadata': {
        'date_filter_applied': filterDate != null,
        'access_level': canAccess ? 'granted' : 'denied',
        'localization': language,
      },
    }));
  }

  /// Crear post completo
  @Post(path: '/{userId}/posts')
  Future<Response> createPost(
    Request request,
    // Path parameter
    @PathParam('userId', description: 'User identifier') String userId,
    
    // Query parameters
    @QueryParam('auto_publish', defaultValue: true, description: 'Publish post immediately') bool autoPublish,
    @QueryParam('schedule_time', required: false, description: 'Schedule publication time') String? scheduleTime,
    
    // Headers
    @RequestHeader('Authorization', required: true, description: 'User authentication token') String authHeader,
    @RequestHeader('Content-Type', required: true, description: 'Request content type') String contentType,
    @RequestHeader('X-Client-App', required: false, defaultValue: 'web', description: 'Client application identifier') String clientApp,
    
    // Body
    @RequestBody(required: true, description: 'Post creation data') Map<String, dynamic> postData,
  ) async {
    
    // Validar autenticación
    final token = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : '';
    final tokenUserIdParts = token.split('_');
    final tokenUserId = tokenUserIdParts.isNotEmpty ? tokenUserIdParts.last : null;
    final pathUserIdParts = userId.split('_');
    final pathUserId = pathUserIdParts.isNotEmpty ? pathUserIdParts.last : null;
    
    if (tokenUserId != pathUserId) {
      return Response.forbidden(jsonEncode({
        'error': 'Cannot create posts for other users',
        'token_user': tokenUserId,
        'path_user': pathUserId,
      }));
    }
    
    // Validar datos del post
    final content = postData['content'] as String?;
    final visibility = postData['visibility'] as String? ?? 'private';
    final tags = postData['tags'] as List<dynamic>? ?? [];
    final location = postData['location'] as Map<String, dynamic>?;
    
    if (content == null || content.isEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Post content is required',
        'received_data': postData,
      }));
    }
    
    if (content.length > 500) {
      return Response.badRequest(body: jsonEncode({
        'error': 'Post content too long',
        'max_length': 500,
        'current_length': content.length,
      }));
    }
    
    // Validar horario programado
    DateTime? scheduledFor;
    if (scheduleTime != null && scheduleTime.isNotEmpty) {
      try {
        scheduledFor = DateTime.parse(scheduleTime);
        if (scheduledFor.isBefore(DateTime.now())) {
          return Response.badRequest(body: jsonEncode({
            'error': 'Cannot schedule posts in the past',
            'schedule_time': scheduleTime,
            'current_time': DateTime.now().toIso8601String(),
          }));
        }
      } catch (e) {
        return Response.badRequest(body: jsonEncode({
          'error': 'Invalid schedule time format',
          'expected_format': 'ISO 8601 (YYYY-MM-DDTHH:mm:ssZ)',
          'received': scheduleTime,
        }));
      }
    }
    
    final postId = 'post_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final processedTags = tags.whereType<String>().take(10).toList();
    
    final newPost = {
      'id': postId,
      'user_id': userId,
      'content': content,
      'visibility': visibility,
      'tags': processedTags,
      'location': location,
      'status': scheduledFor != null ? 'scheduled' : (autoPublish ? 'published' : 'draft'),
      'created_at': DateTime.now().toIso8601String(),
      'scheduled_for': scheduledFor?.toIso8601String(),
      'client_app': clientApp,
    };
    
    return jsonResponse(jsonEncode({
      'message': 'Post created successfully',
      'post': newPost,
      'creation_context': {
        'user_id': userId,
        'client_app': clientApp,
        'auto_publish': autoPublish,
        'is_scheduled': scheduledFor != null,
      },
      'content_analysis': {
        'content_length': content.length,
        'word_count': content.split(' ').length,
        'tags_count': processedTags.length,
        'has_location': location != null,
        'estimated_read_time_seconds': (content.length / 10).ceil(),
      },
      'publication_info': {
        'status': newPost['status'],
        'published_immediately': autoPublish && scheduledFor == null,
        'scheduled_for': scheduledFor?.toIso8601String(),
        'visibility': visibility,
      },
    }));
  }
}

/// Controller simulando un sistema de gestión de archivos
@RestController(basePath: '/api/folders')
class FileManagementController extends BaseController {

  /// Upload de archivo con todos los parámetros combinados
  @Post(path: '/{folderId}/files')
  Future<Response> uploadFileToFolder(
    Request request,
    // Path parameter
    @PathParam('folderId', description: 'Folder identifier') String folderId,
    
    // Query parameters
    @QueryParam('create_thumbnails', defaultValue: false, description: 'Generate thumbnails for images') bool createThumbnails,
    @QueryParam('scan_virus', defaultValue: true, description: 'Perform virus scanning') bool scanVirus,
    @QueryParam('notify_owner', defaultValue: true, description: 'Notify folder owner') bool notifyOwner,
    @QueryParam('max_file_size', defaultValue: 52428800, description: 'Maximum file size in bytes') int maxFileSize, // 50MB
    
    // Headers
    @RequestHeader('Authorization', required: true, description: 'File upload authorization token') String authHeader,
    @RequestHeader('Content-Type', required: true, description: 'Request content type') String contentType,
    @RequestHeader('X-Upload-Context', required: false, defaultValue: 'web_upload', description: 'Upload context information') String uploadContext,
    
    // Body
    @RequestBody(required: true, description: 'File upload metadata') Map<String, dynamic> fileData,
  ) async {
    
    // Validar token de archivos
    if (!authHeader.startsWith('Bearer file_')) {
      return Response.unauthorized(jsonEncode({
        'error': 'File upload authorization required',
        'hint': 'Use file token starting with "Bearer file_"'
      }));
    }
    
    // Validar datos del archivo
    final filename = fileData['filename'] as String?;
    final fileSize = fileData['size'];
    final fileContentType = fileData['content_type'] as String?;
    final description = fileData['description'] as String?;
    
    final validationErrors = <String>[];
    
    if (filename == null || filename.isEmpty) {
      validationErrors.add('Filename is required');
    }
    
    if (fileSize == null || fileSize is! int || fileSize <= 0) {
      validationErrors.add('Valid file size is required');
    } else if (fileSize > maxFileSize) {
      validationErrors.add('File size exceeds maximum allowed ($maxFileSize bytes)');
    }
    
    if (fileContentType == null || fileContentType.isEmpty) {
      validationErrors.add('File content type is required');
    }
    
    if (validationErrors.isNotEmpty) {
      return Response.badRequest(body: jsonEncode({
        'error': 'File upload validation failed',
        'validation_errors': validationErrors,
        'limits': {
          'max_file_size_bytes': maxFileSize,
          'max_file_size_mb': (maxFileSize / (1024 * 1024)).toStringAsFixed(1),
        },
      }));
    }
    
    // Analizar tipo de archivo
    final isImage = fileContentType!.startsWith('image/');
    final isDocument = ['application/pdf', 'application/msword', 'text/plain'].contains(fileContentType);
    final fileExtension = filename!.contains('.') ? filename.split('.').last.toLowerCase() : '';
    
    // Simular procesamiento
    final fileId = 'file_${DateTime.now().millisecondsSinceEpoch}';
    final uploadPath = '/uploads/$folderId/$fileId/$filename';
    
    final processedFile = {
      'id': fileId,
      'filename': filename,
      'original_name': filename,
      'folder_id': folderId,
      'size_bytes': fileSize,
      'size_mb': (fileSize / (1024 * 1024)).toStringAsFixed(2),
      'content_type': fileContentType,
      'description': description ?? 'No description provided',
      'upload_path': uploadPath,
      'uploaded_at': DateTime.now().toIso8601String(),
      'uploaded_by': authHeader.substring(7),
      'upload_context': uploadContext,
    };
    
    // Simular acciones adicionales
    final actions = <String>[];
    if (createThumbnails && isImage) actions.add('thumbnails_created');
    if (scanVirus) actions.add('virus_scan_completed');
    if (notifyOwner) actions.add('owner_notified');
    
    final securityInfo = {
      'virus_scan': scanVirus ? 'passed' : 'skipped',
      'file_safe': true,
      'quarantined': false,
    };
    
    return jsonResponse(jsonEncode({
      'message': 'File uploaded successfully',
      'file': processedFile,
      'upload_context': {
        'folder_id': folderId,
        'upload_source': uploadContext,
        'uploader': authHeader.substring(7),
      },
      'processing_options': {
        'create_thumbnails': createThumbnails,
        'scan_virus': scanVirus,
        'notify_owner': notifyOwner,
        'max_file_size_mb': (maxFileSize / (1024 * 1024)).toStringAsFixed(1),
      },
      'file_analysis': {
        'file_extension': fileExtension,
        'is_image': isImage,
        'is_document': isDocument,
        'thumbnails_applicable': isImage && createThumbnails,
        'size_category': fileSize < 1024 * 1024 ? 'small' : 
                        fileSize < 10 * 1024 * 1024 ? 'medium' : 'large',
      },
      'actions_performed': actions,
      'security': securityInfo,
      'metadata': {
        'content_type_verified': contentType.contains('application/json'),
        'upload_duration_ms': 200,
        'storage_location': uploadPath,
        'backup_created': true,
      },
    }));
  }
}