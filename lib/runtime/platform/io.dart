import 'dart:io';

import './base.dart';

class PlatformInfo extends BasePlatformInfo {
  String? _memoizedUserAgent;

  @override
  String get userAgent {
    if (_memoizedUserAgent == null) {
      _memoizedUserAgent =
          '$userAgentPrefix - ${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    }
    return _memoizedUserAgent!;
  }

  @override
  String get userAgentHeader => "User-Agent";
}
