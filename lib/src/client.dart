import './config.dart';
import './exception.dart';
import './http.dart';
import './queue.dart';
import './storage.dart';

/// The main client class that provides access to simple API model usage,
/// as well as access to the [queue] and [storage] APIs.
///
/// Example:
///
/// ```dart
/// import 'package:fal_client/client.dart';
///
/// final fal = FalClient.withCredentials("fal_key_id:fal_key_secret");
///
/// void main() async {
///   // check https://fal.ai/models for the available models
///   final result = await fal.subscribe('text-to-image', input: {
///     'prompt': 'a cute shih-tzu puppy',
///     'model_name': 'stabilityai/stable-diffusion-xl-base-1.0',
///   });
///   print(result);
/// }
/// ```
abstract class Client {
  /// The queue client with specific methods to interact with the queue API.
  ///
  /// **Note:** that the [subscribe] method is a convenience method that uses the
  /// [queue] client to submit a request and poll for the result.
  Queue get queue;

  /// The storage client with specific methods to interact with the storage API.
  ///
  /// **Note:** both [run] and [subscribe] auto-upload files using the [storage]
  /// when an [XFile] is passed as an input property value.
  Storage get storage;

  /// Sends a request to the given [id], an optional [path]. This method
  /// is a direct request to the model API and it waits for the processing
  /// to complete before returning the result.
  ///
  /// This is useful for short running requests, but it's not recommended for
  /// long running requests, for those see [submit].
  Future<Map<String, dynamic>> run(
    String id, {
    String method = 'post',
    String path = '',
    Map<String, dynamic>? input,
  });

  /// Submits a request to the given [id], an optional [path]. This method
  /// uses the [queue] API to submit the request and poll for the result.
  ///
  /// This is useful for long running requests, and it's the preffered way
  /// to interact with the model APIs.
  Future<Map<String, dynamic>> subscribe(
    String id, {
    String path = '',
    Map<String, dynamic>? input,
    int pollInterval = 3000,
    bool logs = false,
  });
}

/// The default implementation of the [Client] contract.
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
