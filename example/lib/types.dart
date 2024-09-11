class FluxOutput {
  final List<ImageRef> images;
  final int seed;

  FluxOutput({
    required this.images,
    required this.seed,
  });

  factory FluxOutput.fromMap(Map<String, dynamic> json) {
    return FluxOutput(
      images: ((json['images'] ?? []) as List<dynamic>)
          .map((e) => ImageRef.fromMap(e as Map<String, dynamic>))
          .toList(),
      seed: (json['seed'] * 1).round(),
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
      height: (json['height'] * 1).round(),
      width: (json['width'] * 1).round(),
    );
  }
}
