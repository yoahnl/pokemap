part of 'transport_certification_scenario.dart';

final class AuthoringTransportArtifact {
  const AuthoringTransportArtifact._(
      this.path, this.mediaType, this.parameterPath);

  factory AuthoringTransportArtifact.fromJson(
    Map<String, Object?> json, {
    bool explicitParameterPath = false,
  }) {
    transportEvidenceFields(json, {
      'path',
      'mediaType',
      if (explicitParameterPath) 'parameterPath',
    });
    final path = transportEvidencePath(json['path']);
    final mediaType = json['mediaType'];
    final parameterPath = explicitParameterPath
        ? transportEvidenceList(json['parameterPath'], 'parameter path')
        : const <Object?>['artifactHandle'];
    if (path.split('/').first == '.pokemap' ||
        mediaType is! String ||
        !RegExp(r'^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$')
            .hasMatch(mediaType) ||
        parameterPath.last is! String ||
        parameterPath.any((value) => switch (value) {
              String key => key.isEmpty,
              int index => index < 0,
              _ => true,
            })) {
      throw FormatException('Invalid staged artifact input: $path.');
    }
    return AuthoringTransportArtifact._(
      path,
      mediaType,
      List.unmodifiable(parameterPath),
    );
  }

  final String path;
  final String mediaType;
  final List<Object?> parameterPath;

  Map<String, Object?> _slot(Map<String, Object?> parameters) {
    Object? owner = parameters;
    for (final key in parameterPath.take(parameterPath.length - 1)) {
      if (owner is Map && key is String && owner.containsKey(key)) {
        owner = owner[key];
      } else if (owner is List && key is int && key < owner.length) {
        owner = owner[key];
      } else {
        throw FormatException(
            'Missing artifact parameter parent: $parameterPath.');
      }
    }
    if (owner is! Map<String, Object?> ||
        owner.containsKey(parameterPath.last)) {
      throw FormatException(
          'Expected an empty artifact parameter slot: $parameterPath.');
    }
    return owner;
  }
}

List<AuthoringTransportArtifact> _parseArtifactBindings(
  Map<String, Object?> json,
  Map<String, Object?> parameters,
) {
  final explicit = json.containsKey('artifacts');
  final single = json.containsKey('artifact');
  if (explicit && single) {
    throw const FormatException('Specify artifact or artifacts.');
  }
  final rawInputs = explicit
      ? transportEvidenceList(json['artifacts'], 'staged artifacts')
      : [if (single) json['artifact']];
  final usedPaths = <String>{};
  return List.unmodifiable(rawInputs.map((raw) {
    final artifact = AuthoringTransportArtifact.fromJson(
      transportEvidenceObject(raw, 'staged artifact input'),
      explicitParameterPath: explicit,
    );
    if (!usedPaths.add(canonicalAuthoringJson(artifact.parameterPath))) {
      throw FormatException(
          'Duplicate artifact parameter: ${artifact.parameterPath}.');
    }
    artifact._slot(parameters);
    return artifact;
  }));
}
