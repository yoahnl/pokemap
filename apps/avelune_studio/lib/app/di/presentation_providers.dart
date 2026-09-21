import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/presentations/domain/presentation_port.dart';
import '../../features/project_session/domain/project_session.dart';
import '../../features/verification/domain/verification_port.dart';
import '../../features/world/domain/world_port.dart';
import '../../presentation/features/presentations/presentation_media_picker.dart';

final presentationMediaPickerProvider = Provider<PickPresentationMedia>(
  (ref) =>
      (_) async => null,
);

final presentationPortProvider = Provider.autoDispose
    .family<PresentationPort?, ProjectSession>((ref, session) => null);

final worldPortProvider = Provider.autoDispose
    .family<WorldPort?, ProjectSession>((ref, session) => null);

final verificationPortProvider = Provider.autoDispose
    .family<VerificationPort?, ProjectSession>((ref, session) => null);
