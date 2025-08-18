# 📥 GET Requests

Los **GET requests** son para **leer** datos sin modificar el estado del servidor. Son seguros, idempotentes y cacheables.

## 🎯 Tipos de GET Endpoints

### 1. **Listar Recursos** - `GET /api/resources/`
### 2. **Obtener por ID** - `GET /api/resources/{id}`
### 3. **Búsquedas y Filtros** - `GET /api/resources/search`
### 4. **Recursos Anidados** - `GET /api/users/{id}/posts`
### 5. **Health Checks** - `GET /api/health`

---

## 📋 1. Listar Todos los Recursos

```dart
@Controller('/api/books')
class BookController extends BaseController {
  
  static final List<Map<String, dynamic>> _books = [
    {
      'id': '1',
      'title': 'Clean Code',
      'author': 'Robert Martin',
      'isbn': '978-0132350884',
      'pages': 464,
      'published_year': 2008,
      'category': 'programming'
    },
    {
      'id': '2',
      'title': 'The Pragmatic Programmer',
      'author': 'Dave Thomas',
      'isbn': '978-0201616224',
      'pages': 352,
      'published_year': 1999,
      'category': 'programming'
    },
  ];

  // GET /api/books/
  @GET('/')
  Future<Response> getAllBooks(Request request) async {
    logRequest(request, 'Getting all books');
    
    final response = ApiResponse.success({
      'books': _books,
      'total_count': _books.length,
      'page': 1,
      'per_page': _books.length,
    }, 'Books retrieved successfully');
    
    return jsonResponse(response.toJson());
  }
}
```

**Test:**
```bash
curl http://localhost:8080/api/books/
```

---

## 🎯 2. Obtener Recurso por ID

```dart
// GET /api/books/{id}
@GET('/<id>')
Future<Response> getBook(Request request) async {
  final id = getRequiredParam(request, 'id');
  logRequest(request, 'Getting book with ID: $id');
  
  final book = _books.firstWhere(
    (b) => b['id'] == id,
    orElse: () => {},
  );
  
  if (book.isEmpty) {
    final response = ApiResponse.error('Book not found');
    return jsonResponse(response.toJson(), statusCode: 404);
  }
  
  final response = ApiResponse.success(book, 'Book retrieved successfully');
  return jsonResponse(response.toJson());
}
```

**Test:**
```bash
# Libro existente
curl http://localhost:8080/api/books/1

# Libro no existente
curl http://localhost:8080/api/books/999
```

---

## 🔍 3. Búsquedas y Filtros Avanzados

```dart
// GET /api/books/search?title=clean&author=martin&category=programming&limit=10
@GET('/search')
Future<Response> searchBooks(Request request) async {
  logRequest(request, 'Searching books with filters');
  
  // Extraer parámetros de búsqueda
  final title = getOptionalQueryParam(request, 'title');
  final author = getOptionalQueryParam(request, 'author');
  final category = getOptionalQueryParam(request, 'category');
  final yearFrom = getOptionalQueryParam(request, 'year_from');
  final yearTo = getOptionalQueryParam(request, 'year_to');
  final limit = getOptionalQueryParam(request, 'limit', '10');
  final offset = getOptionalQueryParam(request, 'offset', '0');
  final sortBy = getOptionalQueryParam(request, 'sort_by', 'title');
  final order = getOptionalQueryParam(request, 'order', 'asc');
  
  print('🔍 Search filters:');
  print('  - Title: ${title ?? "any"}');
  print('  - Author: ${author ?? "any"}');
  print('  - Category: ${category ?? "any"}');
  print('  - Year range: ${yearFrom ?? "any"} - ${yearTo ?? "any"}');
  print('  - Sort: $sortBy ($order)');
  print('  - Pagination: offset=$offset, limit=$limit');
  
  // Aplicar filtros
  var filteredBooks = _books.where((book) {
    // Filtro por título
    if (title != null) {
      final bookTitle = book['title'].toString().toLowerCase();
      if (!bookTitle.contains(title.toLowerCase())) return false;
    }
    
    // Filtro por autor
    if (author != null) {
      final bookAuthor = book['author'].toString().toLowerCase();
      if (!bookAuthor.contains(author.toLowerCase())) return false;
    }
    
    // Filtro por categoría
    if (category != null) {
      if (book['category'] != category) return false;
    }
    
    // Filtro por rango de años
    final bookYear = book['published_year'] as int;
    if (yearFrom != null) {
      final fromYear = int.tryParse(yearFrom) ?? 0;
      if (bookYear < fromYear) return false;
    }
    if (yearTo != null) {
      final toYear = int.tryParse(yearTo) ?? 9999;
      if (bookYear > toYear) return false;
    }
    
    return true;
  }).toList();
  
  // Ordenar resultados
  filteredBooks.sort((a, b) {
    dynamic aValue = a[sortBy] ?? '';
    dynamic bValue = b[sortBy] ?? '';
    
    if (aValue is String && bValue is String) {
      final result = aValue.toLowerCase().compareTo(bValue.toLowerCase());
      return order == 'desc' ? -result : result;
    } else if (aValue is num && bValue is num) {
      final result = aValue.compareTo(bValue);
      return order == 'desc' ? -result : result;
    } else {
      final result = aValue.toString().compareTo(bValue.toString());
      return order == 'desc' ? -result : result;
    }
  });
  
  // Aplicar paginación
  final limitInt = int.tryParse(limit) ?? 10;
  final offsetInt = int.tryParse(offset) ?? 0;
  final totalResults = filteredBooks.length;
  final paginatedBooks = filteredBooks.skip(offsetInt).take(limitInt).toList();
  
  final response = ApiResponse.success({
    'books': paginatedBooks,
    'pagination': {
      'total_results': totalResults,
      'current_page': (offsetInt ~/ limitInt) + 1,
      'per_page': limitInt,
      'total_pages': (totalResults / limitInt).ceil(),
      'has_next': (offsetInt + limitInt) < totalResults,
      'has_previous': offsetInt > 0,
    },
    'filters_applied': {
      'title': title,
      'author': author,
      'category': category,
      'year_from': yearFrom,
      'year_to': yearTo,
      'sort_by': sortBy,
      'order': order,
    },
  }, 'Search completed successfully');
  
  return jsonResponse(response.toJson());
}
```

**Tests:**
```bash
# Búsqueda por título
curl "http://localhost:8080/api/books/search?title=clean"

# Múltiples filtros
curl "http://localhost:8080/api/books/search?author=martin&category=programming&year_from=2000"

# Con paginación y ordenamiento
curl "http://localhost:8080/api/books/search?sort_by=published_year&order=desc&limit=5&offset=0"
```

---

## 📚 4. Recursos Anidados

```dart
// GET /api/books/{id}/reviews
@GET('/<id>/reviews')
Future<Response> getBookReviews(Request request) async {
  final bookId = getRequiredParam(request, 'id');
  logRequest(request, 'Getting reviews for book $bookId');
  
  // Verificar que el libro existe
  final book = _books.firstWhere(
    (b) => b['id'] == bookId,
    orElse: () => {},
  );
  
  if (book.isEmpty) {
    final response = ApiResponse.error('Book not found');
    return jsonResponse(response.toJson(), statusCode: 404);
  }
  
  // Reviews de ejemplo (en producción vendrían de BD)
  final reviews = [
    {
      'id': '1',
      'book_id': bookId,
      'reviewer': 'Alice Johnson',
      'rating': 5,
      'comment': 'Excellent book for developers!',
      'created_at': '2024-01-15T10:30:00Z'
    },
    {
      'id': '2',
      'book_id': bookId,
      'reviewer': 'Bob Wilson',
      'rating': 4,
      'comment': 'Very helpful, learned a lot.',
      'created_at': '2024-01-20T14:45:00Z'
    },
  ];
  
  final response = ApiResponse.success({
    'book': {
      'id': book['id'],
      'title': book['title'],
    },
    'reviews': reviews,
    'total_reviews': reviews.length,
    'average_rating': reviews.fold(0.0, (sum, r) => sum + r['rating']) / reviews.length,
  }, 'Reviews retrieved successfully');
  
  return jsonResponse(response.toJson());
}

// GET /api/books/categories
@GET('/categories')
Future<Response> getBookCategories(Request request) async {
  logRequest(request, 'Getting book categories');
  
  final categories = _books
      .map((book) => book['category'] as String)
      .toSet()
      .toList();
  
  final categoriesWithCount = categories.map((category) {
    final count = _books.where((book) => book['category'] == category).length;
    return {
      'name': category,
      'book_count': count,
    };
  }).toList();
  
  final response = ApiResponse.success({
    'categories': categoriesWithCount,
    'total_categories': categories.length,
  }, 'Categories retrieved successfully');
  
  return jsonResponse(response.toJson());
}
```

**Tests:**
```bash
# Reviews de un libro
curl http://localhost:8080/api/books/1/reviews

# Categorías disponibles
curl http://localhost:8080/api/books/categories
```

---

## 📊 5. Health Check y Estadísticas

```dart
// GET /api/books/health
@GET('/health')
Future<Response> healthCheck(Request request) async {
  logRequest(request, 'Books service health check');
  
  return jsonResponse(jsonEncode({
    'service': 'books-api',
    'status': 'healthy',
    'timestamp': DateTime.now().toIso8601String(),
    'version': '1.0.0',
    'statistics': {
      'total_books': _books.length,
      'categories': _books.map((b) => b['category']).toSet().length,
      'latest_book_year': _books
          .map((b) => b['published_year'] as int)
          .reduce((a, b) => a > b ? a : b),
    },
  }));
}

// GET /api/books/stats
@GET('/stats')
Future<Response> getBookStats(Request request) async {
  logRequest(request, 'Getting book statistics');
  
  final totalBooks = _books.length;
  final totalPages = _books.fold(0, (sum, book) => sum + (book['pages'] as int));
  final avgPages = totalPages / totalBooks;
  
  final categoryStats = <String, Map<String, dynamic>>{};
  for (final book in _books) {
    final category = book['category'] as String;
    if (!categoryStats.containsKey(category)) {
      categoryStats[category] = {'count': 0, 'total_pages': 0};
    }
    categoryStats[category]!['count']++;
    categoryStats[category]!['total_pages'] += book['pages'] as int;
  }
  
  final response = ApiResponse.success({
    'overview': {
      'total_books': totalBooks,
      'total_pages': totalPages,
      'average_pages_per_book': avgPages.round(),
    },
    'by_category': categoryStats,
    'year_range': {
      'earliest': _books.map((b) => b['published_year']).reduce((a, b) => a < b ? a : b),
      'latest': _books.map((b) => b['published_year']).reduce((a, b) => a > b ? a : b),
    },
    'generated_at': DateTime.now().toIso8601String(),
  }, 'Statistics generated successfully');
  
  return jsonResponse(response.toJson());
}
```

**Tests:**
```bash
# Health check
curl http://localhost:8080/api/books/health

# Estadísticas
curl http://localhost:8080/api/books/stats
```

---

## 🏆 Mejores Prácticas para GET

### ✅ **DO's**
- ✅ Usar query parameters para filtros y paginación
- ✅ Implementar paginación en listas largas
- ✅ Proporcionar health checks
- ✅ Retornar 404 para recursos no encontrados
- ✅ Incluir metadata útil en responses (total, pagination, etc.)
- ✅ Permitir ordenamiento flexible

### ❌ **DON'Ts**
- ❌ Modificar datos en un GET request
- ❌ Retornar listas sin paginación
- ❌ Ignorar parámetros de filtro inválidos
- ❌ Exponer información sensible
- ❌ Usar GET para operaciones que deberían ser POST

### 📊 Response Estándar para Listas
```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "total_results": 150,
      "current_page": 1,
      "per_page": 10,
      "total_pages": 15,
      "has_next": true,
      "has_previous": false
    },
    "filters_applied": {...}
  },
  "message": "Items retrieved successfully"
}
```

---

**👉 [Siguiente: POST Requests →](04-post-requests.md)**