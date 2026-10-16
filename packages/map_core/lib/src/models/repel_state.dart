final class RepelState {
  const RepelState.empty()
    : remainingSteps = 0,
      itemId = '',
      expirationPending = false;

  const RepelState._(this.remainingSteps, this.itemId, this.expirationPending);

  factory RepelState.active({required String itemId, required int steps}) {
    if (itemId.trim().isEmpty || steps <= 0) {
      throw ArgumentError('Repel requires an item and positive steps');
    }
    return RepelState._(steps, itemId.trim(), false);
  }

  factory RepelState.fromJson(Map<String, dynamic> json) {
    final steps = json['remainingSteps'];
    final item = json['itemId'];
    final pending = json['expirationPending'];
    if (steps is! int ||
        steps < 0 ||
        item is! String ||
        pending is! bool ||
        item != item.trim() ||
        ((steps > 0 || pending) && item.isEmpty) ||
        (steps > 0 && pending) ||
        (steps == 0 && !pending && item.isNotEmpty)) {
      throw const FormatException('Invalid repel state');
    }
    return RepelState._(steps, item, pending);
  }

  final int remainingSteps;
  final String itemId;
  final bool expirationPending;

  bool get isActive => remainingSteps > 0;

  RepelState advance(int units) {
    if (units < 0) throw ArgumentError.value(units, 'units');
    if (!isActive || units == 0) return this;
    final remaining = remainingSteps > units ? remainingSteps - units : 0;
    return RepelState._(remaining, itemId, remaining == 0);
  }

  Map<String, dynamic> toJson() => {
    'remainingSteps': remainingSteps,
    'itemId': itemId,
    'expirationPending': expirationPending,
  };

  @override
  bool operator ==(Object other) =>
      other is RepelState &&
      remainingSteps == other.remainingSteps &&
      itemId == other.itemId &&
      expirationPending == other.expirationPending;

  @override
  int get hashCode => Object.hash(remainingSteps, itemId, expirationPending);
}
