import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_workspace.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';

void main() {
  testWidgets('Surface Studio exposes a first-level TSX workspace',
      (tester) async {
    await tester.pumpWidget(
      _wrapPanel(
        SurfaceStudioPanel(
          readModel: buildSurfaceStudioReadModelFromCatalog(
            ProjectSurfaceCatalog(),
          ),
          projectTilesets: const [],
          tsxFileLoader: const _NoopTsxFileLoader(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('surface_studio.primary_tabs')), findsOne);
    expect(find.text('Catalogue Surface'), findsOneWidget);
    expect(find.text('TSX'), findsOneWidget);
    expect(find.text('Diagnostics'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('surface_studio.tab.tsx')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('surface_studio.tsx_workspace')), findsOne);
    expect(find.text('Aucune animation TSX importée.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('tiled_tsx_workspace.empty_import')),
      findsOneWidget,
    );
    expect(find.text('Détails avancés'), findsNothing);
  });

  testWidgets('Diagnostics remain available as their own top-level workspace',
      (tester) async {
    await tester.pumpWidget(
      _wrapPanel(
        SurfaceStudioPanel(
          readModel: buildSurfaceStudioReadModelFromCatalog(
            ProjectSurfaceCatalog(),
          ),
          projectTilesets: const [],
          tsxFileLoader: const _NoopTsxFileLoader(),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('surface_studio.tab.diagnostics')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('surface_studio.diagnostics_workspace')),
      findsOne,
    );
    expect(find.text('Détails avancés'), findsOneWidget);
  });
}

Widget _wrapPanel(Widget child) {
  return MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(size: Size(2048, 1120)),
      child: CupertinoPageScaffold(
        child: SizedBox(
          width: 2048,
          height: 1120,
          child: child,
        ),
      ),
    ),
  );
}

final class _NoopTsxFileLoader implements TiledTsxFileLoader {
  const _NoopTsxFileLoader();

  @override
  Future<TiledTsxLoadedFile?> pickAndLoadTsx() async => null;
}
