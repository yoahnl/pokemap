import 'package:avelune_studio/features/verification/application/studio_failure_diagnosis.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {

  test('known export failures name their family and owner', () {
    StudioFailureDiagnosis of(String code, {String? path}) =>
        diagnoseExportFailure(code: code, summary: code, path: path);
    expect(of('invalidGameVersion').family, StudioCheckFamily.input);
    expect(of('invalidGameVersion').owner, StudioFailureOwner.general);
    expect(of('resource_library.invalid').family, StudioCheckFamily.resources);
    expect(
      of('regional_map.image_invalid').owner,
      StudioFailureOwner.regionalMap,
    );
    expect(
      of('runtime3d.publication_unsupported').family,
      StudioCheckFamily.runtimeCapabilities,
    );
    expect(
      of('runtime3d.publication_unsupported').owner,
      StudioFailureOwner.exportMode,
    );
    expect(of('exportWriteFailed').owner, StudioFailureOwner.exportDestination);
    expect(
      of('missingProjectFile', path: 'assets/a.png').owner,
      StudioFailureOwner.resources,
    );
    expect(of('missingProjectFile', path: 'scenes/a.json').owner, isNull);
    final readiness = diagnoseExportFailure(
      code: 'gameplayReadinessFailed',
      summary: 'Pas jouable',
      readinessCodes: const ['exportNewGameStartSpawnRequired'],
    );
    expect(readiness.family, StudioCheckFamily.launch);
    expect(readiness.owner, StudioFailureOwner.map);
    final mixed = diagnoseExportFailure(
      code: 'gameplayReadinessFailed',
      summary: 'Pas jouable',
      readinessCodes: const [
        'exportNewGameStartSpawnRequired',
        'exportStoryEndUnreachable',
      ],
    );
    expect(mixed.family, StudioCheckFamily.launch);
    expect(mixed.owner, isNull);
    final unknown = of('somethingNew');
    expect(unknown.determined, isFalse);
    expect(unknown.owner, isNull);
    expect(unknown.detail, 'somethingNew');
  });

  test('a launch failure is owned only when its cause is typed', () {
    final known = diagnoseLaunchFailure(
      const StudioLaunchProblem('Aucune case', owner: StudioFailureOwner.map),
    );
    expect(known.family, StudioCheckFamily.launch);
    expect(known.owner, StudioFailureOwner.map);
    final capability = diagnoseLaunchFailure(
      StateError('The project requires gameplay.periodic-reward-condition@1.'),
    );
    expect(capability.family, StudioCheckFamily.runtimeCapabilities);
    expect(capability.owner, isNull);
    expect(
      capability.summary,
      contains('gameplay.periodic-reward-condition@1'),
    );
    final unknown = diagnoseLaunchFailure(StateError('moteur'));
    expect(unknown.determined, isFalse);
    expect(unknown.owner, isNull);
    expect(unknown.detail, contains('moteur'));
  });

}
