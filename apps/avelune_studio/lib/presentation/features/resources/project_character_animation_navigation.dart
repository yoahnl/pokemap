part of 'project_character_animation_editor.dart';

const _workshopDirections = [
  EntityFacing.south,
  EntityFacing.north,
  EntityFacing.west,
  EntityFacing.east,
];

const _animationGroups = [
  (
    title: 'Déplacements',
    icon: Icons.directions_walk_outlined,
    states: [
      CharacterAnimationState.idle,
      CharacterAnimationState.walk,
      CharacterAnimationState.run,
      CharacterAnimationState.climb,
      CharacterAnimationState.bicycleIdle,
      CharacterAnimationState.bicycle,
    ],
  ),
  (
    title: 'Sur l’eau',
    icon: Icons.water_outlined,
    states: [
      CharacterAnimationState.surfIdle,
      CharacterAnimationState.surf,
      CharacterAnimationState.surfEnter,
      CharacterAnimationState.surfExit,
    ],
  ),
  (
    title: 'Actions',
    icon: Icons.bolt_outlined,
    states: [
      CharacterAnimationState.cut,
      CharacterAnimationState.rockSmash,
      CharacterAnimationState.strength,
      CharacterAnimationState.push,
    ],
  ),
];

extension _CharacterAnimationNavigation
    on _ProjectCharacterAnimationEditorState {
  List<CharacterCustomAnimationDefinition> get _definitions =>
      widget.project.characterStudioCatalog.customAnimationDefinitions;

  Widget _animationSidebar(BuildContext context) {
    final configured = <CharacterAnimationState, int>{};
    for (final clip in widget.character.animations) {
      if (clip.frames.isEmpty) continue;
      configured.update(clip.state, (count) => count + 1, ifAbsent: () => 1);
    }
    return StudioPanel(
      compact: true,
      children: [
        _createAnimationButton(),
        const Divider(),
        Expanded(
          child: ListView(
            primary: false,
            children: [
              for (final group in _animationGroups) ...[
                _animationGroupTitle(context, group.title),
                for (final state in group.states)
                  _animationEntry(
                    state.name,
                    characterAnimationLabel(state),
                    group.icon,
                    configured[state] ?? 0,
                    _workshopDirections.length,
                  ),
              ],
              if (_definitions.isNotEmpty) ...[
                _animationGroupTitle(context, 'Personnalisées'),
                for (final definition in _definitions)
                  _animationEntry(
                    'custom:${definition.id}',
                    definition.displayName,
                    Icons.animation_outlined,
                    widget.character.customAnimations
                        .where(
                          (clip) =>
                              clip.definitionId == definition.id &&
                              clip.frames.isNotEmpty,
                        )
                        .length,
                    definition.mode == CharacterCustomAnimationMode.single
                        ? 1
                        : _workshopDirections.length,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _animationPicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioSelect(
        label: 'Animation',
        value: _selection,
        options: {
          for (final group in _animationGroups)
            for (final state in group.states)
              state.name: characterAnimationLabel(state),
          for (final definition in _definitions)
            'custom:${definition.id}': definition.displayName,
        },
        onChanged: _canNavigate ? _selectAnimation : null,
      ),
      Align(alignment: Alignment.centerLeft, child: _createAnimationButton()),
    ],
  );

  Widget _createAnimationButton() => StudioButton(
    label: 'Nouvelle animation',
    icon: Icons.add,
    variant: StudioButtonVariant.quiet,
    onPressed: _canNavigate ? _create : null,
  );

  Widget _animationGroupTitle(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: StudioSpacing.m),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );

  Widget _animationEntry(
    String id,
    String name,
    IconData icon,
    int count,
    int total,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
    child: StudioNavigationEntry(
      key: ValueKey('character-animation-$id'),
      icon: icon,
      label: name,
      selected: _selection == id,
      marker: count == 0
          ? null
          : StudioBadge(
              '$count/$total',
              tone: count == total ? StudioTone.success : StudioTone.neutral,
            ),
      markerLabel: count == 0 ? 'À configurer' : '$count directions sur $total',
      onTap: _canNavigate ? () => _selectAnimation(id) : null,
    ),
  );
}
