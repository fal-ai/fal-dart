import 'dart:convert';
import 'package:http/http.dart' as http;

import './config.dart';
import './exception.dart';
import './runtime/platform.dart';

bool isValidUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host.contains("fal.ai");
  } catch (e) {
    return false;
  }
}

final platform = PlatformInfo();

/// Builds a URL for the given [id], an optional [path], using the [config] to determine
/// the host and input when present.
String buildUrl(
  String id, {
  required Config config,
  String method = 'post',
  String path = '',
  Map<String, dynamic>? input,
}) {
  final pathValue = path.replaceAll(RegExp(r'^/|/{2,}'), '');
  final params = method.toLowerCase() == 'get' && input != null
      ? Uri(queryParameters: input)
      : null;
  final queryParams =
      params != null && params.query.isNotEmpty ? '?${params.query}' : '';

  return isValidUrl(id)
      ? 'id$queryParams'
      : 'https://$id.${config.host}/$pathValue$queryParams';
}

/// Sends a request to the given [id], an optional [path]. It relies on
/// [buildUrl] to determine the host and input when present.
///
/// When [config.proxyUrl] is present, it will be used as the base URL for the request,
/// and send the `x-fal-target-url` header with the original URL, so server-side
/// proxies can forward the request to [fal.ai](https://fal.ai).
Future<Map<String, dynamic>> sendRequest(
  String id, {
  required Config config,
  String method = 'post',
  String path = '',
  Map<String, dynamic>? input,
}) async {
  final url = buildUrl(
    id,
    config: config,
    method: method,
    path: path,
    input: input,
  );
  final headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
  };
  headers[platform.userAgentHeader] = platform.userAgent;
  if (config.credentials.trim().isNotEmpty) {
    headers['Authorization'] = 'Key ${config.credentials}';
  }
  if (config.proxyUrl != null) {
    headers['X-Fal-Target-Url'] = url;
  }

  final request = http.Request(
    method.toUpperCase(),
    Uri.parse(config.proxyUrl ?? url),
  );
  request.headers.addAll(headers);

  if (method.toLowerCase() != 'get' && input != null) {
    request.body = jsonEncode(input);
  }

  final response = await request.send();
  final body = await response.stream.bytesToString();

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return jsonDecode(body);
  }

  if (response.statusCode == 422) {
    final error = jsonDecode(body);
    throw ValidationException.fromMap(error);
  }

  throw FalApiException(
      status: response.statusCode, message: body, body: jsonDecode(body));
}
