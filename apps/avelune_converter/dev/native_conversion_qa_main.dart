import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:avelune_converter/converter_app.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:path/path.dart' as path;

Future<void> main() async {
  if (!kDebugMode || !Platform.isMacOS) {
    throw StateError('Native conversion QA requires macOS debug mode.');
  }
  MarionetteBinding.ensureInitialized();
  const sourcePath = String.fromEnvironment('AVELUNE_QA_SOURCE');
  const parentPath = String.fromEnvironment('AVELUNE_QA_PARENT');
  for (final value in [sourcePath, parentPath]) {
    if (!path.isAbsolute(value) ||
        path.normalize(value) != value ||
        value == path.rootPrefix(value)) {
      throw StateError(
        'Explicit absolute source and parent paths are required.',
      );
    }
  }
  ConverterWorkflow? active;
  developer.registerExtension('ext.flutter.avelune.nativeConversionQa', (
    method,
    parameters,
  ) async {
    final state = active?.state;
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'expectedSource': sourcePath,
        'expectedParent': parentPath,
        'source': state?.source?.rootPath,
        'supplementalRoots': state?.source?.supplementalRootPaths,
        'selectedMaps': state?.settings?.selectedSourceMapIds,
        'phase': state?.phase?.name,
        'busy': state?.isBusy,
        'progress': state?.progress == null
            ? null
            : {
                'done': state!.progress!.done,
                'total': state.progress!.total,
                'unit': state.progress!.unit.name,
              },
        'prepared': state?.prepared == null
            ? null
            : {
                'canApprove': state!.prepared!.canApprove,
                'mapCount': state.prepared!.composition.nativeMaps.length,
                'planHash': state.prepared!.previewPlan?.canonicalHash.value,
                'blockingDiagnostics': [
                  for (final diagnostic
                      in state.prepared!.normalizedSource.diagnostics)
                    if (diagnostic.blocksPlanning) diagnostic.toJson(),
                  for (final diagnostic
                      in state.prepared!.composition.diagnostics)
                    if (diagnostic.blocksPlanning) diagnostic.toJson(),
                ],
              },
        'result': state?.result == null
            ? null
            : {
                'projectPath': state!.result!.projectPath,
                'published': state.result!.published,
                'sourceUnchanged': state.result!.sourceUnchanged,
                'nativeRevision': state.result!.receipt.nativeRevision,
              },
        'failure': state?.failure?.toString(),
        'pid': pid,
      }),
    );
  });
  runApp(
    ConverterApp(
      workflowFactory: () => active = ConverterWorkflow(),
      initialSourcePath: sourcePath,
      initialParentPath: parentPath,
    ),
  );
}
