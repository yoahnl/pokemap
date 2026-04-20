sealed class TrainerFieldUpdate<T> {
  const TrainerFieldUpdate();

  const factory TrainerFieldUpdate.keep() = _KeepTrainerFieldUpdate<T>;
  const factory TrainerFieldUpdate.set(T? value) = _SetTrainerFieldUpdate<T>;

  bool get isKeep;
  T? get valueOrNull;
}

final class _KeepTrainerFieldUpdate<T> extends TrainerFieldUpdate<T> {
  const _KeepTrainerFieldUpdate();

  @override
  bool get isKeep => true;

  @override
  T? get valueOrNull => null;
}

final class _SetTrainerFieldUpdate<T> extends TrainerFieldUpdate<T> {
  const _SetTrainerFieldUpdate(this.value);

  final T? value;

  @override
  bool get isKeep => false;

  @override
  T? get valueOrNull => value;
}
