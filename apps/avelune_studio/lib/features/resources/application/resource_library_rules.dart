import 'package:map_core/map_core_domain.dart';

import 'resource_catalog.dart';
import 'resource_category_tree.dart';

bool resourceLibraryRegular({
  required bool atelierVisible,
  required ResourceLibraryFamily family,
}) =>
    !atelierVisible ||
    (family != ResourceLibraryFamily.borders &&
        family != ResourceLibraryFamily.models3d &&
        family != ResourceLibraryFamily.environments);

String? resourceLibraryFamilyName(ProjectManifest project, String familyId) =>
    familyId == unclassifiedResourceFamily
    ? 'Sans famille'
    : project.resourceLibraryCatalog.effectiveFamilies
          .where((family) => family.id == familyId)
          .firstOrNull
          ?.name;

String? resourceLibraryCategoryName({
  required bool atelierVisible,
  required String category,
  required ResourceCategoryTree tree,
}) => !atelierVisible || category.isEmpty
    ? null
    : category == uncategorizedResourceCategory
    ? 'Sans catégorie'
    : tree.nodes.where((node) => node.id == category).firstOrNull?.name;
