import 'dart:typed_data';

import 'package:map_core/map_core_domain.dart';

import '../../resources/domain/resource_port.dart';

abstract interface class DialoguePort {
  Future<DialogueSourceSnapshot> load(String id);

  Future<DialoguePublicationReceipt> publish({
    required String id,
    required DialogueSourceSnapshot? base,
    required ProjectDialogueEntry? entry,
    required String? source,
  });
}

abstract interface class DialoguePortraitPort {
  Future<Uint8List?> readPortrait(String characterId, String stateId);
}

class DialogueSourceSnapshot {
  const DialogueSourceSnapshot({
    required this.entry,
    required this.source,
    required this.revision,
  });

  final ProjectDialogueEntry entry;
  final String source;
  final String revision;
}

class DialoguePublicationReceipt {
  const DialoguePublicationReceipt({
    required this.resources,
    required this.snapshot,
  });

  final ResourceMutationReceipt resources;
  final DialogueSourceSnapshot? snapshot;
}

class DialogueFailure implements Exception {
  const DialogueFailure(this.message, {this.details = const {}});

  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => message;
}
