import 'package:flutter_test/flutter_test.dart';
import 'package:flame_3d/core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/spatial_light_behavior.dart';
import 'package:map_render_3d/src/spatial_firefly_lighting.dart';
import 'package:map_render_3d/src/spatial_point_light.dart';
import 'package:map_render_3d/src/spatial_environment_lighting.dart';

void main() {
  test('proximity uses hysteresis, smooth fades, pause, inverse mode and reset', () {
    final state=SpatialLightProximityState();
    final rule=ModelLightProximity(enterDistance:3,exitDistance:4,fadeSeconds:1);
    double sample(double distance,double time,{ModelLightProximity? config})=>state.sample(rule:config??rule,distanceSquared:distance*distance,elapsedSeconds:time);
    expect(sample(5,0),0);
    expect(sample(2,.25),.25);
    expect(sample(3.5,.5),.5);
    expect(sample(3.5,.5),.5);
    expect(sample(3.9,1),1);
    expect(sample(4.1,1.25),.75);
    expect(sample(3.5,1.5),.5);
    expect(sample(5,2),0);
    expect(sample(5,0,config:ModelLightProximity(mode:ModelLightProximityMode.far)),1);
    expect(state.sample(rule:null,distanceSquared:25,elapsedSeconds:0),1);
  });
  test('cycles follow the supplied simulation time and compose with daylight and proximity', () {
    final light=Model3dPointLight(localPosition:Model3dVector3.zero,intensity:2,
      colorCycle:ModelLightColorCycle(colors:[0xff0000,0x0000ff],periodSeconds:8));
    final sample=spatialPlacedPointLight(light,Matrix4.identity(),daylight:.5,proximityStrength:.5,elapsedSeconds:4);
    expect(sample.color.toARGB32()&0xffffff,0x0000ff);
    expect(sample.intensity,.5);
  });
  test('firefly illumination stays in two slots and fades when selection changes', () {
    final budget=SpatialFireflyLightBudget();
    SpatialPointLight light(double x)=>SpatialPointLight(position:(x:x,y:.5,z:0),radius:1,intensity:1);
    final candidates=[for(var i=0;i<16;i++)(i,light(i.toDouble()))];
    expect(budget.sample(candidates,Vector3.zero(),0),hasLength(2));
    expect(budget.sample(candidates,Vector3.zero(),.3).every((v)=>v.intensity==1),isTrue);
    final moving=budget.sample(candidates,Vector3(15,0,0),.45);
    expect(moving,hasLength(2));
    expect(moving.first.intensity,closeTo(.5,1e-9));
    expect(budget.sample(candidates,Vector3(15,0,0),.45).first.intensity,closeTo(.5,1e-9));
    expect(budget.sample([],Vector3.zero(),.5),isEmpty);
  });
}
