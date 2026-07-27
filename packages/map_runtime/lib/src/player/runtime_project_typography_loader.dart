import 'dart:io';

import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

final class RuntimeProjectFontRequest {
  const RuntimeProjectFontRequest({
    required this.file,
    required this.family,
    required this.fallbackFamilies,
  });

  final File? file;
  final String? family;
  final List<String> fallbackFamilies;
}

final class RuntimeLoadedFontRole {
  RuntimeLoadedFontRole({
    required this.registeredFamily,
    required List<String> fallbackFamilies,
  }) : fallbackFamilies = List<String>.unmodifiable(fallbackFamilies);

  final String? registeredFamily;
  final List<String> fallbackFamilies;
}

final class RuntimeLoadedTypography {
  RuntimeLoadedTypography({
    required Map<ProjectTypographyRole, RuntimeLoadedFontRole> roles,
    required List<ProjectTypographyRole> unavailableRoles,
  })  : roles = Map<ProjectTypographyRole, RuntimeLoadedFontRole>.unmodifiable(
          roles,
        ),
        unavailableRoles =
            List<ProjectTypographyRole>.unmodifiable(unavailableRoles);

  final Map<ProjectTypographyRole, RuntimeLoadedFontRole> roles;
  final List<ProjectTypographyRole> unavailableRoles;
}

abstract interface class RuntimeFontRegistrar {
  Future<void> register(String family, Uint8List bytes);
}

final class FlutterRuntimeFontRegistrar implements RuntimeFontRegistrar {
  const FlutterRuntimeFontRegistrar();

  @override
  Future<void> register(String family, Uint8List bytes) async {
    final loader = FontLoader(family)
      ..addFont(
        Future<ByteData>.value(ByteData.sublistView(bytes)),
      );
    await loader.load();
  }
}

/// Registers packaged fonts independently so one corrupt role cannot block boot.
final class RuntimeProjectTypographyLoader {
  const RuntimeProjectTypographyLoader({
    this.registrar = const FlutterRuntimeFontRegistrar(),
  });

  final RuntimeFontRegistrar registrar;

  Future<RuntimeLoadedTypography> load(
    Map<ProjectTypographyRole, RuntimeProjectFontRequest> requests,
  ) async {
    final roles = <ProjectTypographyRole, RuntimeLoadedFontRole>{};
    final unavailable = <ProjectTypographyRole>[];
    for (final entry in requests.entries) {
      final request = entry.value;
      String? registeredFamily;
      final file = request.file;
      final family = request.family?.trim();
      if (file != null && family != null && family.isNotEmpty) {
        try {
          if (await FileSystemEntity.type(file.path, followLinks: false) !=
              FileSystemEntityType.file) {
            throw const FileSystemException('Font asset is unavailable.');
          }
          await registrar.register(family, await file.readAsBytes());
          registeredFamily = family;
        } on Object {
          unavailable.add(entry.key);
        }
      }
      roles[entry.key] = RuntimeLoadedFontRole(
        registeredFamily: registeredFamily,
        fallbackFamilies: request.fallbackFamilies,
      );
    }
    return RuntimeLoadedTypography(
      roles: roles,
      unavailableRoles: unavailable,
    );
  }
}
