import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:map_core/map_core.dart';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/glb_fixture.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  test('inspects explicit MASK cutoff and RGB/RGBA float vertex colors', () {
    for (final width in [3, 4]) {
      final result =
          const GlbModel3dInspector().inspect(coloredGlb(width: width));
      expect(result.materials.single.toJson()['alphaMode'], 'mask');
      expect(result.materials.single.toJson()['alphaCutoff'], .5);
      expect(result.diagnostics, isNot(contains('renderer.ignored_color_0')));
      expect(result.triangleCount, 1);
    }
  });
  for (final change in <String, void Function(Map<String, dynamic>)>{
    'missing cutoff': (j) => j['materials'][0].remove('alphaCutoff'),
    'other cutoff': (j) => j['materials'][0]['alphaCutoff'] = .1,
    'BLEND': (j) => j['materials'][0]['alphaMode'] = 'BLEND',
    'invalid double sided': (j) => j['materials'][0]['doubleSided'] = 'true',
    'integer color': (j) => j['accessors'][1]['componentType'] = 5123,
    'normalized float': (j) => j['accessors'][1]['normalized'] = true,
    'wrong color width': (j) => j['accessors'][1]['type'] = 'VEC2',
    'wrong color count': (j) => j['accessors'][1]['count'] = 2,
    'COLOR_1': (j) =>
        j['meshes'][0]['primitives'][0]['attributes']['COLOR_1'] = 1,
  }.entries) {
    test('rejects ${change.key}', () {
      expect(
          () => const GlbModel3dInspector()
              .inspect(coloredGlb(edit: change.value)),
          throwsFormatException);
    });
  }
  test('preserves explicit two sided OPAQUE and MASK inspection metadata', () {
    for (final mode in ['OPAQUE', 'MASK']) {
      final result = const GlbModel3dInspector().inspect(coloredGlb(edit: (j) {
        j['materials'][0]['alphaMode'] = mode;
        j['materials'][0]['doubleSided'] = true;
        if (mode == 'OPAQUE') j['materials'][0].remove('alphaCutoff');
      }));
      expect(result.materials.single.toJson()['doubleSided'], true);
    }
  });
  test(
      'exports and inspects MASK two sided metadata with its native model bytes',
      () {
    final bytes =
        coloredGlb(edit: (j) => j['materials'][0]['doubleSided'] = true);
    final built = const GamePackageBuilder().build(
        manifest: spatialManifest(),
        payloadFiles: spatialPayload(modelBytes: bytes));
    const GamePackageInspector().inspect(built.packageBytes);
    final archive = ZipDecoder().decodeBytes(built.packageBytes);
    final project = ProjectManifest.fromJson(jsonDecode(utf8.decode(
            archive.findFile('project/project.json')!.content as List<int>))
        as Map<String, dynamic>);
    final material = project.models3d.single.inspection.materials.single;
    expect(material.alphaMode, Model3dAlphaMode.mask);
    expect(material.alphaCutoff, .5);
    expect(material.doubleSided, true);
    expect(
        archive.findFile('project/assets/models3d/model.glb')!.content, bytes);
  });
  for (final value in [-.1, 1.1, double.nan]) {
    test('rejects vertex color outside finite normalized range $value', () {
      expect(
          () => const GlbModel3dInspector().inspect(coloredGlb(color: value)),
          throwsFormatException);
    });
  }
  test('validates each native wrap axis without rewriting PNG bytes', () {
    for (final wrap in [10497, 33648, 33071]) {
      final result = const GlbModel3dInspector().inspect(coloredGlb(edit: (j) {
        j['samplers'] = [
          {'wrapS': wrap, 'wrapT': wrap}
        ];
      }));
      expect(result.triangleCount, 1);
    }
    expect(
        () => const GlbModel3dInspector().inspect(coloredGlb(edit: (j) {
              j['samplers'] = [
                {'wrapS': 123, 'wrapT': 10497}
              ];
            })),
        throwsFormatException);
  });
  final fixtures = Platform.environment['AVELUNE_BW2_FIXTURES'];
  if (fixtures != null) {
    test('inspects every authentic BW2 model through the native GLB profile',
        () {
      final files = Directory(fixtures)
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.glb'))
          .toList();
      expect(files, isNotEmpty);
      for (final file in files) {
        final result =
            const GlbModel3dInspector().inspect(file.readAsBytesSync());
        expect(result.triangleCount, greaterThan(0));
        expect(result.diagnostics, isNot(contains('renderer.ignored_color_0')));
      }
      print('BW2 inspected model count: ${files.length}');
    });
  }
}
