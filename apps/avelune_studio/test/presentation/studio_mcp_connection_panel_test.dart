import 'package:avelune_studio/platform/mcp/studio_mcp_service.dart';
import 'package:avelune_studio/presentation/features/settings/studio_mcp_connection_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../platform/mcp/studio_mcp_service_test.dart'
    show FakeStudioMcpProcess, flush;

void main() {
  testWidgets(
    'ready configuration is copied without rendering its private key',
    (tester) async {
      final process = FakeStudioMcpProcess();
      final service = StudioMcpService(launch: () async => process);
      addTearDown(service.dispose);
      await tester.runAsync(() async {
        final starting = service.start();
        await flush();
        process.ready();
        await starting;
      });
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: StudioMcpConnectionPanel(service: service)),
      );
      expect(find.text('Connexion prête'), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      await tester.tap(find.text('Copier la configuration'));
      await tester.pump();
      expect(copied, contains('Bearer secret'));
      expect(copied, contains('http://127.0.0.1:43210/mcp'));
      expect(find.textContaining('Configuration copiée.'), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(service.stop);
    },
  );

  testWidgets('failed service remains actionable and a retry is explicit', (
    tester,
  ) async {
    var attempts = 0;
    final process = FakeStudioMcpProcess();
    final service = StudioMcpService(
      launch: () async {
        attempts++;
        if (attempts == 1) throw StateError('private detail secret');
        return process;
      },
    );
    addTearDown(service.dispose);
    await tester.runAsync(service.start);
    await tester.pumpWidget(
      MaterialApp(home: StudioMcpConnectionPanel(service: service)),
    );
    expect(find.textContaining('secret'), findsNothing);
    expect(find.text('Réessayer la connexion'), findsOneWidget);
    await tester.tap(find.text('Réessayer la connexion'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.text('Connexion en cours de démarrage…'), findsOneWidget);
    process.ready();
    await tester.pump();
    expect(find.text('Connexion prête'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(service.stop);
  });
}
