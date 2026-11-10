import 'dart:async';

import 'package:avelune_studio/features/resources/application/resource_usage_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_usage_port.dart';
import 'package:flutter_test/flutter_test.dart';

const _target = ResourceUsageTarget(family: 'decors', id: 'tree');
const _entry = ResourceUsageEntry(
  ownerKind: 'map',
  ownerId: 'garden',
  ownerLabel: 'Jardin',
  location: 'garden.json:placedElements[0]',
  relation: ResourceUsageRelation.direct,
);

ResourceUsageReport _report({List<String> issues = const []}) =>
    ResourceUsageReport(
      target: _target,
      revision: 'revision',
      fingerprints: const {'garden.json': 'fingerprint'},
      entries: const [_entry],
      coverageIssues: issues,
    );

ResourceUsageController _controller(
  _UsagePort port, {
  List<String> Function()? dirtyOwners,
  Future<bool> Function(ResourceUsageEntry)? openOwner,
  Future<String?> Function(ResourceUsageReport)? replace,
  void Function()? changed,
}) => ResourceUsageController(
  target: _target,
  port: port,
  dirtyOwners: dirtyOwners ?? () => [],
  openOwner: openOwner ?? (_) async => true,
  canOpenOwner: (_) => true,
  replace: replace,
  changed: changed ?? () {},
);

void main() {
  test(
    'analysis reports its revision and reflects unresolved drafts',
    () async {
      final port = _UsagePort();
      var dirty = <String>[];
      final controller = _controller(port, dirtyOwners: () => dirty);
      expect(controller.phase, ResourceUsagePhase.notAnalyzed);
      await controller.analyze();
      expect(controller.phase, ResourceUsagePhase.complete);
      expect(controller.report!.revision, 'revision');
      expect(port.targets.single, same(_target));
      expect(port.verifications, 1);
      dirty = ['Carte · Jardin'];
      expect(controller.phase, ResourceUsagePhase.incomplete);
      expect(port.analyses, 1);
      expect(port.verifications, 1);
    },
  );

  test('coverage gaps and changed revisions never become complete', () async {
    for (final current in [false, true]) {
      final port = _UsagePort()
        ..current = current
        ..result = _report(issues: ['Carte indisponible']);
      final controller = _controller(port);
      await controller.analyze();
      expect(
        controller.phase,
        current ? ResourceUsagePhase.incomplete : ResourceUsagePhase.stale,
      );
      expect(controller.report!.coverageIssues, ['Carte indisponible']);
      expect(controller.canReplace, isFalse);
    }
  });

  test('cancellation rejects late reports and waits before retrying', () async {
    final release = Completer<void>();
    bool Function()? cancelled;
    final port = _UsagePort()
      ..analyzeOperation = (check) async {
        cancelled = check;
        await release.future;
        return _report();
      };
    final controller = _controller(port);
    final pending = controller.analyze();
    expect(controller.working, isTrue);
    controller.cancel();
    expect(cancelled!(), isTrue);
    expect(controller.phase, ResourceUsagePhase.cancelled);
    await controller.analyze();
    expect(port.analyses, 1);
    release.complete();
    await pending;
    expect(controller.report, isNull);
    expect(controller.working, isFalse);
    expect(port.verifications, 0);
    port.analyzeOperation = null;
    await controller.analyze();
    expect(port.analyses, 2);
    expect(controller.phase, ResourceUsagePhase.complete);
  });

  test(
    'invalidation marks the report stale without reading the port',
    () async {
      final port = _UsagePort();
      var openings = 0;
      final controller = _controller(
        port,
        openOwner: (_) async {
          openings++;
          return true;
        },
      );
      await controller.analyze();
      controller.invalidate();
      controller.invalidate();
      expect(controller.phase, ResourceUsagePhase.stale);
      expect(controller.report, same(port.result));
      expect(controller.canOpen(_entry), isFalse);
      expect(await controller.open(_entry), isFalse);
      expect(openings, 0);
      expect(port.analyses, 1);
      expect(port.verifications, 1);
    },
  );

  test('failed revision revalidation prevents owner navigation', () async {
    for (final failure in [false, true]) {
      final port = _UsagePort();
      var openings = 0;
      final controller = _controller(
        port,
        openOwner: (_) async {
          openings++;
          return true;
        },
      );
      await controller.analyze();
      port.verifyOperation = (_) async {
        if (failure) throw StateError('Relecture indisponible');
        return false;
      };
      expect(await controller.open(_entry), isFalse);
      expect(openings, 0);
      expect(port.verifications, 2);
      expect(
        controller.phase,
        failure ? ResourceUsagePhase.incomplete : ResourceUsagePhase.stale,
      );
      if (failure) {
        expect(controller.error, contains('Relecture indisponible'));
      }
    }
  });

  for (final replacement in [false, true]) {
    test(
      'invalidation during ${replacement ? 'replacement' : 'opening'} revalidation prevents callbacks',
      () async {
        final verification = Completer<bool>();
        final port = _UsagePort();
        var dirty = <String>[];
        var openings = 0, replacements = 0;
        final controller = _controller(
          port,
          dirtyOwners: () => dirty,
          openOwner: (_) async {
            openings++;
            return true;
          },
          replace: (_) async {
            replacements++;
            return 'Occurrences remplacées';
          },
        );
        await controller.analyze();
        port.verifyOperation = (_) => verification.future;
        final pending = replacement
            ? controller.replaceUsages()
            : controller.open(_entry);
        dirty = ['Carte · Jardin'];
        controller.invalidate();
        verification.complete(true);
        await pending;
        expect(openings, 0);
        expect(replacements, 0);
        expect(controller.phase, ResourceUsagePhase.stale);
        expect(port.verifications, 2);
      },
    );
  }

  test(
    'partial known owners open once and a refusal retains their location',
    () async {
      final release = Completer<bool>();
      final port = _UsagePort()
        ..result = _report(issues: ['Autre carte absente']);
      var openings = 0;
      final controller = _controller(
        port,
        openOwner: (_) {
          openings++;
          return release.future;
        },
      );
      await controller.analyze();
      final pending = controller.open(_entry);
      expect(await controller.open(_entry), isFalse);
      release.complete(false);
      expect(await pending, isFalse);
      expect(openings, 1);
      expect(controller.error, contains(_entry.location));
      expect(controller.phase, ResourceUsagePhase.incomplete);
    },
  );

  test(
    'replacement revalidates clean reports and invalidates its result',
    () async {
      final port = _UsagePort();
      var dirty = <String>[];
      final replaced = <ResourceUsageReport>[];
      final controller = _controller(
        port,
        dirtyOwners: () => dirty,
        replace: (report) async {
          replaced.add(report);
          return 'Deux occurrences remplacées';
        },
      );
      await controller.analyze();
      dirty = ['Carte · Jardin'];
      expect(controller.canReplace, isFalse);
      await controller.replaceUsages();
      expect(replaced, isEmpty);
      dirty = [];
      expect(controller.canReplace, isTrue);
      await controller.replaceUsages();
      expect(replaced.single, same(port.result));
      expect(controller.notice, 'Deux occurrences remplacées');
      expect(controller.phase, ResourceUsagePhase.stale);
      expect(controller.canReplace, isFalse);
      expect(port.verifications, 2);
    },
  );

  test(
    'disposal rejects late verification and preserves the shared port',
    () async {
      final verification = Completer<bool>();
      final port = _UsagePort();
      var openings = 0;
      var notifications = 0;
      final controller = _controller(
        port,
        changed: () => notifications++,
        openOwner: (_) async {
          openings++;
          return true;
        },
      );
      await controller.analyze();
      port.verifyOperation = (_) => verification.future;
      final pending = controller.open(_entry);
      controller.dispose();
      final before = notifications;
      verification.complete(true);
      expect(await pending, isFalse);
      await controller.analyze();
      expect(openings, 0);
      expect(notifications, before);
      expect(port.analyses, 1);
      expect(port.disposed, isFalse);
    },
  );
}

class _UsagePort implements ResourceUsagePort {
  ResourceUsageReport result = _report();
  bool current = true;
  bool disposed = false;
  int analyses = 0, verifications = 0;
  final targets = <ResourceUsageTarget>[];
  Future<ResourceUsageReport> Function(bool Function()?)? analyzeOperation;
  Future<bool> Function(ResourceUsageReport)? verifyOperation;

  @override
  Future<ResourceUsageReport> analyze(
    ResourceUsageTarget target, {
    bool Function()? cancelled,
  }) {
    analyses++;
    targets.add(target);
    return analyzeOperation?.call(cancelled) ?? Future.value(result);
  }

  @override
  Future<bool> isCurrent(ResourceUsageReport report) {
    verifications++;
    return verifyOperation?.call(report) ?? Future.value(current);
  }

  @override
  Future<void> dispose() async => disposed = true;
}
