class PickedModelSource {
  const PickedModelSource(this.path, this.name);
  final String path;
  final String name;
}

typedef PickModelSource = Future<PickedModelSource?> Function();
