import 'package:fal_client/src/common.dart';
import 'package:fal_client/src/util.dart';

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
abstract class QueueClient {
  /// Submits a request to the given [endpointId]. This method
  /// uses the [queue] API to initiate the request. Next you need to rely on
  /// [status] and [result] to poll for the result.
  ///
  /// The [webhookUrl] is the URL where the server will send the result once
  /// the request is completed. This is particularly useful when you want to
  /// receive the result in a different server and for long running requests.
  Future<EnqueueResult> submit(String endpointId,
      {Map<String, dynamic>? input, String? webhookUrl});

  /// Checks the queue for the status of the request with the given [requestId].
  /// See [QueueStatus] for the different statuses.
  Future<QueueStatus> status(
    String endpointId, {
    required String requestId,
    bool logs,
  });

  /// Retrieves the result of the request with the given [requestId]
  /// once the queue status is [CompletedStatus].
  Future<FalOutput> result(String endpointId, {required String requestId});
}

class QueueClientImpl implements QueueClient {
  final Config config;

  QueueClientImpl({required this.config});

  @override
  Future<EnqueueResult> submit(String endpointId,
      {Map<String, dynamic>? input, String? webhookUrl}) async {
    final queryParams = {
      if (webhookUrl != null) 'fal_webhook': webhookUrl,
    };
    final response = await sendRequest(endpointId,
        config: config, subdomain: "queue", input: input, query: queryParams);
    final result = await handleJsonResponse(response);
    return EnqueueResult.fromMap(result);
  }

  @override
  Future<QueueStatus> status(String endpointId,
      {required String requestId, bool logs = false}) async {
    final id = parseEndpointId(endpointId);
    final response = await sendRequest("${id.owner}/${id.alias}",
        config: config,
        method: 'get',
        path: '/requests/$requestId/status',
        subdomain: "queue",
        input: {
          'logs': logs ? '1' : '0',
        });
    final result = await handleJsonResponse(response);
    return QueueStatus.fromMap(result);
  }

  @override
  Future<FalOutput> result(String endpointId,
      {required String requestId}) async {
    final id = parseEndpointId(endpointId);
    final response = await sendRequest("${id.owner}/${id.alias}",
        config: config,
        method: 'get',
        path: '/requests/$requestId',
        subdomain: "queue");
    return convertResponseToOutput(response);
  }
}
