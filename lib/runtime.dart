import 'package:platform/platform.dart';

// In Dart, we can use the dart:html library to check for browser-specific features
bool isBrowser() {
  return false;
}

String? _memoizedUserAgent;

String? getUserAgent() {
  if (isBrowser()) {
    return null;
  }
  if (_memoizedUserAgent != null) {
    return _memoizedUserAgent!;
  }

  const packageVersion = '0.1.0';

  const platform = LocalPlatform();
  _memoizedUserAgent =
      'fal.ai/dart-client@$packageVersion (${platform.version} ${platform.operatingSystemVersion})';
  return _memoizedUserAgent!;
}
