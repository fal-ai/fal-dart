import 'package:fal_client/fal_client.dart';
import 'package:flutter/material.dart';

import 'types.dart';

// You can use the proxyUrl to protect your credentials in production.
// final fal = FalClient.withProxy('http://localhost:3333/api/fal/proxy');

// You can also use the credentials locally for development, but make sure
// you protected your credentials behind a proxy in production.
final fal = FalClient.withCredentials('FAL_KEY');

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
  final TextEditingController _promptController = TextEditingController();
  String? _generatedImageUrl;
  bool _isProcessing = false;

  Future<String> generateImage(String prompt) async {
    final output = await fal.subscribe("fal-ai/flux/dev",
        input: {
          'prompt': prompt,
        },
        mode: SubscriptionMode.pollingWithInterval(Duration(seconds: 1)));
    print(output.requestId);
    final data = FluxOutput.fromMap(output.data);
    return data.images.first.url;
  }

  void _onGenerateImage() async {
    setState(() {
      _isProcessing = true;
    });
    String imageUrl = await generateImage(_promptController.text);
    setState(() {
      _generatedImageUrl = imageUrl;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FLUX.1 [dev]'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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
