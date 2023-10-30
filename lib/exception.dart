class FalApiException implements Exception {
  final int status;
  final String message;
  final Map<String, dynamic>? body;

  FalApiException({
    required this.status,
    required this.message,
    this.body,
  });

  @override
  String toString() {
    return 'ApiException: $status - $message';
  }
}

class ValidationErrorInfo {
  final String msg;
  final String type;

  ValidationErrorInfo({
    required this.msg,
    required this.type,
  });

  factory ValidationErrorInfo.fromMap(Map<String, dynamic> json) {
    return ValidationErrorInfo(
      msg: json['msg'],
      type: json['type'],
    );
  }
}

class ValidationException extends FalApiException {
  final List<ValidationErrorInfo> errors;

  ValidationException({
    required int status,
    required String message,
    required this.errors,
  }) : super(
          status: status,
          message: message,
        );

  factory ValidationException.fromMap(Map<String, dynamic> json) {
    return ValidationException(
      status: json['status'],
      message: json['message'],
      errors: (json['body'] as List<dynamic>)
          .map((e) => ValidationErrorInfo.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
