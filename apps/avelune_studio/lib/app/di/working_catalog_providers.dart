import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/project_session/domain/project_session.dart';
import '../../features/resources/application/working_catalog_controller.dart';
import '../../features/resources/data/local_working_catalog_adapter.dart';

final workingCatalogControllerProvider = Provider.autoDispose
    .family<WorkingCatalogController, ProjectSession>((ref, session) {
      final controller = WorkingCatalogController(
        LocalWorkingCatalogAdapter(session),
        recoveryOperationIds: session.recoveryOperationIds,
      );
      ref.onDispose(controller.dispose);
      return controller;
    });
