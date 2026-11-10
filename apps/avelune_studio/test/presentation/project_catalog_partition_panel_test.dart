import 'dart:async';

import 'package:avelune_studio/features/resources/coordination/project_catalog_partition_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('library optimization stays guarded by its child draft and explicit consent', () async {
    var allowed = false, approved = false;
    var confirmations = 0, partitions = 0, reopens = 0;
    final workflow = ProjectCatalogPartitionWorkflow(
      partition: () async {
        partitions++;
      },
      reopen: () async {
        reopens++;
      },
      confirm: () async {
        confirmations++;
        return approved;
      },
      isActive: () => true,
      changed: () {},
    )..childGuard = () async => allowed;
    expect(await workflow.optimize(), isFalse);
    expect(confirmations, 0);
    allowed = true;
    expect(await workflow.optimize(), isFalse);
    expect(partitions, 0);
    approved = true;
    expect(await workflow.optimize(), isTrue);
    expect(partitions, 1);
    expect(reopens, 1);
  });

  test(
    'a converted catalogue retries reopening without converting twice',
    () async {
      var partitions = 0, reopens = 0;
      final workflow = ProjectCatalogPartitionWorkflow(
        partition: () async {
          partitions++;
        },
        reopen: () async {
          if (++reopens == 1) throw StateError('reopen unavailable');
        },
        confirm: () async => true,
        isActive: () => true,
        changed: () {},
      );
      expect(await workflow.optimize(), isFalse);
      expect(workflow.error, contains('reopen unavailable'));
      expect(await workflow.optimize(), isTrue);
      expect(partitions, 1);
      expect(reopens, 2);
      expect(workflow.error, isNull);
    },
  );

  test('an active partition locks repeated conversion and exit', () async {
    final gate = Completer<void>();
    final started = Completer<void>();
    var partitions = 0;
    final workflow = ProjectCatalogPartitionWorkflow(
      partition: () async {
        partitions++;
        started.complete();
        await gate.future;
      },
      reopen: () async {},
      confirm: () async => true,
      isActive: () => true,
      changed: () {},
    );
    final partitioning = workflow.optimize();
    await started.future;
    expect(await workflow.optimize(), isFalse);
    expect(await workflow.allowExit(), isFalse);
    gate.complete();
    expect(await partitioning, isTrue);
    expect(partitions, 1);
  });

  test('late partition consent cannot convert a disposed workspace', () async {
    final consent = Completer<bool>();
    final started = Completer<void>();
    var partitions = 0;
    final workflow = ProjectCatalogPartitionWorkflow(
      partition: () async {
        partitions++;
      },
      reopen: () async {},
      confirm: () {
        started.complete();
        return consent.future;
      },
      isActive: () => true,
      changed: () {},
    );
    final partitioning = workflow.optimize();
    await started.future;
    workflow.dispose();
    consent.complete(true);
    expect(await partitioning, isFalse);
    expect(partitions, 0);
  });
}
