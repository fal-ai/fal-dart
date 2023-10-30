import 'dart:convert';

import 'package:http/http.dart' as http;

import './config.dart';
import './exception.dart';

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

  return 'https://$id.${config.host}/$pathValue$queryParams';
}

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
    // 'User-Agent': getUserAgent(),
  };
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

  if (input != null) {
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
