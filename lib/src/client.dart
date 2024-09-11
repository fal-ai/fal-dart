import './config.dart';
import './exception.dart';
import './http.dart';
import './queue.dart';
import './storage.dart';
import 'common.dart';

abstract class SubscriptionMode {
  static const SubscriptionMode streaming = StreamingMode();
  static const SubscriptionMode polling = PollingMode();

  static SubscriptionMode pollingWithInterval(Duration interval) {
    return PollingMode(pollInterval: interval);
  }

  const SubscriptionMode();
}

class PollingMode extends SubscriptionMode {
  final Duration pollInterval;

  const PollingMode({
    this.pollInterval = const Duration(milliseconds: 500),
  }) : super();
}

class StreamingMode extends SubscriptionMode {
  const StreamingMode() : super();
}

/// The main client class that provides access to simple API model usage,
/// as well as access to the [queue] and [storage] APIs.
///
/// Example:
///
/// ```dart
/// import 'package:fal_client/client.dart';
///
/// final fal = FalClient.withCredentials("FAL_KEY");
///
/// void main() async {
///   // check https://fal.ai/models for the available models
///   final output = await fal.subscribe('fal-ai/flux/dev', input: {
///     'prompt': 'a cute shih-tzu puppy',
///   });
///   print(output.data);
///   print(output.requestId);
/// }
/// ```
abstract class FalClient {
  /// The queue client with specific methods to interact with the queue API.
  ///
  /// **Note:** that the [subscribe] method is a convenience method that uses the
  /// [queue] client to submit a request and poll for the result.
  QueueClient get queue;

  /// The storage client with specific methods to interact with the storage API.
  ///
  /// **Note:** both [run] and [subscribe] auto-upload files using the [storage]
  /// when an [XFile] is passed as an input property value.
  StorageClient get storage;

  /// Sends a request to the given [endpointId]. This method
  /// is a direct request to the model API and it waits for the processing
  /// to complete before returning the result.
  ///
  /// This is useful for short running requests, but it's not recommended for
  /// long running requests, for those see [submit].
  Future<FalOutput> run(
    String endpointId, {
    String method = 'post',
    Map<String, dynamic>? input,
  });

  /// Submits a request to the given [endpointId]. This method
  /// uses the [queue] API to submit the request and poll for the result.
  ///
  /// This is useful for long running requests, and it's the preffered way
  /// to interact with the model APIs.
  ///
  /// The [webhookUrl] is the URL where the server will send the result once
  /// the request is completed. This is particularly useful when you want to
  /// receive the result in a different server and for long running requests.
  Future<FalOutput> subscribe(String endpointId,
      {Map<String, dynamic>? input,
      SubscriptionMode mode,
      Duration timeout = const Duration(minutes: 5),
      bool logs = false,
      String? webhookUrl,
      Function(String)? onEnqueue,
      Function(QueueStatus)? onQueueUpdate});

  factory FalClient.withProxy(String proxyUrl) {
    return FalClientImpl(config: Config(proxyUrl: proxyUrl));
  }

  factory FalClient.withCredentials(String credentials) {
    return FalClientImpl(config: Config(credentials: credentials));
  }
}

/// The default implementation of the [Client] contract.
class FalClientImpl implements FalClient {
  final Config config;

  @override
  final QueueClient queue;

  @override
  final StorageClient storage;

  FalClientImpl({
    required this.config,
  })  : queue = QueueClientImpl(config: config),
        storage = StorageClientImpl(config: config);

  @override
  Future<FalOutput> run(
    String endpointId, {
    String method = 'post',
    Map<String, dynamic>? input,
  }) async {
    final transformedInput =
        input != null ? await storage.transformInput(input) : null;
    final response = await sendRequest(
      endpointId,
      config: config,
      method: method,
      input: transformedInput,
    );
    return convertResponseToOutput(response);
  }

  @override
  Future<FalOutput> subscribe(String endpointId,
      {Map<String, dynamic>? input,
      SubscriptionMode mode = SubscriptionMode.polling,
      Duration timeout = const Duration(minutes: 5),
      bool logs = false,
      String? webhookUrl,
      Function(String)? onEnqueue,
      Function(QueueStatus)? onQueueUpdate}) async {
    final transformedInput =
        input != null ? await storage.transformInput(input) : null;
    final enqueued = await queue.submit(endpointId,
        input: transformedInput, webhookUrl: webhookUrl);
    if (onEnqueue != null) {
      onEnqueue(enqueued.requestId);
    }
    final requestId = enqueued.requestId;

    if (onEnqueue != null) {
      onEnqueue(requestId);
    }

    if (mode is PollingMode) {
      return _pollForResult(
        endpointId,
        requestId: requestId,
        logs: logs,
        pollInterval: mode.pollInterval,
        timeout: timeout,
        onQueueUpdate: onQueueUpdate,
      );
    }

    throw UnimplementedError('Streaming mode is not yet implemented.');
  }

  Future<FalOutput> _pollForResult(
    String endpointId, {
    required String requestId,
    required bool logs,
    required Duration pollInterval,
    required Duration timeout,
    Function(QueueStatus)? onQueueUpdate,
  }) async {
    final expiryTime = DateTime.now().add(timeout);

    while (true) {
      if (DateTime.now().isAfter(expiryTime)) {
        throw FalApiException(
            message: 'Request timed out after $timeout milliseconds.',
            status: 408);
      }
      final queueStatus =
          await queue.status(endpointId, requestId: requestId, logs: logs);

      if (onQueueUpdate != null) {
        onQueueUpdate(queueStatus);
      }

      if (queueStatus is CompletedStatus) {
        return await queue.result(endpointId, requestId: requestId);
      }
      await Future.delayed(pollInterval);
    }
  }
}
