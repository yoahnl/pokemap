import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('actual converted Route9 cardinal collision graph matches the source oracle', () async {
    final qualification = jsonDecode(await File(Platform.environment['AC12_QUALIFICATION']!).readAsString()) as Map;
    final oracle = jsonDecode(await File(Platform.environment['AC12_ORACLE']!).readAsString()) as Map;
    final native = (qualification['nativeMaps'] as List).single as Map;
    final projectFile = '${qualification['projectPath']}/project.json';
    final bundle = await loadRuntimeMapBundle(projectFilePath: projectFile, mapId: native['id'] as String);
    final map = bundle.map;
    final manifest = bundle.manifest;
    expect(map.size.width, 72); expect(map.size.height, 61);
    expect(map.placedElements, isNotEmpty);
    final rawMap = ProjectManifest.fromJson(jsonDecode(await File(projectFile).readAsString()));
    expect(manifest.characters.single.id, rawMap.characters.single.id);
    expect(manifest.characters.single.frameWidth, 2);
    expect(manifest.characters.single.frameHeight, 2);
    final source = (oracle['maps'] as List).single as Map;
    final statuses = source['statuses'] as List;
    expect(statuses.length, 72 * 61 * 4);
    const directions = [Direction.south, Direction.west, Direction.east, Direction.north];
    final base = GameplayWorldState.initial(map: map, project: manifest,
        playerPos: const GridPos(x:35,y:22), tileWidth:32, tileHeight:32);
    final failures = <Map<String,Object?>>[];
    final counts = <String,int>{'allowed':0,'blocked':0,'unqualifiedClosed':0};
    var index = 0;
    for (var y=0; y<61; y++) {
      for (var x=0; x<72; x++) {
        final start = GridPos(x:x,y:y);
        final world = base.withPlayer(GameplayPlayerState.fromGridSpawn(
            cell:start, facing:Direction.south, tileWidthPx:32, tileHeightPx:32,
            mapWidthCells:72,mapHeightCells:61));
        for (final direction in directions) {
          final status = statuses[index++] as String;
          final result = stepGameplayWorld(world, MoveIntent(direction,pixelsPerStep:32));
          final target = GridPos(x:x+direction.dx,y:y+direction.dy);
          final fullStep = result.world.player.pos == target;
          final expectedStep = status == 'allowed';
          final kind = status == 'unqualified' ? 'unqualifiedClosed' : status;
          counts[kind] = counts[kind]! + 1;
          if (fullStep != expectedStep && failures.length < 64) {
            failures.add({'x':x,'y':y,'direction':direction.name,'source':status,
              'nativeResult':result.runtimeType.toString(),
              'nativeGrid':result.world.player.pos.toJson(),
              'nativePixel':[result.world.player.playerPositionPx.leftPx,result.world.player.playerPositionPx.topPx]});
          }
        }
      }
    }
    final record = {'kind':'actualNativeCollisionGraphProbe','sourceQualification':Platform.environment['AC12_QUALIFICATION'],
      'projectPath':qualification['projectPath'],'nativeMapId':map.id,
      'sourceMapId':98,'arcs':statuses.length,'counts':counts,'failures':failures,
      'projectDataEnriched':false,'sourceScriptsExecuted':0,'aiCalls':0,
      'nativeContactPolicy':'12x8 swept pixel resolver from aligned cells',
      'sourceUnqualifiedCertified':false,'passed':failures.isEmpty};
    await File(Platform.environment['AC12_COLLISION_RECEIPT']!).writeAsString(jsonEncode(record),flush:true);
    expect(failures,isEmpty,reason:jsonEncode(failures));
  }, timeout: const Timeout(Duration(minutes:2)));
}
