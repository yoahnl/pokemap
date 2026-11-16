import 'package:flutter/widgets.dart';

final class EditorTextTransactions {
  EditorTextTransactions([this.changed]);

  final VoidCallback? changed;
  final _pending = <Future<void>>{};

  bool get pending => _pending.isNotEmpty;

  Future<void> track(Future<void> task) {
    late final Future<void> tracked;
    tracked = task.whenComplete(() {
      _pending.remove(tracked);
      changed?.call();
    });
    _pending.add(tracked);
    changed?.call();
    return tracked;
  }

  Future<void> finish() async {
    while (_pending.isNotEmpty) {
      await Future.wait(_pending.toList());
    }
  }
}

class EditorTextTransactionsScope extends InheritedWidget {
  const EditorTextTransactionsScope({
    super.key,
    required this.transactions,
    required super.child,
  });

  final EditorTextTransactions transactions;

  static EditorTextTransactions? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<EditorTextTransactionsScope>()
      ?.transactions;

  @override
  bool updateShouldNotify(EditorTextTransactionsScope oldWidget) =>
      !identical(oldWidget.transactions, transactions);
}
