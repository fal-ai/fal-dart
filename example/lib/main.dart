import 'package:fal_client/fal_client.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'types.dart';

// You can use the proxyUrl to protect your credentials in production.
// final fal = FalClient.withProxy('http://localhost:3333/api/_fal/proxy');

// You can also use the credentials locally for development, but make sure
// you protected your credentials behind a proxy in production.
final fal = FalClient.withCredentials('FAL_KEY_ID:FAL_KEY_SECRET');

void main() {
  runApp(const FalSampleApp());
}

class FalSampleApp extends StatelessWidget {
  const FalSampleApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fal.ai',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.indigo, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const TextoToImageScreen(title: 'fal.ai'),
    );
  }
}

class TextoToImageScreen extends StatefulWidget {
  const TextoToImageScreen({super.key, required this.title});
  final String title;

  @override
  State<TextoToImageScreen> createState() => _TextoToImageScreenState();
}

class _TextoToImageScreenState extends State<TextoToImageScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  final TextEditingController _promptController = TextEditingController();
  String? _generatedImageUrl;
  bool _isProcessing = false;

  Future<String> generateImage(XFile image, String prompt) async {
    final result = await fal.subscribe(textToImageId, input: {
      'prompt': prompt,
      'image_url': image,
    });
    return result['image']['url'] as String;
  }

  void _onGenerateImage() async {
    if (_image == null || _promptController.text.isEmpty) {
      // Handle error: either image not selected or prompt not entered
      return;
    }
    setState(() {
      _isProcessing = true;
    });
    String imageUrl = await generateImage(_image!, _promptController.text);
    setState(() {
      _generatedImageUrl = imageUrl;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Illusion Diffusion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);
                setState(() {
                  _image = image;
                });
              },
              child: const Text('Pick Image'),
            ),
            // if (_image != null)
            // Image,
            TextFormField(
              controller: _promptController,
              decoration: const InputDecoration(labelText: 'Imagine...'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _onGenerateImage,
              child: _isProcessing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(),
                        ),
                        SizedBox(width: 8),
                        Text('Generating...'),
                      ],
                    )
                  : const Text('Generate Image'),
            ),
            if (_generatedImageUrl != null)
              Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Image.network(_generatedImageUrl!)),
          ],
        ),
      ),
    );
  }
}
