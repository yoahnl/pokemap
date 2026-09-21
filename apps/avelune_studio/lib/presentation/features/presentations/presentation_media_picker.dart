import 'package:map_core/map_core_domain.dart';

typedef PickPresentationMedia =
    Future<({String path, String label})?> Function(ProjectMediaKind kind);
