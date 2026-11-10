import 'dart:async';

import 'package:map_core/map_core.dart';

import '../domain/resource_port.dart';

class ModelCollisionDraft {
  ModelCollisionDraft(ProjectModel3dEntry model)
    : custom = model.collisionBounds != null,
      blocksMovementByDefault = model.blocksMovementByDefault {
    final bounds = model.collisionBounds ?? model.inspection.bounds;
    values = [
      bounds.min.x,
      bounds.min.y,
      bounds.min.z,
      bounds.max.x,
      bounds.max.y,
      bounds.max.z,
    ].map((value) => '$value').toList();
  }

  bool custom, blocksMovementByDefault;
  late List<String> values;
  bool saving = false, _closed = false;
  String? error;

  Model3dBounds? build() {
    if (!custom) return null;
    final parsed = values
        .map((value) => double.tryParse(value.replaceAll(',', '.')))
        .toList();
    if (parsed.any((value) => value == null || !value.isFinite)) {
      throw const ResourceFailure(
        'Saisissez six nombres valides pour le volume.',
      );
    }
    final numbers = parsed.cast<double>();
    if ([0, 1, 2].any((axis) => numbers[axis] >= numbers[axis + 3])) {
      throw const ResourceFailure(
        'Chaque maximum doit être supérieur au minimum correspondant.',
      );
    }
    return Model3dBounds(
      min: Model3dVector3(x: numbers[0], y: numbers[1], z: numbers[2]),
      max: Model3dVector3(x: numbers[3], y: numbers[4], z: numbers[5]),
    );
  }

  Future<bool> save(
    Future<void> Function(Model3dBounds?, bool) publish, {
    required bool Function() canSave,
  }) async {
    if (_closed || saving || !canSave()) return false;
    saving = true;
    error = null;
    try {
      await publish(build(), blocksMovementByDefault);
      return !_closed;
    } on Object catch (failure) {
      if (!_closed) error = '$failure';
      return false;
    } finally {
      saving = false;
    }
  }

  void dispose() => _closed = true;
}

class ModelRampDraft {
  ModelRampDraft(ProjectModel3dEntry model) {
    final profile = model.rampProfile;
    final bounds = model.inspection.bounds;
    enabled = profile != null;
    direction = profile?.direction ?? SpatialRampDirection.north;
    values = [
      profile?.x ?? bounds.min.x,
      profile?.z ?? bounds.min.z,
      profile?.width ?? bounds.size.x,
      profile?.depth ?? bounds.size.z,
      profile?.lowHeight ?? bounds.min.y,
      profile?.highHeight ?? bounds.max.y,
    ].map((value) => '$value').toList();
  }

  late bool enabled;
  late SpatialRampDirection direction;
  late List<String> values;
  bool saving = false, _closed = false;
  String? error;

  Model3dRampProfile? build() {
    if (!enabled) return null;
    final parsed = values
        .map((value) => double.tryParse(value.replaceAll(',', '.')))
        .toList();
    if (parsed.any((value) => value == null || !value.isFinite)) {
      throw const FormatException('Saisissez des dimensions valides.');
    }
    final n = parsed.cast<double>();
    return Model3dRampProfile(
      x: n[0],
      z: n[1],
      width: n[2],
      depth: n[3],
      lowHeight: n[4],
      highHeight: n[5],
      direction: direction,
    );
  }

  Future<bool> save(
    Future<void> Function(Model3dRampProfile?) publish, {
    required bool Function() canSave,
  }) async {
    if (_closed || saving || !canSave()) return false;
    saving = true;
    error = null;
    try {
      await publish(build());
      return !_closed;
    } on Object catch (failure) {
      if (!_closed) error = 'Impossible d’appliquer cet escalier : $failure';
      return false;
    } finally {
      saving = false;
    }
  }

  void dispose() => _closed = true;
}

class ModelShadowDraft {
  ModelShadowDraft(ProjectModel3dEntry model)
    : _model = model,
      value = model.castsShadowsByDefault;

  ProjectModel3dEntry _model;
  bool value, saving = false, _closed = false;
  String? error;
  int _request = 0;

  void update(ProjectModel3dEntry model) {
    if (_model.id != model.id ||
        _model.castsShadowsByDefault != model.castsShadowsByDefault) {
      _request++;
      saving = false;
      value = model.castsShadowsByDefault;
      error = null;
    }
    _model = model;
  }

  Future<bool> save(
    bool next,
    FutureOr<void> Function(bool) publish, {
    required bool Function() canSave,
  }) async {
    if (_closed || saving || !canSave()) return false;
    final request = ++_request;
    final confirmed = value;
    value = next;
    saving = true;
    error = null;
    try {
      await publish(next);
      if (_closed || request != _request) return false;
      value = next;
      return true;
    } on Object catch (failure) {
      if (!_closed && request == _request) {
        value = confirmed;
        error = '$failure';
      }
      return false;
    } finally {
      if (request == _request) saving = false;
    }
  }

  void dispose() {
    _closed = true;
    _request++;
  }
}
