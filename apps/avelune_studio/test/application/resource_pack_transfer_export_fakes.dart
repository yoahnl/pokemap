import 'dart:async';

import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resource_pack_transfer_test_ports.dart';

class ExportPackTestPort extends PackTestPort {
  final authorizedPaths = <String>[];
  final released = <String>[];
  Map<String, Object?>? lastExport;
  int preparations = 0, licenses = 0;
  bool failNativeRelease = false;
  @override
  Future<void> authorizeSource(String path) async {
    authorizedPaths.add(path);
  }

  @override
  Future<List<int>> readExportPayloadChunk(
    String payloadRef,
    int offset,
    int length,
  ) async => [1, 2, 3].skip(offset).take(length).toList();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb == 'selection.create' && input['mode'] == 'native') {
      verbs.add(verb);
      inputs.add(input);
      return {...summary, 'sourceRevision': 'snapshot-revision'};
    }
    if (verb == 'stage_license') {
      verbs.add(verb);
      inputs.add(input);
      licenses++;
      return settled({
        'licenseHandle': 'license-$licenses',
        'rawSha256': 'document-$licenses',
        'byteLength': 12,
      });
    }
    if (verb == 'prepare' && input.containsKey('metadata')) {
      verbs.add(verb);
      inputs.add(input);
      preparations++;
      return settled({
        'preparedExportHandle': 'native-prepared-$preparations',
        'previewHandle': 'native-preview-$preparations',
        'projectionFingerprint': 'projection-$preparations',
        'requiresOrganizationAcknowledgement': true,
        'resourceCount': 2,
        'summary': {
          'selectedRootCount': selected,
          'resourceCount': 2,
          'supportCount': 0,
          'fileCount': 1,
          'promotionCount': 1,
          'neutralizationCount': 1,
          'sourceCount': 1,
          'globalCreditCount': 1,
          'licenseCount': licenses,
          'publicationNoticeCount': 1,
        },
      });
    }
    if (verb == 'preview' &&
        (input['previewHandle'] as String).startsWith('native-preview')) {
      verbs.add(verb);
      inputs.add(input);
      return {
        'scope': 'preparedNativeClosure',
        'items': input['cursor'] == null
            ? [
                {
                  'kind': 'resource',
                  'resourceKind': 'character',
                  'nativeId': 'hero',
                  'id': 'hero',
                  'label': 'Hero',
                  'selected': true,
                },
              ]
            : [
                {
                  'kind': 'resource',
                  'resourceKind': 'borderBlueprint',
                  'nativeId': 'late',
                  'id': 'late',
                  'label': 'Late border',
                  'selected': true,
                },
              ],
        if (input['cursor'] == null) 'nextCursor': 'later',
      };
    }
    if (verb == 'export') {
      verbs.add(verb);
      inputs.add(input);
      lastExport = Map.of(input);
      return settled({
        'artifactHandle': 'artifact',
        'payloadRef': 'payload',
        'rawSha256': 'hash',
        'byteLength': 3,
      });
    }
    if (verb == 'release') {
      released.add(input['handle']! as String);
      if (failNativeRelease &&
          (input['handle']! as String).startsWith('native-prepared')) {
        failNativeRelease = false;
        throw StateError('cleanup');
      }
      return {'released': true};
    }
    return super.transfer(verb, input);
  }
}

class ExportTestSink implements ResourcePackExportSink {
  @override
  Future<ResourcePackPublication> reconcilePublication(String token) async =>
      throw StateError('No pending publication');
  ExportTestSink({this.wait = false});
  final bool wait;
  final entered = Completer<void>(), gate = Completer<void>();
  List<int> bytes = [];
  @override
  Future<ResourcePackPublication> publish({
    required String suggestedName,
    required int byteLength,
    required String rawSha256,
    required Future<List<int>> Function(int, int) readChunk,
    required bool Function() isCancelled,
    required void Function() enterFinalization,
  }) async {
    entered.complete();
    if (wait) await gate.future;
    if (isCancelled()) return const ResourcePackPublication.cancelled();
    bytes = await readChunk(0, byteLength);
    enterFinalization();
    return const ResourcePackPublication.published('/published.aveluneassets');
  }
}

class LateExportPackPort extends ExportPackTestPort {
  String? lateVerb;
  final entered = Completer<void>(), gate = Completer<void>();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    final result = await super.transfer(verb, input);
    if (verb == lateVerb) {
      entered.complete();
      await gate.future;
    }
    return result;
  }
}

class LatePreviewExportPort extends ExportPackTestPort {
  bool delay = false;
  final entered = Completer<void>();
  final gate = Completer<Map<String, Object?>>();
  @override
  Future<Map<String, Object?>> transfer(
    String verb, [
    Map<String, Object?> input = const {},
  ]) async {
    if (verb == 'preview' && delay) {
      entered.complete();
      return gate.future;
    }
    return super.transfer(verb, input);
  }
}

class PendingExportTestSink extends ExportTestSink {
  int requeries = 0;
  @override
  Future<ResourcePackPublication> publish({
    required String suggestedName,
    required int byteLength,
    required String rawSha256,
    required Future<List<int>> Function(int, int) readChunk,
    required bool Function() isCancelled,
    required void Function() enterFinalization,
  }) async {
    enterFinalization();
    return const ResourcePackPublication.pending('native-pending');
  }

  @override
  Future<ResourcePackPublication> reconcilePublication(String token) async {
    expect(token, 'native-pending');
    requeries++;
    return const ResourcePackPublication.published('/published.aveluneassets');
  }
}
