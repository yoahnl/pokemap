import 'package:path/path.dart' as p;

enum MapRenderView { game, top, orbit }

final class RenderRequestException implements Exception {
  const RenderRequestException(this.message);

  final String message;

  @override
  String toString() => 'RenderRequestException: $message';
}

final class RenderRequest {
  const RenderRequest({
    required this.projectRoot,
    required this.mapId,
    required this.outputPath,
    this.centerX,
    this.centerZ,
    this.magnification = 2,
    this.view = MapRenderView.game,
    this.minuteOfDay = 720,
  });

  factory RenderRequest.fromJson(Map<String, Object?> json) {
    const allowed = {
      'projectRoot',
      'mapId',
      'outputPath',
      'center',
      'magnification',
      'view',
      'minuteOfDay',
    };
    final unknown = json.keys.where((key) => !allowed.contains(key)).toList();
    if (unknown.isNotEmpty) {
      throw RenderRequestException('Unknown render fields: ${unknown.join(', ')}.');
    }
    final projectRoot = _absolutePath(json['projectRoot'], 'projectRoot');
    final outputPath = _absolutePath(json['outputPath'], 'outputPath');
    if (p.extension(outputPath) != '.png') {
      throw const RenderRequestException('outputPath must name a .png file.');
    }
    final mapId = json['mapId'];
    if (mapId is! String || mapId.isEmpty) {
      throw const RenderRequestException('mapId must be a non-empty string.');
    }
    final center = json['center'];
    double? centerX, centerZ;
    if (center != null) {
      if (center is! Map ||
          center.length != 2 ||
          center['x'] is! num ||
          center['z'] is! num) {
        throw const RenderRequestException('center must be {x, z}.');
      }
      centerX = (center['x'] as num).toDouble();
      centerZ = (center['z'] as num).toDouble();
      if (!centerX.isFinite || !centerZ.isFinite) {
        throw const RenderRequestException('center must be finite.');
      }
    }
    final magnification = _number(json['magnification'], 'magnification', 2);
    if (magnification < .5 || magnification > 8) {
      throw const RenderRequestException('magnification must be within 0.5 to 8.');
    }
    final minuteOfDay = _number(json['minuteOfDay'], 'minuteOfDay', 720);
    if (minuteOfDay < 0 || minuteOfDay >= 1440) {
      throw const RenderRequestException('minuteOfDay must be within 0 to 1439.');
    }
    final rawView = json['view'] ?? 'game';
    final view = MapRenderView.values.where((value) => value.name == rawView).firstOrNull;
    if (view == null) {
      throw const RenderRequestException('view must be game, top or orbit.');
    }
    return RenderRequest(
      projectRoot: projectRoot,
      mapId: mapId,
      outputPath: outputPath,
      centerX: centerX,
      centerZ: centerZ,
      magnification: magnification,
      view: view,
      minuteOfDay: minuteOfDay,
    );
  }

  final String projectRoot;
  final String mapId;
  final String outputPath;
  final double? centerX;
  final double? centerZ;
  final double magnification;
  final MapRenderView view;
  final double minuteOfDay;

  String projectFile(String relativePath) {
    final resolved = p.normalize(p.join(projectRoot, relativePath));
    if (!p.isWithin(projectRoot, resolved)) {
      throw RenderRequestException('Project file escapes the project root: $relativePath');
    }
    return resolved;
  }
}

String _absolutePath(Object? value, String field) {
  if (value is! String || value.isEmpty || !p.isAbsolute(value)) {
    throw RenderRequestException('$field must be an absolute path.');
  }
  return p.normalize(value);
}

double _number(Object? value, String field, double fallback) {
  if (value == null) return fallback;
  if (value is! num || !value.isFinite) {
    throw RenderRequestException('$field must be a finite number.');
  }
  return value.toDouble();
}

final class ScanRequest {
  const ScanRequest({
    required this.projectRoot,
    required this.mapId,
    required this.outputDirectory,
    this.maxViews = 12,
    this.magnification = 4,
  });

  factory ScanRequest.fromJson(Map<String, Object?> json) {
    const allowed = {'projectRoot', 'mapId', 'outputDirectory', 'maxViews', 'magnification'};
    final unknown = json.keys.where((key) => !allowed.contains(key)).toList();
    if (unknown.isNotEmpty) {
      throw RenderRequestException('Unknown scan fields: ${unknown.join(', ')}.');
    }
    final mapId = json['mapId'];
    if (mapId is! String || mapId.isEmpty) {
      throw const RenderRequestException('mapId must be a non-empty string.');
    }
    final maxViews = json['maxViews'] ?? 12;
    if (maxViews is! int || maxViews < 1 || maxViews > 32) {
      throw const RenderRequestException('maxViews must be an integer within 1 to 32.');
    }
    final magnification = _number(json['magnification'], 'magnification', 4);
    if (magnification < 2 || magnification > 8) {
      throw const RenderRequestException('magnification must be within 2 to 8.');
    }
    return ScanRequest(
      projectRoot: _absolutePath(json['projectRoot'], 'projectRoot'),
      mapId: mapId,
      outputDirectory: _absolutePath(json['outputDirectory'], 'outputDirectory'),
      maxViews: maxViews,
      magnification: magnification,
    );
  }

  final String projectRoot;
  final String mapId;
  final String outputDirectory;
  final int maxViews;
  final double magnification;

  String projectFile(String relativePath) {
    final resolved = p.normalize(p.join(projectRoot, relativePath));
    if (!p.isWithin(projectRoot, resolved)) {
      throw RenderRequestException('Project file escapes the project root: $relativePath');
    }
    return resolved;
  }
}
