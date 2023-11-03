library fal_client;

import 'package:fal_client/storage.dart';

import './config.dart';
import './exception.dart';
import './http.dart';
import './queue.dart';

abstract class Client {
  Queue get queue;

  Storage get storage;

  Future<Map<String, dynamic>> run(
    String id, {
    String method = 'post',
    String path = '',
    Map<String, dynamic>? input,
  });

  Future<Map<String, dynamic>> subscribe(
    String id, {
    String path = '',
    Map<String, dynamic>? input,
    int pollInterval = 3000,
    bool logs = false,
  });
}

class FalClient implements Client {
  final Config config;

  @override
  final Queue queue;

  @override
  final Storage storage;

  FalClient({
    required this.config,
  })  : queue = QueueClient(config: config),
        storage = StorageClient(config: config);

  factory FalClient.withProxy(String proxyUrl) {
    return FalClient(config: Config(proxyUrl: proxyUrl));
  }

  factory FalClient.withCredentials(String credentials) {
    return FalClient(config: Config(credentials: credentials));
  }

  @override
  Future<Map<String, dynamic>> run(
    String id, {
    String method = 'post',
    String path = '',
    Map<String, dynamic>? input,
  }) async {
    final transformedInput =
        input != null ? await storage.transformInput(input) : null;
    return await sendRequest(
      id,
      config: config,
      method: method,
      input: transformedInput,
    );
  }

  @override
  Future<Map<String, dynamic>> subscribe(String id,
      {String path = '',
      Map<String, dynamic>? input,
      int pollInterval = 3000, // 3 seconds
      int timeout = 300000, // 5 minutes
      bool logs = false,
      Function(String)? onEnqueue,
      Function(QueueStatus)? onQueueUpdate}) async {
    final transformedInput =
        input != null ? await storage.transformInput(input) : null;
    final enqueued =
        await queue.submit(id, input: transformedInput, path: path);
    final requestId = enqueued.requestId;

    if (onEnqueue != null) {
      onEnqueue(requestId);
    }

    return _pollForResult(
      id,
      requestId: requestId,
      logs: logs,
      pollInterval: pollInterval,
      timeout: timeout,
      onQueueUpdate: onQueueUpdate,
    );
  }

  Future<Map<String, dynamic>> _pollForResult(
    String id, {
    required String requestId,
    required bool logs,
    required int pollInterval,
    required int timeout,
    Function(QueueStatus)? onQueueUpdate,
  }) async {
    final expiryTime = DateTime.now().add(Duration(milliseconds: timeout));

    while (true) {
      if (DateTime.now().isAfter(expiryTime)) {
        throw FalApiException(
            message: 'Request timed out after $timeout milliseconds.',
            status: 408);
      }
      final queueStatus =
          await queue.status(id, requestId: requestId, logs: logs);

      if (onQueueUpdate != null) {
        onQueueUpdate(queueStatus);
      }

      if (queueStatus is CompletedStatus) {
        return await queue.result(id, requestId: requestId);
      }
      await Future.delayed(Duration(milliseconds: pollInterval));
    }
  }
}
