import './config.dart';
import './http.dart';

/// Data structure that represents the enqueued request and contains the [requestId].
class EnqueueResult {
  String requestId;

  EnqueueResult(this.requestId);

  factory EnqueueResult.fromMap(Map<String, dynamic> json) {
    return EnqueueResult(json['request_id']);
  }
}

/// Data structure that represents a log entry in the queue.
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

/// Data structure that represents the status of a request in the queue.
/// This is the base class for the different statuses: [InProgressStatus],
/// [CompletedStatus] and [InQueueStatus].
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

/// Indicates that the queue is currently processing the request.
class InProgressStatus extends QueueStatus {
  List<RequestLog> logs;

  InProgressStatus({
    required String responseUrl,
    required this.logs,
  }) : super('IN_PROGRESS', responseUrl);

  factory InProgressStatus.fromMap(Map<String, dynamic> json) {
    return InProgressStatus(
      responseUrl: json['response_url'],
      logs: ((json['logs'] ?? []) as List<dynamic>)
          .map((e) => RequestLog.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Indicates that the request has been completed and contains the [logs].
class CompletedStatus extends QueueStatus {
  List<RequestLog> logs;

  CompletedStatus({
    required String responseUrl,
    required this.logs,
  }) : super('COMPLETED', responseUrl);

  factory CompletedStatus.fromMap(Map<String, dynamic> json) {
    return CompletedStatus(
      responseUrl: json['response_url'],
      logs: ((json['logs'] ?? []) as List<dynamic>)
          .map((e) => RequestLog.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Indicates that the request is still in the queue and contains the [queuePosition].
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

/// This establishes the contract of the client with the queue API.
abstract class Queue {
  /// Submits a request to the given [id], an optional [path]. This method
  /// uses the [queue] API to initiate the request. Next you need to rely on
  /// [status] and [result] to poll for the result.
  Future<EnqueueResult> submit(
    String id, {
    String path = '',
    Map<String, dynamic>? input,
  });

  /// Checks the queue for the status of the request with the given [requestId].
  /// See [QueueStatus] for the different statuses.
  Future<QueueStatus> status(
    String id, {
    required String requestId,
    bool logs,
  });

  /// Retrieves the result of the request with the given [requestId]
  /// once the queue status is [CompletedStatus].
  Future<Map<String, dynamic>> result(String id, {required String requestId});
}

class QueueClient implements Queue {
  final Config config;

  QueueClient({required this.config});

  @override
  Future<EnqueueResult> submit(String id,
      {String path = '', Map<String, dynamic>? input}) async {
    final result = await sendRequest(id,
        config: config, path: '/fal/queue/submit$path', input: input);
    return EnqueueResult.fromMap(result);
  }

  @override
  Future<QueueStatus> status(String id,
      {required String requestId, bool logs = false}) async {
    final result = await sendRequest(id,
        config: config,
        method: 'get',
        path: '/fal/queue/requests/$requestId/status',
        input: {
          'logs': logs ? '1' : '0',
        });
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
