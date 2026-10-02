import 'dart:async';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_usage_results.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu_resource_host.dart';

void main() {
  testWidgets(
    'cancelled actual analysis publishes no late report and prevents concurrent retry',
    (tester) async {
      late _RetainedUsagePort retained;
      final host = await UwUResourceHost.open(
        tester,
        wrapUsages: (port) => retained = _RetainedUsagePort(port),
      );
      await host.family(ResourceKind.images);
      await host.action('images:atelier', 'Voir les usages dans le projet');
      await host.tap('resource-usage-analyze');
      expect(retained.reached.isCompleted, isTrue);
      expect(find.text('Analyse en cours'), findsOneWidget);
      await tester.tap(find.text('Annuler l’analyse'));
      await pumpIo(tester, frames: 3);
      expect(find.text('Analyse annulée · nettoyage en cours'), findsOneWidget);
      final button = tester.widget<StudioButton>(
        find.byKey(const ValueKey('resource-usage-analyze')),
      );
      expect(button.onPressed, isNull);
      expect(retained.calls, 1);
      retained.release.complete();
      await pumpIo(tester, frames: 12);
      expect(find.text('Analyse annulée'), findsOneWidget);
      expect(
        tester
            .widget<ResourceUsageResults>(find.byType(ResourceUsageResults))
            .report,
        isNull,
      );
      expect((await host.reopen()).tilesets.single.id, 'atelier');
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('resource-usage-analyze')),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets('usage revalidation error refuses real owner navigation', (
    tester,
  ) async {
    late _ObservedUsagePort observed;
    final host = await UwUResourceHost.open(
      tester,
      wrapUsages: (port) => observed = _ObservedUsagePort(port),
    );
    await host.family(ResourceKind.images);
    await host.action('images:atelier', 'Voir les usages dans le projet');
    await host.tap('resource-usage-analyze');
    final report = tester
        .widget<ResourceUsageResults>(find.byType(ResourceUsageResults))
        .report!;
    observed.failVerification = true;
    await host.openUsage(
      report.entries.firstWhere((entry) => entry.mapId == 'clairiere'),
    );
    expect(host.fixture.controller.active!.current.id, 'jardin');
    expect(find.text('Analyse incomplète'), findsOneWidget);
    expect(find.textContaining('Relecture indisponible'), findsOneWidget);
    expect(observed.verifications, 2);
  });

  testWidgets('draft notifications invalidate usage report without disk scan', (
    tester,
  ) async {
    late _ObservedUsagePort observed;
    final host = await UwUResourceHost.open(
      tester,
      wrapUsages: (port) => observed = _ObservedUsagePort(port),
    );
    await host.family(ResourceKind.images);
    await host.action('images:atelier', 'Voir les usages dans le projet');
    await host.tap('resource-usage-analyze');
    expect(observed.verifications, 1);
    final document = host.fixture.controller.active!;
    final commands = MapEditingCommands(
      document,
      host.fixture.controller.project!,
    );
    for (var x = 14; x < 17; x++) {
      commands.place(
        host.fixture.controller.project!.elements.first,
        GridPos(x: x, y: 10),
      );
      host.fixture.controller.notify();
      await tester.pump();
    }
    expect(observed.verifications, 1);
    expect(observed.analyses, 1);
    expect(find.text('Résultat périmé · relancez l’analyse'), findsOneWidget);
    expect(find.textContaining('Brouillons non analysés'), findsOneWidget);
    expect(document.dirty, isTrue);
  });
}

class _ObservedUsagePort implements ResourceUsagePort {
  _ObservedUsagePort(this.delegate);
  final ResourceUsagePort delegate;
  int analyses = 0, verifications = 0;
  bool failVerification = false;
  @override
  Future<ResourceUsageReport> analyze(
    ResourceUsageTarget target, {
    bool Function()? cancelled,
  }) {
    analyses++;
    return delegate.analyze(target, cancelled: cancelled);
  }

  @override
  Future<bool> isCurrent(ResourceUsageReport report) {
    verifications++;
    if (failVerification) {
      throw StateError('Relecture indisponible');
    }
    return delegate.isCurrent(report);
  }

  @override
  Future<void> dispose() => delegate.dispose();
}

class _RetainedUsagePort implements ResourceUsagePort {
  _RetainedUsagePort(this.delegate);
  final ResourceUsagePort delegate;
  final reached = Completer<void>();
  final release = Completer<void>();
  int calls = 0;
  @override
  Future<ResourceUsageReport> analyze(
    ResourceUsageTarget target, {
    bool Function()? cancelled,
  }) async {
    calls++;
    final report = await delegate.analyze(target, cancelled: cancelled);
    reached.complete();
    await release.future;
    if (cancelled?.call() == true) throw const ResourceUsageCancelled();
    return report;
  }

  @override
  Future<bool> isCurrent(ResourceUsageReport report) =>
      delegate.isCurrent(report);
  @override
  Future<void> dispose() => delegate.dispose();
}
