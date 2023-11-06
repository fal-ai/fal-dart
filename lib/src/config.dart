/// Config class for the client. You can setup the [credentials] or
/// a [proxyUrl] to use a server-side proxy that can handle and protect
/// credentials.
class Config {
  String credentials;
  String host;
  String? proxyUrl;

  Config({
    this.credentials = '',
    this.host = 'gateway.alpha.fal.ai',
    this.proxyUrl,
  });
}
