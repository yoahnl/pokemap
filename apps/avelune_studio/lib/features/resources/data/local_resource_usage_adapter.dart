import 'package:map_authoring/map_authoring_local.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/resource_usage_port.dart';

final class LocalResourceUsageAdapter implements ResourceUsagePort {
  LocalResourceUsageAdapter({
    required this.session,
    ProjectFileReader? reader,
    ProjectSnapshotLoadProfileSink? profileSink,
  }) : _reader = reader ?? const LocalProjectFileReader(),
       _profileSink = profileSink;

  final ProjectSession session;
  final ProjectFileReader _reader;
  final ProjectSnapshotLoadProfileSink? _profileSink;
  final _handles = WorkspaceHandleStore();
  OpenedProject? _opened;
  ProjectSnapshotLoader? _loader;
  Future<void>? _initializing;
  bool _disposed = false;

  Future<void> _initialize() async {
    final pending = _initializing ??= _open();
    try {
      await pending;
    } on Object {
      _initializing = null;
      rethrow;
    }
  }

  Future<void> _open() async {
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: _reader,
    );
    _check();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: _reader,
      handles: _handles,
    ).openProject(session.directoryPath);
    if (_disposed) {
      _handles.closeWorkspace(opened.workspaceHandle);
      throw const ResourceUsageCancelled();
    }
    _opened = opened;
    _loader = ProjectSnapshotLoader(
      handles: _handles,
      snapshotCache: ProjectSnapshotCache(),
      profileSink: _profileSink,
    );
  }

  void _check([bool Function()? cancelled]) {
    if (_disposed || cancelled?.call() == true) {
      throw const ResourceUsageCancelled();
    }
  }

  Future<ProjectSnapshot> _snapshot([bool Function()? cancelled]) async {
    _check(cancelled);
    await _initialize();
    _check(cancelled);
    late final ProjectSnapshot result;
    try {
      result = await _loader!.load(
        _opened!.projectHandle,
        policy: ProjectSnapshotLoadPolicy.resourceUsageReadProjection,
      );
    } on Object {
      _check(cancelled);
      rethrow;
    }
    _check(cancelled);
    return result;
  }

  @override
  Future<ResourceUsageReport> analyze(
    ResourceUsageTarget target, {
    bool Function()? cancelled,
  }) async {
    final snapshot = await _snapshot(cancelled);
    final report = const ResourceUsageProjection().analyze(snapshot, target);
    _check(cancelled);
    return report;
  }

  @override
  Future<bool> isCurrent(ResourceUsageReport report) async {
    if (_disposed) return false;
    try {
      final snapshot = await _snapshot();
      if (report.revision != snapshot.revision ||
          report.fingerprints.length != snapshot.resourceFingerprints.length) {
        return false;
      }
      return report.fingerprints.entries.every(
        (entry) => snapshot.resourceFingerprints[entry.key] == entry.value,
      );
    } on Object {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    if (_opened != null) _handles.closeWorkspace(_opened!.workspaceHandle);
  }
}
