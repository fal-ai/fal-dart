# The fal.ai Dart/Flutter client

![fal_client pub.dev package](https://img.shields.io/pub/v/fal_client?color=%237527D7&label=fal_client&style=flat-square)
![Build](https://img.shields.io/github/actions/workflow/status/fal-ai/serverless-client-dart/build.yml?style=flat-square)
![License](https://img.shields.io/github/license/fal-ai/serverless-client-dart?style=flat-square)

## About the Project

The `fal_client` is a robust and user-friendly library designed for seamless integration of fal serverless functions in Dart and Flutter projects. Developed in pure Dart, it provides developers with simple APIs to interact with AI models and works across all supported Flutter platforms.

## Getting Started

The `fal_client` library serves as a client for fal serverless Python functions. For guidance on creating your functions, refer to the [quickstart guide](https://fal.ai/docs).

### Client Library

This client library is crafted as a lightweight layer atop platform standards like `http` and `cross_file`. This ensures a hassle-free integration into your existing codebase. Moreover, it addresses platform disparities, guaranteeing flawless operation across various Flutter runtimes.

> **Note:**
> Ensure you've reviewed the [fal-serverless getting started guide](https://fal.ai/docs) to acquire your credentials and register your functions.

1. Start by adding `fal_client` as a dependency:

  ```sh
  flutter pub add fal_client
  ```

2. Setup the client instance:

  ```dart
  import "package:fal_client/client.dart";

  final fal = FalClient.withCredentials("FAL_KEY_ID:FAL_KEY_SECRET");
  ```

3. Now use `fal.subcribe` to dispatch requests to the model API:

  ```dart
  final result = await fal.subscribe('110602490-lora',
    input: {
      'prompt': 'a cute shih-tzu puppy',
      'model_name': 'stabilityai/stable-diffusion-xl-base-1.0',
      'image_size': 'square_hd'
    },
    onQueueUpdate: (update) => {print(update)}
  );
  ```

**Notes:**

- Replace `text-to-image` with a valid model id. Check [fal.ai/models](https://fal.ai/models) for all available models.
- The result type is a `Map<String, dynamic>` and the entries depend on the API output schema.

## Roadmap

See the [open feature requests](https://github.com/fal-ai/serverless-client-dart/labels/enhancement) for a list of proposed features and join the discussion.

## Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Make sure you read our [Code of Conduct](https://github.com/fal-ai/serverless-client-dart/blob/main/CODE_OF_CONDUCT.md)
2. Fork the project and clone your fork
3. Setup the local environment with `npm install`
4. Create a feature branch (`git checkout -b feature/add-cool-thing`) or a bugfix branch (`git checkout -b fix/smash-that-bug`)
5. Commit the changes (`git commit -m 'feat(client): added a cool thing'`) - use [conventional commits](https://conventionalcommits.org)
6. Push to the branch (`git push --set-upstream origin feature/add-cool-thing`)
7. Open a Pull Request

Check the [good first issue queue](https://github.com/fal-ai/serverless-client-dart/labels/good+first+issue), your contribution will be welcome!

## License

Distributed under the MIT License. See [LICENSE](https://github.com/fal-ai/serverless-client-dart/blob/main/LICENSE) for more information.
