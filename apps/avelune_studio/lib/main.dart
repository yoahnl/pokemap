import 'dart:convert';

import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:map_authoring/map_authoring_project_creation.dart';

import 'package:avelune_studio/app/studio_bootstrap.dart';

Future<void> main() async {
  AveluneWidgetsFlutterBinding.ensureInitialized();
  final catalog = await loadStudioProjectTemplateCatalog();
  runApp(StudioBootstrap(templateCatalog: catalog));
}

Future<ProjectTemplateCatalog> loadStudioProjectTemplateCatalog() async =>
    ProjectTemplateCatalog.fromJson(
      jsonDecode(
        await rootBundle.loadString(
          '../../packages/map_authoring/assets/project_templates.v1.json',
        ),
      ),
    );
