import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter/converter_app.dart';
import 'package:avelune_converter/desktop_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

Future<void> main() async {
  if (!kDebugMode || !Platform.isMacOS) {
    throw StateError('Converter qualification requires a macOS debug build.');
  }
  MarionetteBinding.ensureInitialized();
  const selected = String.fromEnvironment('AVELUNE_CONVERTER_QA_PLAN');
  if (selected.isEmpty ||
      await File(selected).resolveSymbolicLinks() != selected) {
    throw StateError('A canonical AVELUNE_CONVERTER_QA_PLAN is required.');
  }
  final recipe = await const LocalStudyPlanStore().read(selected);
  ConverterWorkflow? active;
  developer.registerExtension('ext.flutter.avelune.converterQualification', (
    method,
    parameters,
  ) async {
    final state = active?.state;
    return developer.ServiceExtensionResponse.result(
      jsonEncode({
        'planPath': selected,
        'recipeHash': recipe.canonicalHash.value,
        'expectedApprovedPlanHash': recipe.approvedPlanHash.value,
        'expectedSource': recipe.sourceSelection.rootPath,
        'activeSource': state?.source?.rootPath,
        'phase': state?.phase?.name,
        'busy': state?.isBusy,
        'preparedPlanHash': state?.prepared?.previewPlan?.canonicalHash.value,
        'approvalHash': state?.approval?.approvedPlanHash.value,
        'result': state?.result == null
            ? null
            : {
                'projectPath': state!.result!.projectPath,
                'published': state.result!.published,
                'nativeRevision': state.result!.receipt.nativeRevision,
                'approvedPlanHash': state.result!.approvedPlanHash.value,
                'sourceUnchanged': state.result!.sourceUnchanged,
                'playableCertified': state.result!.playableCertified,
              },
        'errorCode': state?.failure?.code,
        'pid': pid,
      }),
    );
  });
  runApp(
    ConverterApp(
      workflowFactory: () => active = ConverterWorkflow(),
      pathPicker: (kind) async => switch (kind) {
        ConverterPathKind.planFile => selected,
        ConverterPathKind.sourceFolder => recipe.sourceSelection.rootPath,
        ConverterPathKind.destinationParent => recipe.settings.parentPath,
        ConverterPathKind.sourceProject => null,
      },
    ),
  );
}
