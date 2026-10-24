import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../app/providers/core/repository_providers.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../design_system/design_system.dart';

class ContactDeviceConfigurationSheet extends ConsumerWidget {
  const ContactDeviceConfigurationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final project = state.project;
    final path = state.projectRootPath;
    if (project == null || path == null) {
      return const PokeMapEmptyState(
        title: 'Aucun projet ouvert',
        description:
            'Ouvrez un projet pour configurer son appareil de contacts.',
        icon: Icon(Icons.contacts_outlined),
      );
    }
    return ContactDeviceConfigurationForm(
      project: project,
      onSave: (configuration) async {
        final queries = ref.read(authoringQueryAdapterProvider);
        await queries.invalidate(path);
        final before = await queries.open(path);
        if (before.manifest != ref.read(editorNotifierProvider).project) {
          throw StateError(
            'Le projet a changé. Rechargez sa configuration avant de continuer.',
          );
        }
        final operation =
            'editor_contacts_${DateTime.now().microsecondsSinceEpoch}';
        final mutations = ref.read(authoringMutationAdapterProvider);
        final plan = await mutations.plan(
          path,
          actionId: 'contact_device.configure',
          parameters: {'configuration': configuration?.toJson()},
          idempotencyKey: operation,
          requestId: operation,
          expectedRevision: before.snapshotRevision,
        );
        await mutations.apply(plan, operationId: operation);
        await queries.invalidate(path);
        ref
            .read(editorNotifierProvider.notifier)
            .acceptCanonicalProjectManifest(
              (await queries.open(path)).manifest,
              statusMessage: 'Appareil de contacts sauvegardé.',
            );
        return true;
      },
    );
  }
}

class ContactDeviceConfigurationForm extends StatefulWidget {
  const ContactDeviceConfigurationForm({
    super.key,
    required this.project,
    required this.onSave,
  });
  final ProjectManifest project;
  final Future<bool> Function(ProjectContactDeviceConfig?) onSave;

  @override
  State<ContactDeviceConfigurationForm> createState() =>
      _ContactDeviceConfigurationFormState();
}

class _ContactDeviceConfigurationFormState
    extends State<ContactDeviceConfigurationForm> {
  late bool enabled = widget.project.contactDevice != null;
  late final label = TextEditingController(
    text: widget.project.contactDevice?.label ?? 'Appareil de contacts',
  );
  late final empty = TextEditingController(
    text:
        widget.project.contactDevice?.emptyMessage ??
        'Aucun contact enregistré.',
  );
  late String acquiredFact = widget.project.contactDevice?.acquiredFactId ?? '';
  late final contacts = [
    for (final entry
        in widget.project.contactDevice?.contacts ??
            <ProjectContactEntryConfig>[])
      _ContactDraft.from(entry),
  ];
  bool saving = false;
  String? message;

  @override
  void dispose() {
    label.dispose();
    empty.dispose();
    for (final contact in contacts) {
      contact.label.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      message = null;
    });
    try {
      if (enabled &&
          widget.project.settings.dimension != ProjectDimension.threeD) {
        throw const FormatException(
          'L’appareil de contacts nécessite un projet en 3D.',
        );
      }
      final configuration = enabled
          ? ProjectContactDeviceConfig(
              id: widget.project.contactDevice?.id ?? 'contact-device',
              label: label.text.trim(),
              acquiredFactId: acquiredFact,
              emptyMessage: empty.text.trim(),
              contacts: [for (final c in contacts) c.build()],
            )
          : null;
      final errors =
          configuration?.referenceErrors(
            facts: widget.project.facts,
            sceneIds: widget.project.scenes.map((s) => s.id).toSet(),
            characterIds: widget.project.characters.map((c) => c.id).toSet(),
          ) ??
          [];
      if (errors.isNotEmpty) throw FormatException(errors.join('\n'));
      final accepted = await widget.onSave(configuration);
      if (mounted) {
        setState(
          () => message = accepted
              ? 'Appareil de contacts sauvegardé.'
              : 'La configuration n’a pas été enregistrée.',
        );
      }
    } on Object catch (error) {
      if (mounted) setState(() => message = error.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget factPicker(
    String key,
    String title,
    String value,
    ValueChanged<String> onChanged, {
    bool optional = false,
  }) => PokeMapDropdownField<String>(
    key: Key(key),
    label: title,
    value: value,
    enabled: !saving,
    items: [
      PokeMapDropdownItem(
        value: '',
        label: optional ? 'Toujours disponible' : 'Choisir une variable',
      ),
      for (final fact in widget.project.facts.where(
        (f) => f.valueKind == NarrativeValueKind.boolean,
      ))
        PokeMapDropdownItem(value: fact.id, label: fact.label),
    ],
    onChanged: (id) => setState(() => onChanged(id)),
  );

  Widget scenePicker(
    String key,
    String title,
    String value,
    ValueChanged<String> onChanged,
  ) => PokeMapDropdownField<String>(
    key: Key(key),
    label: title,
    value: value,
    enabled: !saving,
    items: [
      const PokeMapDropdownItem(value: '', label: 'Choisir une conversation'),
      for (final scene in widget.project.scenes)
        PokeMapDropdownItem(value: scene.id, label: scene.name),
    ],
    onChanged: (id) => setState(() => onChanged(id)),
  );

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      PokeMapToggleTile(
        key: const Key('contact-device-enabled'),
        label: 'Appareil de contacts',
        description:
            'L’appareil apparaît dans le menu après son acquisition. Les contacts et leur disponibilité suivent les variables de l’histoire.',
        value: enabled,
        onChanged: (value) => setState(() => enabled = value),
      ),
      if (enabled) ...[
        const SizedBox(height: 12),
        PokeMapTextField(
          label: 'Nom de l’appareil',
          controller: label,
          fieldKey: const Key('contact-device-label'),
          enabled: !saving,
        ),
        const SizedBox(height: 12),
        factPicker(
          'contact-device-acquired',
          'Variable d’acquisition',
          acquiredFact,
          (id) => acquiredFact = id,
        ),
        const SizedBox(height: 12),
        PokeMapTextField(
          label: 'Message sans contact',
          controller: empty,
          enabled: !saving,
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < contacts.length; i++) ...[
          PokeMapPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PokeMapTextField(
                  label: 'Nom du contact',
                  controller: contacts[i].label,
                  fieldKey: Key('contact-label-$i'),
                  enabled: !saving,
                ),
                const SizedBox(height: 10),
                factPicker(
                  'contact-registered-$i',
                  'Variable d’enregistrement',
                  contacts[i].registeredFact,
                  (id) => contacts[i].registeredFact = id,
                ),
                const SizedBox(height: 10),
                factPicker(
                  'contact-available-$i',
                  'Variable de disponibilité',
                  contacts[i].availableFact,
                  (id) => contacts[i].availableFact = id,
                  optional: true,
                ),
                const SizedBox(height: 10),
                scenePicker(
                  'contact-scene-$i',
                  'Conversation disponible',
                  contacts[i].scene,
                  (id) => contacts[i].scene = id,
                ),
                const SizedBox(height: 10),
                scenePicker(
                  'contact-unavailable-$i',
                  'Réponse si indisponible',
                  contacts[i].unavailable,
                  (id) => contacts[i].unavailable = id,
                ),
                const SizedBox(height: 10),
                PokeMapDropdownField<String>(
                  label: 'Portrait du personnage',
                  value: contacts[i].character,
                  enabled: !saving,
                  items: [
                    const PokeMapDropdownItem(
                      value: '',
                      label: 'Aucun portrait',
                    ),
                    for (final character in widget.project.characters)
                      PokeMapDropdownItem(
                        value: character.id,
                        label: character.name,
                      ),
                  ],
                  onChanged: (id) => setState(() => contacts[i].character = id),
                ),
                const SizedBox(height: 10),
                PokeMapButton(
                  variant: PokeMapButtonVariant.secondary,
                  onPressed: saving
                      ? null
                      : () => setState(() {
                          contacts.removeAt(i).label.dispose();
                        }),
                  child: const Text('Retirer ce contact'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        PokeMapButton(
          key: const Key('contact-device-add'),
          variant: PokeMapButtonVariant.secondary,
          onPressed: saving
              ? null
              : () => setState(() {
                  var index = contacts.length + 1;
                  while (contacts.any((c) => c.id == 'contact-$index')) {
                    index++;
                  }
                  contacts.add(_ContactDraft('contact-$index'));
                }),
          leading: const Icon(Icons.person_add_outlined),
          child: const Text('Ajouter un contact'),
        ),
      ],
      if (message != null) ...[
        const SizedBox(height: 12),
        PokeMapBadge(label: message!),
      ],
      const SizedBox(height: 12),
      PokeMapButton(
        key: const Key('contact-device-save'),
        onPressed: saving ? null : save,
        child: Text(saving ? 'Enregistrement…' : 'Enregistrer l’appareil'),
      ),
    ],
  );
}

final class _ContactDraft {
  _ContactDraft(this.id) : label = TextEditingController();
  _ContactDraft.from(ProjectContactEntryConfig entry)
    : id = entry.id,
      label = TextEditingController(text: entry.label),
      registeredFact = entry.registeredFactId,
      availableFact = entry.availableFactId ?? '',
      scene = entry.sceneId,
      unavailable = entry.unavailableSceneId,
      character = entry.characterId ?? '';
  final String id;
  final TextEditingController label;
  String registeredFact = '';
  String availableFact = '';
  String scene = '';
  String unavailable = '';
  String character = '';
  ProjectContactEntryConfig build() => ProjectContactEntryConfig(
    id: id,
    label: label.text.trim(),
    registeredFactId: registeredFact,
    availableFactId: availableFact.isEmpty ? null : availableFact,
    sceneId: scene,
    unavailableSceneId: unavailable,
    characterId: character.isEmpty ? null : character,
  );
}
