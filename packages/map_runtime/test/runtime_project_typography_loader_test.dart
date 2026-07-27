import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('registers each installed role and isolates corrupt font failures',
      () async {
    final root = await Directory.systemTemp.createTemp('runtime-fonts-');
    addTearDown(() => root.delete(recursive: true));
    final display =
        await File('${root.path}/display.ttf').writeAsBytes(<int>[0, 1, 0, 0]);
    final dialogue =
        await File('${root.path}/dialogue.ttf').writeAsBytes(<int>[0, 1, 0, 0]);
    final registrar = _Registrar(failingFamily: 'Aube Dialogue');

    final loaded = await RuntimeProjectTypographyLoader(
      registrar: registrar,
    ).load(
      <ProjectTypographyRole, RuntimeProjectFontRequest>{
        ProjectTypographyRole.display: RuntimeProjectFontRequest(
          file: display,
          family: 'Aube Display',
          fallbackFamilies: const <String>['sans-serif'],
        ),
        ProjectTypographyRole.dialogue: RuntimeProjectFontRequest(
          file: dialogue,
          family: 'Aube Dialogue',
          fallbackFamilies: const <String>['serif'],
        ),
        ProjectTypographyRole.numbers: const RuntimeProjectFontRequest(
          file: null,
          family: null,
          fallbackFamilies: <String>['monospace'],
        ),
      },
    );

    expect(
      loaded.roles[ProjectTypographyRole.display]?.registeredFamily,
      'Aube Display',
    );
    expect(
      loaded.roles[ProjectTypographyRole.dialogue]?.registeredFamily,
      isNull,
    );
    expect(
      loaded.roles[ProjectTypographyRole.dialogue]?.fallbackFamilies,
      <String>['serif'],
    );
    expect(
      loaded.unavailableRoles,
      <ProjectTypographyRole>[ProjectTypographyRole.dialogue],
    );
  });
}

final class _Registrar implements RuntimeFontRegistrar {
  _Registrar({required this.failingFamily});

  final String failingFamily;

  @override
  Future<void> register(String family, Uint8List bytes) async {
    if (family == failingFamily) throw StateError('corrupt');
  }
}
