import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/coordination/resource_replacement_workflow.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> runReplacementForTest({
  required ResourceNavigation navigation,
  required ResourceItem item,
  required PickResourceImage picker,
  required bool Function() isActive,
  required Future<void> Function(ResourceReplacementSession) present,
  bool shouldPresent = true,
}) async {
  Object? presentationFailure;
  StackTrace? presentationTrace;
  var presented = false;
  await runResourceImageReplacement(
    navigation: navigation,
    item: item,
    picker: picker,
    isActive: isActive,
    present: (session) async {
      presented = true;
      try {
        await present(session);
      } catch (failure, trace) {
        presentationFailure = failure;
        presentationTrace = trace;
        rethrow;
      }
    },
  );
  if (presentationFailure case final failure?) {
    Error.throwWithStackTrace(failure, presentationTrace!);
  }
  expect(presented, shouldPresent, reason: navigation.error);
}
