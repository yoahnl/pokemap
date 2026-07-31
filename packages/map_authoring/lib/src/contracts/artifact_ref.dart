import 'json_contract_support.dart';
import '../support/authoring_fingerprint.dart';

/// Path-free identity for bytes staged before a project mutation is planned.
///
/// The digest is the authority. File names and source paths are deliberately
/// absent so API and future MCP clients cannot turn an artifact handle into an
/// ambient filesystem capability.
final class ContentArtifactRef {
  ContentArtifactRef({
    required String digest,
    required String mediaType,
    required int byteLength,
  })  : digest = _digest(digest),
        mediaType = _mediaType(mediaType),
        byteLength = _byteLength(byteLength),
        handle = _handleForDigest(_digest(digest));

  factory ContentArtifactRef.fromBytes(
    List<int> bytes, {
    required String mediaType,
  }) {
    _validateBytes(bytes);
    return ContentArtifactRef(
      // The authoring fingerprint uses SHA-256 with a stable domain frame. It
      // remains content-addressed while avoiding a second crypto dependency.
      digest: computeAuthoringBytesFingerprint(
        bytes,
        logicalName: 'artifact-content',
      ),
      mediaType: mediaType,
      byteLength: bytes.length,
    );
  }

  factory ContentArtifactRef.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(
      json,
      const {'digest', 'handle', 'mediaType', 'byteLength'},
    );
    final rawLength = json['byteLength'];
    if (rawLength is! int) {
      throw const FormatException('byteLength must be an integer');
    }
    try {
      final reference = ContentArtifactRef(
        digest: requireContractString(json['digest'], 'digest'),
        mediaType: requireContractString(json['mediaType'], 'mediaType'),
        byteLength: rawLength,
      );
      if (json['handle'] != reference.handle) {
        throw const FormatException('handle must match digest');
      }
      return reference;
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String digest;
  final String handle;
  final String mediaType;
  final int byteLength;

  String get hexDigest => digest.substring('sha256:'.length);

  Map<String, Object?> toJson() => {
        'digest': digest,
        'handle': handle,
        'mediaType': mediaType,
        'byteLength': byteLength,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentArtifactRef &&
          other.digest == digest &&
          other.mediaType == mediaType &&
          other.byteLength == byteLength;

  @override
  int get hashCode => Object.hash(digest, mediaType, byteLength);
}

String _digest(String value) {
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      'digest',
      'must be a lowercase SHA-256 digest',
    );
  }
  return value;
}

String _mediaType(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized != value ||
      !RegExp(r'^[a-z0-9][a-z0-9!#$&^_.+-]*/[a-z0-9][a-z0-9!#$&^_.+-]*$')
          .hasMatch(normalized)) {
    throw ArgumentError.value(value, 'mediaType', 'must be a stable MIME type');
  }
  return normalized;
}

int _byteLength(int value) {
  if (value < 0) {
    throw ArgumentError.value(value, 'byteLength', 'must not be negative');
  }
  return value;
}

String _handleForDigest(String digest) =>
    'artifact://sha256/${digest.substring('sha256:'.length)}';

void _validateBytes(List<int> bytes) {
  if (bytes.any((byte) => byte < 0 || byte > 255)) {
    throw ArgumentError.value(bytes, 'bytes', 'must contain bytes');
  }
}
