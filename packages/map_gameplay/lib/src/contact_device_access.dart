import 'package:map_core/map_core.dart';

final class ContactDeviceAccess {
  ContactDeviceAccess._(
      this.configuration, this.isAcquired, this.contacts, this._read);

  factory ContactDeviceAccess.resolve(
      {required ProjectManifest project, required GameState state}) {
    final configuration = project.contactDevice;
    final definitions = {for (final fact in project.facts) fact.id: fact};
    bool read(String id) {
      final definition = definitions[id];
      if (definition?.valueKind != NarrativeValueKind.boolean) return false;
      final value = state.narrativeFactRuntimeState.valueFor(id) ??
          definition!.initialValue;
      return value.kind == NarrativeValueKind.boolean && value.boolValue;
    }

    final acquired =
        configuration != null && read(configuration.acquiredFactId);
    final contacts = acquired
        ? configuration.contacts
            .where((c) => read(c.registeredFactId))
            .toList(growable: false)
        : <ProjectContactEntryConfig>[];
    return ContactDeviceAccess._(
        configuration, acquired, List.unmodifiable(contacts), read);
  }

  final ProjectContactDeviceConfig? configuration;
  final bool isAcquired;
  final List<ProjectContactEntryConfig> contacts;
  final bool Function(String) _read;

  String sceneForContact(String id) {
    final matches = contacts.where((c) => c.id == id);
    if (!isAcquired || matches.length != 1)
      throw StateError('The device or requested contact is unavailable.');
    final contact = matches.single;
    return contact.availableFactId == null || _read(contact.availableFactId!)
        ? contact.sceneId
        : contact.unavailableSceneId;
  }
}
