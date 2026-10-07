import 'dart:typed_data';

import 'resource_port.dart';

abstract interface class ModelResourcePort {
  Future<ResourceMutationReceipt> importModel({
    required String sourcePath,
    required String name,
  });

  Future<Uint8List> readModel(String modelId);

  Future<ResourceMutationReceipt> deleteModel(String modelId);
}
