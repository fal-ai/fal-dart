import './config.dart';
import './http.dart';

class EnqueueResult {
  String requestId;

  EnqueueResult(this.requestId);

  factory EnqueueResult.fromMap(Map<String, dynamic> json) {
    return EnqueueResult(json['request_id']);
  }
}

class RequestLog {
  String message;
  String timestamp;

  RequestLog({
    required this.message,
    required this.timestamp,
  });

  factory RequestLog.fromMap(Map<String, dynamic> json) {
    return RequestLog(
      message: json['message'],
      timestamp: json['timestamp'],
    );
  }
}

abstract class QueueStatus {
  String status;
  String responseUrl;

  QueueStatus(this.status, this.responseUrl);

  factory QueueStatus.fromMap(Map<String, dynamic> json) {
    switch (json['status']) {
      case 'IN_PROGRESS':
        return InProgressStatus.fromMap(json);
      case 'COMPLETED':
        return CompletedStatus.fromMap(json);
      case 'IN_QUEUE':
        return InQueueStatus.fromMap(json);
      default:
        throw Exception('Unknown status: ${json['status']}');
    }
  }
}

class InProgressStatus extends QueueStatus {
  List<RequestLog> logs;

  InProgressStatus({
    required String responseUrl,
    required this.logs,
  }) : super('IN_PROGRESS', responseUrl);

  factory InProgressStatus.fromMap(Map<String, dynamic> json) {
    return InProgressStatus(
      responseUrl: json['response_url'],
      logs: (json['logs'] as List<dynamic>)
          .map((e) => RequestLog.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CompletedStatus extends QueueStatus {
  List<RequestLog> logs;

  CompletedStatus({
    required String responseUrl,
    required this.logs,
  }) : super('COMPLETED', responseUrl);

  factory CompletedStatus.fromMap(Map<String, dynamic> json) {
    return CompletedStatus(
      responseUrl: json['response_url'],
      logs: (json['logs'] as List<dynamic>)
          .map((e) => RequestLog.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class InQueueStatus extends QueueStatus {
  int queuePosition;

  InQueueStatus({
    required String responseUrl,
    required this.queuePosition,
  }) : super('IN_QUEUE', responseUrl);

  factory InQueueStatus.fromMap(Map<String, dynamic> json) {
    return InQueueStatus(
      responseUrl: json['response_url'],
      queuePosition: json['queue_position'],
    );
  }
}

abstract class Queue {
  Future<EnqueueResult> submit(
    String id, {
    String path = '',
    Map<String, dynamic>? input,
  });

  Future<QueueStatus> status(
    String id, {
    required String requestId,
    bool logs,
  });

  Future<Map<String, dynamic>> result(String id, {required String requestId});
}

class QueueClient implements Queue {
  final Config config;

  QueueClient({required this.config});

  @override
  Future<EnqueueResult> submit(String id,
      {String path = '', Map<String, dynamic>? input}) async {
    final result = await sendRequest(id,
        config: config, path: '$path/fal/queue/submit', input: input);
    return EnqueueResult.fromMap(result);
  }

  @override
  Future<QueueStatus> status(String id,
      {required String requestId, bool logs = false}) async {
    final result = await sendRequest(id,
        config: config,
        method: 'get',
        path: '/fal/queue/requests/$requestId/status');
    return QueueStatus.fromMap(result);
  }

  @override
  Future<Map<String, dynamic>> result(String id,
      {required String requestId}) async {
    return sendRequest(id,
        config: config,
        method: 'get',
        path: '/fal/queue/requests/$requestId/response');
  }
}
