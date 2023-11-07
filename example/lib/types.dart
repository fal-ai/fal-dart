class IllusionDiffusionResult {
  final ImageRef image;
  final int seed;

  IllusionDiffusionResult({required this.image, required this.seed});

  factory IllusionDiffusionResult.fromMap(Map<String, dynamic> json) {
    return IllusionDiffusionResult(
      image: ImageRef.fromMap(json['image'] as Map<String, dynamic>),
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

const textToImageId = '54285744-illusion-diffusion';
