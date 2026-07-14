import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'border_feature.dart';

/// Persisted authored content of one dedicated Border layer.
///
/// This value contains only Border feature intent and explicit materialization.
/// Map layer metadata and runtime generation are deliberately outside this
/// model.
@immutable
final class BorderLayerContent {
  static const int formatVersionV1 = 1;
  static const int currentFormatVersion = formatVersionV1;

  /// Canonical content for a Border layer that has not been drawn yet.
  static const BorderLayerContent emptyContent = BorderLayerContent._(
    formatVersion: currentFormatVersion,
    features: <BorderFeature>[],
  );

  BorderLayerContent({
    this.formatVersion = currentFormatVersion,
    List<BorderFeature> features = const <BorderFeature>[],
  }) : _features = List<BorderFeature>.unmodifiable(features) {
    if (formatVersion != currentFormatVersion) {
      throw ValidationException(
        'BorderLayerContent.formatVersion must be $currentFormatVersion',
      );
    }

    final seenIds = <String>{};
    for (final feature in _features) {
      if (!seenIds.add(feature.id)) {
        throw ValidationException(
          'BorderLayerContent.features must not contain duplicate ids: '
          '${feature.id}',
        );
      }
    }
  }

  const BorderLayerContent._({
    required this.formatVersion,
    required List<BorderFeature> features,
  }) : _features = features;

  final int formatVersion;
  final List<BorderFeature> _features;

  /// Features in authored order.
  List<BorderFeature> get features => _features;

  bool get isEmpty => _features.isEmpty;

  int get featureCount => _features.length;

  /// Returns the feature matching [id] exactly, or `null` when absent.
  BorderFeature? featureById(String id) {
    for (final feature in _features) {
      if (feature.id == id) {
        return feature;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderLayerContent &&
          formatVersion == other.formatVersion &&
          _listsEqual(_features, other._features);

  @override
  int get hashCode => Object.hash(formatVersion, Object.hashAll(_features));
}

bool _listsEqual<T>(List<T> first, List<T> second) {
  if (identical(first, second)) {
    return true;
  }
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}
