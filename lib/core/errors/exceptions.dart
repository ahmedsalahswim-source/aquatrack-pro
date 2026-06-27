class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException({required this.message, this.statusCode});

  @override
  String toString() => 'ServerException: $message (${statusCode ?? "unknown"})';
}

class AuthException implements Exception {
  final String message;
  final String code;
  AuthException({required this.message, this.code = 'unknown'});

  @override
  String toString() => 'AuthException: $message ($code)';
}

class CacheException implements Exception {
  final String message;
  CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

class ValidationException implements Exception {
  final String message;
  final String field;
  ValidationException({required this.message, required this.field});

  @override
  String toString() => 'ValidationException ($field): $message';
}
