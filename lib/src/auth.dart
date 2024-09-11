import './config.dart';
import './http.dart';

const _defaultTokenExpiration = 180;

Future<String> createJwtToken(
    {required List<String> apps,
    required Config config,
    int expiration = _defaultTokenExpiration}) async {
  final response = await sendRequest("https://rest.alpha.fal.ai/tokens/",
      config: config,
      method: "POST",
      input: {"allowed_apps": apps, "token_expiration": expiration});
  return response as String;
}
