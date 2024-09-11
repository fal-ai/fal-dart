import 'dart:convert';
import 'package:fal_client/src/common.dart';
import 'package:http/http.dart' as http;

import './config.dart';
import './exception.dart';
import './runtime/platform.dart';

bool isValidUrl(String url) {
  try {
    final uri = Uri.parse(url);
    return uri.host.contains("fal.ai") || uri.host.contains("fal.run");
  } catch (e) {
    return false;
  }
}

final platform = PlatformInfo();

/// Builds a URL for the given [endpointId], an optional [path], using the [config] to determine
/// the host and input when present.
String buildUrl(
  String endpointId, {
  required Config config,
  String method = 'post',
  String path = '',
  String subdomain = '',
  Map<String, dynamic>? input,
  Map<String, String>? query,
}) {
  final pathValue = path.replaceAll(RegExp(r'/{2,}|/$'), '');
  var params = method.toLowerCase() == 'get' && input != null
      ? Uri(queryParameters: input)
      : null;
  if (query != null && query.isNotEmpty) {
    if (params != null) {
      params.queryParameters.addAll(query);
    } else {
      params = Uri(queryParameters: query);
    }
  }
  final queryParams =
      params != null && params.query.isNotEmpty ? '?${params.query}' : '';

  final subdomainValue = subdomain.isNotEmpty ? '$subdomain.' : '';
  return isValidUrl(endpointId)
      ? '$endpointId$queryParams'
      : 'https://${subdomainValue}fal.run/${endpointId}$pathValue$queryParams';
}

/// Sends a request to the given [endpointId], an optional [path]. It relies on
/// [buildUrl] to determine the host and input when present.
///
/// When [config.proxyUrl] is present, it will be used as the base URL for the request,
/// and send the `x-fal-target-url` header with the original URL, so server-side
/// proxies can forward the request to [fal.ai](https://fal.ai).
Future<http.StreamedResponse> sendRequest(
  String endpointId, {
  required Config config,
  String method = 'post',
  String path = '',
  String subdomain = '',
  Map<String, dynamic>? input,
  Map<String, String>? query,
}) async {
  final url = buildUrl(
    endpointId,
    config: config,
    method: method,
    path: path,
    subdomain: subdomain,
    input: input,
    query: query,
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
    headers['x-fal-target-url'] = url;
  }

  final request = http.Request(
    method.toUpperCase(),
    Uri.parse(config.proxyUrl ?? url),
  );
  request.headers.addAll(headers);

  if (method.toLowerCase() != 'get' && input != null) {
    request.body = jsonEncode(input);
  }

  return request.send();
}

Future<Map<String, dynamic>> handleJsonResponse(
    http.StreamedResponse response) async {
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

Future<FalOutput> convertResponseToOutput(
    http.StreamedResponse response) async {
  final data = await handleJsonResponse(response);
  final requestId = response.headers['x-fal-request-id'] ?? '';
  return FalOutput(data: data, requestId: requestId);
}
