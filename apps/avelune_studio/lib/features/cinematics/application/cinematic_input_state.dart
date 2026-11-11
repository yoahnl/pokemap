enum CinematicFieldCommitResult { skipped, accepted, rejected }

class CinematicInputState {
  final _fields = <String, CinematicFieldInput>{};
  final _error = _CinematicInputDiagnostic();
  final _actionError = _CinematicInputDiagnostic();
  final _spatialError = _CinematicInputDiagnostic();
  final _inspectorError = _CinematicInputDiagnostic();
  CinematicFieldInput? _validatingField;
  int revision = 0;

  bool get validating => _validatingField != null;
  String? get actionError => _actionError.message;
  set actionError(String? value) => _setDiagnostic(_actionError, value);
  String? get spatialError => _spatialError.message;
  set spatialError(String? value) => _setDiagnostic(_spatialError, value);
  String? get inspectorError => _inspectorError.message;
  set inspectorError(String? value) => _setDiagnostic(_inspectorError, value);

  String? get error {
    if (_error.message != null) return _error.message;
    for (final field in _fields.values) {
      if (field.problem != null) return field.problem;
    }
    return null;
  }

  set error(String? value) => _setDiagnostic(_error, value);

  void _setDiagnostic(_CinematicInputDiagnostic diagnostic, String? value) {
    final owner = value == null ? null : _validatingField;
    if (diagnostic.message == value && identical(diagnostic.field, owner)) {
      return;
    }
    diagnostic.message = value;
    diagnostic.field = owner;
    revision++;
  }

  bool validateField(CinematicFieldInput field, bool Function() validate) {
    final previous = _validatingField;
    _validatingField = field;
    try {
      return validate();
    } finally {
      _validatingField = previous;
    }
  }

  CinematicFieldCommitResult commitField(
    CinematicFieldInput field, {
    required bool Function(String) tryCommit,
    required String fallbackError,
    bool alwaysCommit = false,
  }) {
    if (!identical(field._owner, this)) {
      throw ArgumentError('Ce champ appartient à une autre cinématique.');
    }
    if (!field.pending && field.problem == null && !alwaysCommit) {
      return CinematicFieldCommitResult.skipped;
    }
    final accepted = validateField(field, () => tryCommit(field.text));
    if (accepted) {
      field.accept();
      return CinematicFieldCommitResult.accepted;
    }
    field.reject(error ?? fallbackError);
    return CinematicFieldCommitResult.rejected;
  }

  bool get valid =>
      error == null && !_fields.values.any((field) => field.pending);
  bool get dirty => !valid;

  CinematicFieldInput field(String id, String value) {
    final input = _fields.putIfAbsent(
      id,
      () => CinematicFieldInput._owned(value, () => revision++, this),
    );
    input.synchronize(value);
    return input;
  }

  void discard({bool preserveDiagnostics = false}) {
    for (final field in _fields.values) {
      field._discard();
    }
    for (final diagnostic in [
      _error,
      _actionError,
      _spatialError,
      _inspectorError,
    ]) {
      if (!preserveDiagnostics || diagnostic.field != null) {
        diagnostic.message = null;
        diagnostic.field = null;
      }
    }
    revision++;
  }
}

class _CinematicInputDiagnostic {
  String? message;
  CinematicFieldInput? field;
}

class CinematicFieldInput {
  CinematicFieldInput(String text, void Function() changed)
    : this._owned(text, changed, null);

  CinematicFieldInput._owned(this.text, this._changed, this._owner)
    : _value = text;

  final void Function() _changed;
  final CinematicInputState? _owner;
  String _value;
  String text;
  bool pending = false;
  String? problem;

  void synchronize(String value) {
    _value = value;
    if (!pending && problem == null && text != value) {
      text = value;
    }
  }

  void _discard() {
    text = _value;
    pending = false;
    problem = null;
  }

  void edit(String value) {
    text = value;
    pending = true;
    _changed();
  }

  void accept() {
    pending = false;
    problem = null;
    _changed();
  }

  void reject(String message) {
    pending = false;
    problem = message;
    _changed();
  }
}
