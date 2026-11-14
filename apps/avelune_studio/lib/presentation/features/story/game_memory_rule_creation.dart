import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/game_memory/application/game_memory_controller.dart';
import 'package:avelune_studio/features/game_memory/application/game_memory_rules.dart';
import 'package:avelune_studio/presentation/features/story/game_memory_condition_fields.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

typedef GameMemoryMapLoader = Future<MapData> Function(ProjectMapEntry entry);

class GameMemoryRuleCreation extends StatefulWidget {
  const GameMemoryRuleCreation({
    super.key,
    required this.memory,
    required this.maps,
    required this.loadMap,
    required this.onClose,
  });

  final GameMemoryController memory;
  final List<ProjectMapEntry> maps;
  final GameMemoryMapLoader loadMap;
  final VoidCallback onClose;

  @override
  State<GameMemoryRuleCreation> createState() => _GameMemoryRuleCreationState();
}

class _GameMemoryRuleCreationState extends State<GameMemoryRuleCreation> {
  final _name = TextEditingController();
  final _characters = <String, Future<List<GameMemoryCharacter>>>{};
  GameMemoryRuleCondition? _condition;
  String? _mapId;
  String? _characterId;
  var _visible = true;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  ProjectMapEntry? get _map =>
      widget.maps.where((entry) => entry.id == _mapId).firstOrNull;

  Future<List<GameMemoryCharacter>> _load(ProjectMapEntry entry) =>
      _characters.putIfAbsent(
        entry.id,
        () async => gameMemoryCharacters(await widget.loadMap(entry)),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final memory = widget.memory;
    final map = _map;
    return ListView(
      key: const ValueKey('memory-rule-creation'),
      padding: const EdgeInsets.all(StudioSpacing.xl),
      children: [
        TextField(
          key: const ValueKey('memory-new-rule-name'),
          controller: _name,
          autofocus: true,
          decoration: InputDecoration(
            isDense: true,
            labelText: l10n.memoryRuleName,
          ),
        ),
        StudioSection(
          title: l10n.memoryRuleWhile,
          children: [
            GameMemoryConditionFields(
              memory: memory,
              enabled: true,
              condition: _condition,
              onChanged: (value) => setState(() => _condition = value),
            ),
          ],
        ),
        StudioSection(
          title: l10n.memoryRuleThen,
          children: [
            KeyedSubtree(
              key: const ValueKey('memory-new-rule-map'),
              child: StudioSelect(
                label: l10n.memoryRuleMap,
                value: _mapId,
                options: {
                  for (final entry in widget.maps) entry.id: entry.name,
                },
                onChanged: (id) => setState(() {
                  _mapId = id;
                  _characterId = null;
                }),
              ),
            ),
            const SizedBox(height: StudioSpacing.m),
            if (map != null)
              FutureBuilder(
                future: _load(map),
                builder: (context, snapshot) => switch (snapshot) {
                  AsyncSnapshot(:final error?) => StudioNotice(
                    l10n.memoryLoadFailed('$error'),
                    isError: true,
                  ),
                  AsyncSnapshot(data: final characters?)
                      when characters.isEmpty =>
                    StudioNotice(l10n.memoryRuleNoCharacter),
                  AsyncSnapshot(data: final characters?) => KeyedSubtree(
                    key: const ValueKey('memory-new-rule-character'),
                    child: StudioSelect(
                      label: l10n.memoryRuleCharacter,
                      value: _characterId,
                      options: {
                        for (final character in characters)
                          character.id: character.name,
                      },
                      onChanged: (id) => setState(() => _characterId = id),
                    ),
                  ),
                  _ => StudioLoadingState(
                    label: l10n.memoryRuleCharactersLoading,
                  ),
                },
              ),
            const SizedBox(height: StudioSpacing.m),
            SegmentedButton<bool>(
              key: const ValueKey('memory-new-rule-effect'),
              showSelectedIcon: false,
              segments: [
                for (final (value, effect) in const [
                  (true, WorldRuleEffectKind.entityVisible),
                  (false, WorldRuleEffectKind.entityHidden),
                ])
                  ButtonSegment(
                    value: value,
                    label: Text(l10n.memoryEffectKind(effect.name)),
                  ),
              ],
              selected: {_visible},
              onSelectionChanged: (value) =>
                  setState(() => _visible = value.single),
            ),
          ],
        ),
        const SizedBox(height: StudioSpacing.l),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            StudioButton(
              label: l10n.memoryCancel,
              variant: StudioButtonVariant.quiet,
              onPressed: widget.onClose,
            ),
            const SizedBox(width: StudioSpacing.s),
            ValueListenableBuilder(
              valueListenable: _name,
              builder: (context, name, _) => StudioButton(
                key: const ValueKey('memory-new-rule-create'),
                label: l10n.memoryCreate,
                onPressed: _ready(name.text) ? _create : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _ready(String name) =>
      name.trim().isNotEmpty &&
      _condition != null &&
      widget.memory.current(_condition!.factId) != null &&
      _map != null &&
      _characterId != null &&
      widget.memory.staging.editable;

  Future<void> _create() async {
    final map = _map!;
    final characters = await _load(map);
    final character = characters
        .where((item) => item.id == _characterId)
        .firstOrNull;
    if (character == null || !mounted) return;
    final created = widget.memory.rules.create(
      label: _name.text,
      condition: _condition!,
      map: map,
      character: character,
      visible: _visible,
    );
    if (created != null) widget.onClose();
  }
}
