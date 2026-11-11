part of 'cinematic_inspector.dart';

extension CinematicInspectorCommands on CinematicInspector {
  List<Widget> _commandFields(
    CinematicAsset asset,
    CinematicTimelineStep step,
  ) {
    final mediaKind = cinematicCommandMediaKind(step.kind);
    return [
      CinematicCommitField(
        inputs: controller.inputsFor(asset.id),
        changed: changed,
        key: ValueKey('step-label-${asset.id}-${step.id}'),
        label: 'Nom du bloc',
        value: step.label ?? '',
        tryCommit: (value) => _edit(
          asset,
          (a) => updateCinematicTimelineCommandStep(
            a,
            stepId: step.id,
            label: value,
          ).cinematic,
        ),
      ),
      if (step.kind == CinematicTimelineStepKind.dialogueLine) ...[
        StudioSelect(
          label: 'Dialogue lié',
          value: step.assetRef,
          options: {
            for (final dialogue in controller.project.dialogues)
              dialogue.id: '${dialogue.name} · ${dialogue.id}',
          },
          onChanged: (id) => _edit(
            asset,
            (a) => updateCinematicTimelineCommandStep(
              a,
              stepId: step.id,
              dialogueId: id,
            ).cinematic,
          ),
        ),
        StudioButton(
          label: 'Ouvrir le dialogue',
          secondary: true,
          icon: Icons.forum_outlined,
          onPressed: step.assetRef == null
              ? null
              : () => onDialogue(step.assetRef!),
        ),
      ],
      if (mediaKind != null) ...[
        StudioSelect(
          label: 'Média du projet',
          value: step.assetRef,
          options: {
            for (final media in cinematicCommandMediaChoices(
              controller.project,
              step,
            ))
              media.id: '${media.label} · ${media.id}',
          },
          onChanged: (id) => _edit(
            asset,
            (a) => updateCinematicTimelineCommandStep(
              a,
              stepId: step.id,
              mediaAsset: controller.project.cinematicMediaAssets.firstWhere(
                (m) => m.id == id,
              ),
            ).cinematic,
          ),
        ),
        _number(
          asset,
          step,
          'Volume (0 à 1)',
          step.metadata[cinematicTimelineCommandVolumeMetadataKey] ?? '1',
          (a, value) => updateCinematicTimelineCommandStep(
            a,
            stepId: step.id,
            volume: value,
          ).cinematic,
          max: 1,
        ),
        _number(
          asset,
          step,
          'Transition audio (ms)',
          step.metadata[cinematicTimelineCommandFadeMsMetadataKey] ?? '0',
          (a, value) => updateCinematicTimelineCommandStep(
            a,
            stepId: step.id,
            fadeMs: value.toInt(),
          ).cinematic,
          integer: true,
        ),
        StudioSelect(
          label: 'Lecture du média',
          value:
              step.metadata[cinematicTimelineCommandLoopMetadataKey] ?? 'false',
          options: const {
            'false': 'Une fois',
            'true': 'En boucle pendant la séquence',
          },
          onChanged: (value) => _edit(
            asset,
            (a) => updateCinematicTimelineCommandStep(
              a,
              stepId: step.id,
              loop: value == 'true',
            ).cinematic,
          ),
        ),
        const Text(
          'Le média doit être disponible dans le projet. L’aperçu spatial seul ne certifie pas sa lecture audio.',
        ),
      ],
      if (step.kind == CinematicTimelineStepKind.shake)
        _number(
          asset,
          step,
          'Intensité (0 à 1)',
          step.metadata[cinematicTimelineCommandIntensityMetadataKey] ?? '0.5',
          (a, value) => updateCinematicTimelineCommandStep(
            a,
            stepId: step.id,
            intensity: value,
          ).cinematic,
          max: 1,
        ),
    ];
  }

  Widget _number(
    CinematicAsset asset,
    CinematicTimelineStep step,
    String label,
    String value,
    CinematicAsset Function(CinematicAsset, double) transform, {
    double? max,
    bool integer = false,
  }) => CinematicCommitField(
    inputs: controller.inputsFor(asset.id),
    changed: changed,
    key: ValueKey('$label-${asset.id}-${step.id}'),
    label: label,
    alwaysCommit: true,
    value: value,
    tryCommit: (text) {
      final accepted = controller.commitCommandNumber(
        asset.id,
        view.inputs,
        label,
        text,
        transform,
        max: max,
        integer: integer,
      );
      changed();
      return accepted;
    },
  );
}
