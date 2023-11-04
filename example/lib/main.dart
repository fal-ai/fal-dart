import 'package:fal_client/client.dart';
import 'package:flutter/material.dart';

// final fal = FalClient.withProxy("http://localhost:3333/api/_fal/proxy");

// You can also use the credentials locally for development, but make sure
// you protected your credentials behind a proxy in production.
final fal = FalClient.withCredentials(
    "adf7f57f-d316-41c3-bb12-552356340cfe:d16be5f12c0091c1dc22696a2fd07c9b");

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'fal.ai',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const TextoToImageScreen(title: 'fal.ai'),
    );
  }
}

class TextToImageResult {
  final List<ImageRef> images;
  final int seed;

  TextToImageResult({required this.images, required this.seed});

  factory TextToImageResult.fromMap(Map<String, dynamic> json) {
    return TextToImageResult(
      images: (json['images'] as List<dynamic>)
          .map((e) => ImageRef.fromMap(e as Map<String, dynamic>))
          .toList(),
      seed: json['seed'],
    );
  }
}

class ImageRef {
  final String url;
  final int height;
  final int width;

  ImageRef({required this.url, required this.height, required this.width});

  factory ImageRef.fromMap(Map<String, dynamic> json) {
    return ImageRef(
      url: json['url'],
      height: json['height'],
      width: json['width'],
    );
  }
}

class TextoToImageScreen extends StatefulWidget {
  const TextoToImageScreen({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<TextoToImageScreen> createState() => _TextoToImageScreenState();
}

class _TextoToImageScreenState extends State<TextoToImageScreen> {
  bool _isLoading = false;
  final _promptController =
      TextEditingController(text: "a cute shih-tzu puppy");
  ImageRef? _image;

  void _generateImage() async {
    setState(() {
      _isLoading = true;
      _image = null;
    });
    final result = await fal.subscribe("110602490-lora", input: {
      "prompt": _promptController.text,
      "model_name": "stabilityai/stable-diffusion-xl-base-1.0",
      "image_size": "square_hd"
    });
    setState(() {
      _isLoading = false;
      _image = TextToImageResult.fromMap(result).images[0];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(controller: _promptController),
            if (_isLoading) const CircularProgressIndicator(),
            if (!_isLoading && _image != null)
              FittedBox(
                fit: BoxFit.fill,
                child: Image.network(_image!.url,
                    width: _image!.width.toDouble(),
                    height: _image!.height.toDouble()),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateImage,
        tooltip: 'Generate',
        child: const Icon(Icons.play_arrow_rounded),
      ),
    );
  }
}
