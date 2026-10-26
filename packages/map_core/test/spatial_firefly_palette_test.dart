import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('legacy atmosphere and visual documents keep old schema and default colors', () {
    final settings=SpatialAtmosphereSettings();
    expect(settings.hasFireflyStyle,isFalse);
    expect(settings.toJson().containsKey('fireflyLighting'),isFalse);
    expect(SpatialAtmosphereDocument(mapId:'village',settings:settings).toJson()['schemaVersion'],2);
    expect(spatialFireflyColor(seed:7,index:1),SpatialFireflyColor.yellow);
    expect(SpatialVisualDocument(profile:SpatialVisualPatch()).toJson()['schemaVersion'],1);
  });
  test('palette is stable, covers all four colors and keeps the shared count budget', () {
    final colors=[for(var i=0;i<128;i++) spatialFireflyColor(seed:7,index:i,yellow:1,green:1,blue:1,pink:1)];
    expect(colors.toSet(),SpatialFireflyColor.values.toSet());
    expect(colors,[for(var i=0;i<128;i++) spatialFireflyColor(seed:7,index:i,yellow:1,green:1,blue:1,pink:1)]);
    expect(spatialFireflyColor(seed:7,index:1,yellow:0),isNull);
    expect(spatialFireflyColor(seed:7,index:1,yellow:0,blue:1),SpatialFireflyColor.blue);
  });
  test('extended style round trips and is refused in an older document schema', () {
    final settings=SpatialAtmosphereSettings(fireflyLighting:true,fireflyGreenAmount:.5,fireflyBlueAmount:.7);
    final doc=SpatialAtmosphereDocument(mapId:'village',settings:settings);
    expect(doc.toJson()['schemaVersion'],3);
    expect(SpatialAtmosphereDocument.fromJson(doc.toJson()).settings,settings);
    expect(() => SpatialAtmosphereDocument.fromJson({...doc.toJson(),'schemaVersion':2}),throwsFormatException);
    final patch=SpatialVisualPatch.fromJson({'fireflyLighting':true,'fireflyPinkAmount':.8});
    final visual=SpatialVisualDocument(profile:patch);
    expect(visual.toJson()['schemaVersion'],2);
    expect(SpatialVisualDocument.fromJson(visual.toJson()).profile,patch);
    expect(() => SpatialVisualDocument.fromJson({...visual.toJson(),'schemaVersion':1}),throwsFormatException);
    final changed=patch.applyAtmosphere(settings);
    expect(changed.fireflyGreenAmount,.5);
    expect(changed.fireflyPinkAmount,.8);
    expect(() => SpatialAtmosphereSettings(fireflyLightStrength:double.nan),throwsFormatException);
    expect(() => SpatialVisualPatch.fromJson({'fireflyLightRadius':-1}),throwsFormatException);
  });
}
