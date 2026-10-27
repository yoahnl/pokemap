final class SpatialLiftDefinition {
  SpatialLiftDefinition({
    required this.id,
    required this.name,
    required this.instanceId,
    required this.x,
    required this.z,
    required this.width,
    required this.depth,
    required num lowerHeight,
    required num upperHeight,
    required this.durationMs,
  }) : lowerHeight = lowerHeight.toDouble(),
       upperHeight = upperHeight.toDouble() {
    if ([
          id,
          instanceId,
        ].any((v) => !RegExp(r'^[a-zA-Z0-9_-]{1,128}$').hasMatch(v)) ||
        name.trim().isEmpty ||
        x < 0 ||
        z < 0 ||
        width < 1 ||
        depth < 1 ||
        width > 32 ||
        depth > 32 ||
        !this.lowerHeight.isFinite ||
        !this.upperHeight.isFinite ||
        this.lowerHeight < 0 ||
        this.upperHeight > 1024 ||
        this.upperHeight <= this.lowerHeight ||
        durationMs < 100 ||
        durationMs > 30000) {
      throw const FormatException('Invalid spatial lift definition.');
    }
  }
  final String id, name, instanceId;
  final int x, z, width, depth, durationMs;
  final double lowerHeight, upperHeight;
  double get travelHeight => upperHeight - lowerHeight;
  bool contains(double px, double pz) =>
      px >= x && pz >= z && px < x + width && pz < z + depth;
  bool fits(int mapWidth, int mapDepth) =>
      x + width <= mapWidth && z + depth <= mapDepth;
  factory SpatialLiftDefinition.fromJson(Map<String, dynamic> json) {
    const fields = {
      'id',
      'name',
      'instanceId',
      'x',
      'z',
      'width',
      'depth',
      'lowerHeight',
      'upperHeight',
      'durationMs',
    };
    if (json.keys.any((key) => !fields.contains(key)) ||
        fields.any((key) => !json.containsKey(key)) ||
        ['id', 'name', 'instanceId'].any((key) => json[key] is! String) ||
        [
          'x',
          'z',
          'width',
          'depth',
          'durationMs',
        ].any((key) => json[key] is! int) ||
        ['lowerHeight', 'upperHeight'].any((key) => json[key] is! num)) {
      throw const FormatException('Invalid spatial lift fields.');
    }
    return SpatialLiftDefinition(
      id: json['id'],
      name: json['name'],
      instanceId: json['instanceId'],
      x: json['x'],
      z: json['z'],
      width: json['width'],
      depth: json['depth'],
      lowerHeight: json['lowerHeight'],
      upperHeight: json['upperHeight'],
      durationMs: json['durationMs'],
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'instanceId': instanceId,
    'x': x,
    'z': z,
    'width': width,
    'depth': depth,
    'lowerHeight': lowerHeight,
    'upperHeight': upperHeight,
    'durationMs': durationMs,
  };
  @override
  bool operator ==(Object other) =>
      other is SpatialLiftDefinition &&
      id == other.id &&
      name == other.name &&
      instanceId == other.instanceId &&
      x == other.x &&
      z == other.z &&
      width == other.width &&
      depth == other.depth &&
      lowerHeight == other.lowerHeight &&
      upperHeight == other.upperHeight &&
      durationMs == other.durationMs;
  @override
  int get hashCode => Object.hash(
    id,
    name,
    instanceId,
    x,
    z,
    width,
    depth,
    lowerHeight,
    upperHeight,
    durationMs,
  );
}
