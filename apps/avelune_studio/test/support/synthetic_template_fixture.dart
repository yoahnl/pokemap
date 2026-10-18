import 'package:map_authoring/map_authoring_local.dart';

import '../../../../packages/map_authoring/test/support/project_template_fixture.dart';

final syntheticTemplates = [
  SyntheticProjectTemplate(id: 'alpha', tileSize: 16, width: 12, height: 10),
  SyntheticProjectTemplate(id: 'beta', tileSize: 48, width: 9, height: 7),
];
final fixtureTemplateCatalog = ProjectTemplateCatalog.fromJson({
  'schemaVersion': 1,
  'templates': [for (final fixture in syntheticTemplates) fixture.descriptor],
});
ProjectTemplateDescriptor get syntheticDescriptor =>
    fixtureTemplateCatalog.require('alpha');
final offlineProjectCreation = LocalProjectCreationService(
  templateCatalog: fixtureTemplateCatalog,
  readTemplate: readSyntheticTemplate,
);

Future<List<int>> readSyntheticTemplate(Uri uri) async {
  for (final fixture in syntheticTemplates) {
    final descriptor = fixture.catalog.templates.single;
    if (uri == descriptor.archiveUri) return fixture.archive;
    if (uri == descriptor.previewUri) return fixture.preview;
  }
  throw StateError('Unexpected synthetic template URL: $uri');
}

final workspaceTemplate = SyntheticProjectTemplate(
  id: 'workspace',
  tileSize: 32,
  width: 32,
  height: 26,
);
final workspaceProjectCreation = LocalProjectCreationService(
  templateCatalog: workspaceTemplate.catalog,
  readTemplate: (uri) async {
    final descriptor = workspaceTemplate.catalog.templates.single;
    if (uri == descriptor.archiveUri) return workspaceTemplate.archive;
    if (uri == descriptor.previewUri) return workspaceTemplate.preview;
    throw StateError('Unexpected synthetic workspace URL: $uri');
  },
);
