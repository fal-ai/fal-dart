import 'dart:html';

import './base.dart';

class PlatformInfo extends BasePlatformInfo {
  String? _memoizedUserAgent;

  @override
  String get userAgent {
    if (_memoizedUserAgent == null) {
      _memoizedUserAgent = '$userAgentPrefix - ${window.navigator.userAgent}';
    }
    return _memoizedUserAgent!;
  }

  @override
  String get userAgentHeader => "X-Fal-User-Agent";
}
