import '../version.dart';

abstract class BasePlatformInfo {
  String get userAgent;

  String get userAgentHeader;
}

const userAgentPrefix = 'fal.ai/dart-client@${packageVersion}';
