import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';
import 'support/spatial_package_fixture.dart';

void main() {
  test('audible fire declares its capability while silent flames remain compatible', () {
    final files = spatialPayload();
    final project = ProjectManifest.fromJson(jsonDecode(utf8.decode(files['project/project.json']!)));
    final light = Model3dPointLight(localPosition: Model3dVector3.zero,
      flame: ModelLightFlame(style: ModelLightFlameStyle.brazier, crackleVolume: .65));
    files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(
      models3d: [project.models3d.first.copyWith(light: light), ...project.models3d.skip(1)]).toJson()));
    final caps = ['map3d@1', SpatialSceneLightingCapabilities.pointLightCapabilityId, SpatialLightWorkshopCapabilities.flameCapabilityId];
    expect(() => const GamePackageBuilder().build(manifest: spatialManifest(capabilities: caps), payloadFiles: files),
      throwsA(isA<GamePackageFormatException>().having((e) => e.message, 'sound capability', contains('map3d.light-crackle@1'))));
    final built = const GamePackageBuilder().build(manifest: spatialManifest(capabilities: [...caps, SpatialLightWorkshopCapabilities.crackleCapabilityId]), payloadFiles: files);
    expect(const GamePackageInspector().inspect(built.packageBytes).manifest.compatibility.requiredCapabilities, contains(SpatialLightWorkshopCapabilities.crackleCapabilityId));
  });
  test('flames require their own capability while legacy packages stay readable', () {
    final files = spatialPayload();
    final project = ProjectManifest.fromJson(jsonDecode(utf8.decode(files['project/project.json']!)));
    final models = project.models3d;
    final light = Model3dPointLight(localPosition: Model3dVector3(x: 0, y: 1, z: 0),
      flame: ModelLightFlame(style: ModelLightFlameStyle.brazier, embers: .75));
    files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(
      models3d: [models.first.copyWith(light: light), ...models.skip(1)]).toJson()));
    final base = ['map3d@1', SpatialSceneLightingCapabilities.pointLightCapabilityId];
    expect(() => const GamePackageBuilder().build(
      manifest: spatialManifest(capabilities: base), payloadFiles: files),
      throwsA(isA<GamePackageFormatException>().having((e) => e.message,
        'flame capability', contains('map3d.light-flame@1'))));
    final built = const GamePackageBuilder().build(
      manifest: spatialManifest(capabilities: [...base, 'map3d.light-flame@1']),
      payloadFiles: files);
    expect(const GamePackageInspector().inspect(built.packageBytes).manifest.compatibility.requiredCapabilities,
      contains('map3d.light-flame@1'));
  });

  test('extended visual documents require the explicit capability and remain readable', () {
    final files=spatialPayload();
    files['project/project.visual.json']=utf8.encode(jsonEncode(SpatialVisualDocument(
      profile:SpatialVisualPatch.fromJson({'fireflyLighting':true,'fireflyPinkAmount':.7})).toJson()));
    final base=['map3d@1',SpatialVisualDocument.capabilityId];
    expect(()=>const GamePackageBuilder().build(manifest:spatialManifest(capabilities:base),payloadFiles:files),
      throwsA(isA<GamePackageFormatException>().having((e)=>e.message,'capability',contains(SpatialLightWorkshopCapabilities.capabilityId))));
    final built=const GamePackageBuilder().build(manifest:spatialManifest(capabilities:[...base,SpatialLightWorkshopCapabilities.capabilityId]),payloadFiles:files);
    expect(const GamePackageInspector().inspect(built.packageBytes).manifest.compatibility.requiredCapabilities,
      contains(SpatialLightWorkshopCapabilities.capabilityId));
  });
  test('model cycles and proximity require the same capability without changing source data', () {
    final files=spatialPayload();
    final project=ProjectManifest.fromJson(jsonDecode(utf8.decode(files['project/project.json']!)));
    final models=project.models3d;
    expect(models,isNotEmpty);
    final light=Model3dPointLight(localPosition:Model3dVector3(x:0,y:1,z:0),
      colorCycle:ModelLightColorCycle(colors:[0xbddfff,0xf2c8e5]),proximity:ModelLightProximity());
    files['project/project.json']=utf8.encode(jsonEncode(project.copyWith(models3d:[models.first.copyWith(light:light),...models.skip(1)]).toJson()));
    final base=['map3d@1',SpatialSceneLightingCapabilities.pointLightCapabilityId];
    expect(()=>const GamePackageBuilder().build(manifest:spatialManifest(capabilities:base),payloadFiles:files),throwsA(isA<GamePackageFormatException>()));
    final built=const GamePackageBuilder().build(manifest:spatialManifest(capabilities:[...base,SpatialLightWorkshopCapabilities.capabilityId]),payloadFiles:files);
    expect(const GamePackageInspector().inspect(built.packageBytes).manifest.compatibility.requiredCapabilities,
      contains(SpatialLightWorkshopCapabilities.capabilityId));
  });
}
