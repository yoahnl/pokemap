import 'package:map_core/map_core_domain.dart';

bool studioPublicationAvailable(ProjectDimension? dimension) =>
    dimension != null && dimension != ProjectDimension.threeD;

class StudioGameExportModeSelection {
  StudioGameExportModeSelection({required this.publicationAvailable})
    : _publication = publicationAvailable;

  final bool publicationAvailable;
  bool _publication;
  bool get publication => _publication;

  bool selectPublication(bool value, {required bool operationActive}) {
    if (operationActive || (value && !publicationAvailable)) return false;
    _publication = value;
    return true;
  }
}
