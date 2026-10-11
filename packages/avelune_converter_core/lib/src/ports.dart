part of '../avelune_converter_core.dart';

abstract interface class ConverterClock {
  DateTime now();
}

abstract interface class SourceMapReaderPort {
  Future<SourceMapIr> readMap(SourceIdentity identity);
}

abstract interface class SourceFilePort {
  Future<List<int>> read(ConverterId fileId);
}

abstract interface class RasterPort {
  Future<List<int>> compose(AssetCandidate candidate);
}

abstract interface class SessionStoragePort {
  Future<ConversionSession?> load(ConverterId sessionId);
  Future<void> save(ConversionSession session);
}

abstract interface class VisionPort {
  Future<VisionResponse> suggest(VisionRequestContext request);
}
