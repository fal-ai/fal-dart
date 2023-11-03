import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;

import './config.dart';
import './http.dart';

bool isDataUri(String uri) {
  return uri.startsWith("data:");
}

abstract class Storage {
  Future<String> upload(XFile file);

  Future<Map<String, dynamic>> transformInput(Map<String, dynamic> input);
}

class StorageClient implements Storage {
  final Config config;

  StorageClient({
    required this.config,
  });

  @override
  Future<String> upload(XFile file) async {
    final restDomain = config.host.replaceFirst("gateway", "rest");
    final url = 'https://${restDomain}/storage/upload/initiate';
    final contentType = file.mimeType ?? 'application/octet-stream';
    final signedUpload = await sendRequest(url,
        input: {
          'filename': file.name,
          'content_type': contentType,
        },
        config: config);

    final uploadUrl = signedUpload['upload_url'];
    final data = await file.readAsBytes();
    await http.put(
      Uri.parse(uploadUrl),
      headers: {
        'Content-Type': contentType,
      },
      body: data,
    );
    return signedUpload['file_url'];
  }

  @override
  Future<Map<String, dynamic>> transformInput(
      Map<String, dynamic> input) async {
    List<Future<MapEntry<String, dynamic>>> futures = [];

    for (var entry in input.entries) {
      var key = entry.key;
      var value = entry.value;

      if (value is XFile) {
        futures.add(() async {
          String url = await upload(value);
          return MapEntry(key, url);
        }());
      } else {
        futures.add(Future.value(MapEntry(key, value)));
      }
    }

    final results = await Future.wait(futures);
    return Map.fromEntries(results);
  }
}
