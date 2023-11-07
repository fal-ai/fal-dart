import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;

import './config.dart';
import './http.dart';

/// This establishes the contract of the client with the file storage capabilities.
/// Long running requests cannot keep files in memory, so models that require
/// files/images as input need to upload them and submit their URLs instead.
///
/// This is done by the [StorageClient] class, which allows users to pass [XFile]
/// instances as input, and have them automatically uploaded.
abstract class Storage {
  /// Uploads a file to the storage service and returns its URL.
  Future<String> upload(XFile file);

  /// Transforms the input map, automatic uploading [XFile] instances using
  /// [upload] and replacing them with their URLs.
  Future<Map<String, dynamic>> transformInput(Map<String, dynamic> input);
}

/// This is the default implementation of the [Storage] contract.
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
          'file_name': file.name,
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
