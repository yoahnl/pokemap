import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_pack_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/resources/resource_image_import.dart';

final resourcePortProvider = Provider.autoDispose
    .family<ResourcePort, ProjectSession>(
      (ref, session) => throw StateError('Resource port must be configured'),
    );
final resourceImagePickerProvider = Provider<PickResourceImage>(
  (ref) => throw StateError('Resource image picker must be configured'),
);
final resourcePackPortProvider = Provider.autoDispose
    .family<ResourcePackPort?, ProjectSession>((ref, session) => null);
final resourcePackPickerProvider = Provider<PickResourcePack>(
  (ref) =>
      () async => null,
);

final resourcePackLicensePickerProvider = Provider<PickResourcePackLicenses>(
  (ref) =>
      () async => null,
);
final resourcePackExportSinkProvider = Provider<ResourcePackExportSink?>(
  (ref) => null,
);
