class FalOutput {
  final Map<String, dynamic> data;
  final String requestId;

  FalOutput({
    required this.data,
    required this.requestId,
  });

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'requestId': requestId,
    };
  }
}
