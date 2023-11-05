import './base.dart';

class PlatformInfo extends BasePlatformInfo {
  @override
  String get userAgent => throw UnimplementedError();

  @override
  String get userAgentHeader => throw UnimplementedError();
}
