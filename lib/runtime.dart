import 'package:platform/platform.dart';

// In Dart, we can use the dart:html library to check for browser-specific features
bool isBrowser() {
  return identical(1.0, 1); // This checks if we're on the JavaScript platform
}

String? _memoizedUserAgent;

String? getUserAgent() {
  if (isBrowser()) {
    return null;
    // return window.navigator.userAgent;
    // return window.navigator.userAgent;
  }
  if (_memoizedUserAgent != null) {
    return _memoizedUserAgent!;
  }

  const packageVersion = '1.0.0';

  const platform = LocalPlatform();
  _memoizedUserAgent =
      'fal.ai/dart-client@$packageVersion (${platform.operatingSystem} ${platform.version})';
  return _memoizedUserAgent!;
}
