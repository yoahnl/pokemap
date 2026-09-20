import 'package:map_core/map_core_domain.dart';
import '../../resources/domain/resource_port.dart';

class ScenePublicationReceipt {
  const ScenePublicationReceipt({required this.catalog, required this.scene});
  final ResourceMutationReceipt catalog;
  final SceneAsset scene;
}

abstract interface class ScenePort {
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  });
}

class SceneFailure implements Exception {
  const SceneFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
