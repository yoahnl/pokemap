import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dialogues/domain/dialogue_port.dart';
import '../../features/project_session/domain/project_session.dart';

final dialoguePortProvider = Provider.autoDispose
    .family<DialoguePort?, ProjectSession>((ref, session) => null);
