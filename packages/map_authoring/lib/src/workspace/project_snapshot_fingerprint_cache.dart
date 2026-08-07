import '../ports/project_file_reader.dart';

/// Remembers fingerprints already computed for unchanged resources.
///
/// Hashing dominates a snapshot: the same bytes are walked once for the global
/// revision and once per resource. When a file's identity is unchanged its
/// bytes are unchanged, so both results can be reused.
///
/// Identity is `(scope, path, byteLength, modifiedAt)` with microsecond
/// resolution — the same basis every build system uses. A rewrite that keeps
/// the byte length *and* lands in the same microsecond would go unnoticed;
/// everything coarser is caught. The double-read consistency check is
/// untouched and still rejects a snapshot that observed a mid-load change.
final class ProjectSnapshotFingerprintCache {
  ProjectSnapshotFingerprintCache({this.maximumEntries = 512})
      : assert(maximumEntries > 0);

  final int maximumEntries;
  final Map<ProjectResourceIdentity, String> _resourceFingerprints = {};
  final Map<String, String> _revisions = {};
  final Map<ProjectResourceIdentity, Object> _decoded = {};

  int hits = 0;
  int misses = 0;

  String? resourceFingerprint(ProjectResourceIdentity identity) {
    final found = _resourceFingerprints[identity];
    if (found == null) {
      misses += 1;
    } else {
      hits += 1;
    }
    return found;
  }

  void storeResourceFingerprint(
    ProjectResourceIdentity identity,
    String fingerprint,
  ) {
    if (_resourceFingerprints.length >= maximumEntries) {
      _resourceFingerprints.remove(_resourceFingerprints.keys.first);
    }
    _resourceFingerprints[identity] = fingerprint;
  }

  /// The revision covers every resource in order, so it is keyed by the whole
  /// ordered identity list: one changed file and the key no longer matches.
  String? revision(String identityKey) => _revisions[identityKey];

  void storeRevision(String identityKey, String revision) {
    if (_revisions.length >= maximumEntries) {
      _revisions.remove(_revisions.keys.first);
    }
    _revisions[identityKey] = revision;
  }

  /// Decoded models are pure functions of the bytes and are immutable, so an
  /// unchanged resource can hand back the very same instance.
  T? decoded<T extends Object>(ProjectResourceIdentity identity) {
    final found = _decoded[identity];
    if (found is T) {
      hits += 1;
      return found;
    }
    misses += 1;
    return null;
  }

  void storeDecoded(ProjectResourceIdentity identity, Object model) {
    if (_decoded.length >= maximumEntries) {
      _decoded.remove(_decoded.keys.first);
    }
    _decoded[identity] = model;
  }

  void clear() {
    _resourceFingerprints.clear();
    _revisions.clear();
    _decoded.clear();
  }
}
