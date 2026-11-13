import 'package:avelune_studio/main.dart' as entry;
import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/platform/mcp/studio_mcp_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {

  testWidgets(
    'the declared bundle catalogue reaches the creation port through composition',
    (tester) async {
      final catalog = (await tester.runAsync(
        entry.loadStudioProjectTemplateCatalog,
      ))!;
      expect(catalog.templates, isEmpty);
      await tester.pumpWidget(
        StudioBootstrap(
          templateCatalog: catalog,
          mcpService: StudioMcpService(
            launch: () async => throw StateError('fixture.unavailable'),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(StudioApp)),
        listen: false,
      );
      expect(
        container.read(projectCreationPortProvider)!.templateCatalog,
        same(catalog),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

}
