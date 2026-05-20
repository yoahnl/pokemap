import 'dart:mirrors';
import 'package:map_battle/src/domain/move/behaviors/copy_call_move_behavior.dart';

void main() {
  final lib = currentMirrorSystem().libraries.values.firstWhere(
    (l) => l.uri.path.endsWith('copy_call_move_behavior.dart'),
  );
  final sym = const Symbol('_metronomeExcludedMoveIds');
  final decl = lib.declarations[sym];
  print('decl=${decl.runtimeType}');
  if (decl is VariableMirror) {
    print('owner=${decl.owner!.simpleName}');
    print('isConst=${decl.isConst}');
    final v = (decl as VariableMirror).owner;
    print('value getter?');
  }
  // Try to access through instance of library with mangled symbol object from mirror name.
  try {
    final mirror = lib.getField(sym);
    print('via getField: ${mirror.reflectee}');
  } catch (e) {
    print('getField failed: $e');
  }
}
