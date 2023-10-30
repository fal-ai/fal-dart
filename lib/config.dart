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
