class ScenePokemonGiftMovesDraft {
  ScenePokemonGiftMovesDraft({
    required this.value,
    required this.changed,
    required this.onChanged,
    required this.onValidityChanged,
    this.loadMoves,
    this.catalogueScope,
  }) {
    if (value != null) load();
  }
  List<String>? value;
  Object? catalogueScope;
  Future<Map<String, String>> Function()? loadMoves;
  final void Function() changed;
  final void Function(List<String>?) onChanged;
  final void Function(bool) onValidityChanged;
  bool _disposed = false;
  void _update(void Function() update) {
    if (_disposed) return;
    update();
    changed();
  }

  void configure({
    required List<String>? value,
    required Object? catalogueScope,
    required Future<Map<String, String>> Function()? loadMoves,
  }) {
    final reload =
        this.loadMoves != loadMoves ||
        this.catalogueScope != catalogueScope ||
        this.value == null && value != null;
    final same =
        identical(this.value, value) ||
        this.value != null &&
            value != null &&
            this.value!.length == value.length &&
            Iterable<int>.generate(value.length)
                .every((i) => this.value![i] == value[i]);
    this.value = value;
    this.catalogueScope = catalogueScope;
    this.loadMoves = loadMoves;
    if (reload) {
      load();
    } else if (!same) {
      Future<void>.microtask(() {
        if (!_disposed) onValidityChanged(valid);
      });
    }
  }

  void dispose() {
    _disposed = true;
    _request++;
  }

  Map<String, String> moves = const {};
  bool loading = false;
  String? error;
  int _request = 0;
  bool get valid => validValue(value);
  bool validValue(List<String>? value) =>
      value == null ||
      !loading &&
          error == null &&
          value.isNotEmpty &&
          value.length <= 4 &&
          value.toSet().length == value.length &&
          value.every(moves.containsKey);
  Future<void> load() async {
    final token = ++_request;
    loading = true;
    error = null;
    await Future<void>.value();
    if (_disposed || token != _request) return;
    onValidityChanged(value == null);
    try {
      final load = loadMoves;
      if (load == null) throw StateError('Unavailable');
      final moves = await load();
      if (_disposed || token != _request) return;
      _update(() => this.moves = moves);
    } on Object {
      if (_disposed || token != _request) return;
      _update(
        () => error = 'Catalogue des capacités indisponible. Les références enregistrées sont conservées.',
      );
    } finally {
      if (!_disposed && token == _request) {
        _update(() => loading = false);
        onValidityChanged(valid);
      }
    }
  }

  void change(List<String>? value) {
    onChanged(value == null ? null : List.unmodifiable(value));
    onValidityChanged(validValue(value));
  }

  void swap(int index, int target) {
    final value = [...this.value!];
    final move = value[index];
    value[index] = value[target];
    value[target] = move;
    change(value);
  }
}
