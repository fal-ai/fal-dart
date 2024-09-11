const List<String> APP_NAMESPACES = ["workflows", "comfy"];

typedef AppNamespace = String;

class EndpointId {
  final String owner;
  final String alias;
  final String? path;
  final AppNamespace? namespace;

  EndpointId({
    required this.owner,
    required this.alias,
    this.path,
    this.namespace,
  });
}

EndpointId parseEndpointId(String id) {
  final parts = id.split("/");
  if (APP_NAMESPACES.contains(parts[0])) {
    return EndpointId(
      owner: parts[1],
      alias: parts[2],
      path: parts.sublist(3).join("/"),
      namespace: parts[0],
    );
  }
  return EndpointId(
    owner: parts[0],
    alias: parts[1],
    path: parts.sublist(2).join("/"),
  );
}
