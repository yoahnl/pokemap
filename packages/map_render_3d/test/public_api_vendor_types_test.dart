import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:flutter_test/flutter_test.dart';

const _vendorLibraries = [
  'package:flame/',
  'package:flame_3d/',
  'package:flutter_gpu/',
];

void main() {
  late AnalysisContextCollection collection;

  setUpAll(() {
    collection = AnalysisContextCollection(
      includedPaths: [Directory('lib').absolute.path],
      sdkPath: _dartSdkPath(),
    );
  });

  test(
    'the adapter barrel exposes no Flame nor Flutter GPU type',
    () async {
      final exposure = await _vendorExposure(
        collection,
        'lib/map_render_3d.dart',
      );

      expect(exposure.exportedNames, greaterThan(0));
      expect(exposure.vendorTypes, isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'the check reports a library that leaks Flame types',
    () async {
      final exposure = await _vendorExposure(
        collection,
        'lib/src/model_playback.dart',
      );

      expect(
        exposure.vendorTypes,
        contains(startsWith('AnimatedModelComponent.model -> Model')),
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<({int exportedNames, List<String> vendorTypes})> _vendorExposure(
  AnalysisContextCollection collection,
  String relativePath,
) async {
  final path = File(relativePath).absolute.path;
  final result = await collection
      .contextFor(path)
      .currentSession
      .getResolvedLibrary(path);
  if (result is! ResolvedLibraryResult) {
    throw StateError('Unable to resolve $relativePath: $result');
  }
  final exported = result.element.exportNamespace.definedNames2;
  final hits = <String>{};
  for (final MapEntry(key: name, value: element) in exported.entries) {
    _collectElement(name, element, hits);
  }
  return (exportedNames: exported.length, vendorTypes: hits.toList()..sort());
}

void _collectElement(String name, Element element, Set<String> hits) {
  void type(DartType? value, String where) => _collectType(value, where, hits);
  switch (element) {
    case InterfaceElement():
      type(element.supertype, '$name extends');
      for (final value in element.interfaces) {
        type(value, '$name implements');
      }
      for (final value in element.mixins) {
        type(value, '$name with');
      }
      for (final parameter in element.typeParameters) {
        type(parameter.bound, '$name<${parameter.name}>');
      }
      for (final constructor in element.constructors) {
        if (constructor.isPrivate) continue;
        for (final parameter in constructor.formalParameters) {
          type(parameter.type, '$name(${constructor.name}).${parameter.name}');
        }
      }
      for (final field in element.fields) {
        if (!field.isPrivate) type(field.type, '$name.${field.name}');
      }
      for (final getter in element.getters) {
        if (!getter.isPrivate) type(getter.returnType, '$name.${getter.name}');
      }
      for (final method in element.methods) {
        if (method.isPrivate) continue;
        type(method.returnType, '$name.${method.name}()');
        for (final parameter in method.formalParameters) {
          type(parameter.type, '$name.${method.name}(${parameter.name})');
        }
      }
    case ExtensionElement():
      type(element.extendedType, 'extension $name on');
    case TopLevelFunctionElement():
      type(element.returnType, '$name()');
      for (final parameter in element.formalParameters) {
        type(parameter.type, '$name(${parameter.name})');
      }
    case TypeAliasElement():
      type(element.aliasedType, 'typedef $name');
    case TopLevelVariableElement():
      type(element.type, name);
    case GetterElement():
      type(element.returnType, name);
    default:
  }
}

void _collectType(DartType? value, String where, Set<String> hits) {
  if (value == null) return;
  final library = value.element?.library?.uri.toString() ?? '';
  if (_vendorLibraries.any(library.startsWith)) {
    hits.add('$where -> ${value.getDisplayString()} ($library)');
  }
  switch (value) {
    case InterfaceType():
      for (final argument in value.typeArguments) {
        _collectType(argument, where, hits);
      }
    case FunctionType():
      _collectType(value.returnType, where, hits);
      for (final parameter in value.formalParameters) {
        _collectType(parameter.type, where, hits);
      }
    case RecordType():
      for (final field in value.positionalFields) {
        _collectType(field.type, where, hits);
      }
      for (final field in value.namedFields) {
        _collectType(field.type, where, hits);
      }
    default:
  }
}

String _dartSdkPath() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final sdk = Directory('$flutterRoot/bin/cache/dart-sdk');
    if (sdk.existsSync()) return sdk.path;
  }
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.parent.path != directory.path) {
    final sdk = Directory('${directory.path}/dart-sdk');
    if (sdk.existsSync()) return sdk.path;
    directory = directory.parent;
  }
  throw StateError('Unable to locate the Dart SDK used by Flutter.');
}
