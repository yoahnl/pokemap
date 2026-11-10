import 'dart:async';

import 'package:avelune_studio/features/resources/application/model_definition_drafts.dart';
import 'package:avelune_studio/features/resources/application/model_light_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spatial_environment_fixture.dart';

typedef _Lifecycle = ({
  Future<bool> Function(Future<void> Function()) save,
  void Function() dispose,
  String? Function() error,
});

_Lifecycle _owner(String kind) {
  final model = spatialEnvironmentProject().models3d.single;
  switch (kind) {
    case 'collision':
      final draft = ModelCollisionDraft(model);
      return (
        save: (publish) => draft.save((_, _) => publish(), canSave: () => true),
        dispose: draft.dispose,
        error: () => draft.error,
      );
    case 'ramp':
      final draft = ModelRampDraft(model);
      return (
        save: (publish) => draft.save((_) => publish(), canSave: () => true),
        dispose: draft.dispose,
        error: () => draft.error,
      );
    case 'shadow':
      final draft = ModelShadowDraft(model);
      return (
        save: (publish) =>
            draft.save(true, (_) => publish(), canSave: () => true),
        dispose: draft.dispose,
        error: () => draft.error,
      );
    default:
      final draft = ModelLightDraft(model);
      return (
        save: (publish) => draft.save((_) => publish(), canSave: () => true),
        dispose: draft.dispose,
        error: () => draft.error,
      );
  }
}

void main() {
  for (final kind in ['collision', 'ramp', 'shadow', 'light']) {
    test(
      'a closed $kind draft refuses publication before invoking its callback',
      () async {
        final owner = _owner(kind);
        var publications = 0;
        owner.dispose();
        expect(
          await owner.save(() async {
            publications++;
          }),
          isFalse,
        );
        expect(publications, 0);
      },
    );

    test(
      'a late $kind save failure cannot reinstall state after disposal',
      () async {
        final owner = _owner(kind);
        final gate = Completer<void>();
        var publications = 0;
        final saving = owner.save(() {
          publications++;
          return gate.future;
        });
        owner.dispose();
        gate.completeError(StateError('obsolete failure'));
        expect(await saving, isFalse);
        expect(publications, 1);
        expect(owner.error(), isNull);
      },
    );
  }
}
