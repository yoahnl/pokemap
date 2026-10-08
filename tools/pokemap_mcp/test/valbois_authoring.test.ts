import assert from "node:assert/strict";
import test from "node:test";
import { actors, connections, encounterAreas, passages, surplusPaintedCells, worldPlan } from "../tool/author_valbois_demo.js";

test("native layout refresh removes obsolete path cells without touching its intended cells", () => {
  assert.deepEqual(surplusPaintedCells([0, 1, 1, 0, 1, 0], 3, [{ x: 1, y: 0 }]), [{ x: 2, y: 0 }, { x: 1, y: 1 }]);
  assert.deepEqual(surplusPaintedCells([0, 1, 0], 3, [{ x: 1, y: 0 }]), []);
});

test("Valbois native recipe defines exactly six compact independent maps", () => {
  const maps = worldPlan();
  assert.equal(maps.length, 6);
  assert.equal(new Set(maps.map(map => map.id)).size, 6);
  assert.equal(maps.filter(map => map.interior).length, 2);
  for (const map of maps) {
    assert.ok(map.width <= 30 && map.height <= 24);
    assert.ok(map.spawn.x >= 0 && map.spawn.x < map.width);
    assert.ok(map.spawn.y >= 0 && map.spawn.y < map.height);
    for (const cell of [...map.paths, ...map.grass]) assert.ok(cell.x >= 0 && cell.x < map.width && cell.y >= 0 && cell.y < map.height);
    for (const block of map.blocks) assert.ok(block.x >= 0 && block.z >= 0 && block.x + block.width <= map.width && block.z + block.depth <= map.height);
    for (const [index, block] of map.blocks.entries()) for (const other of map.blocks.slice(index + 1)) {
      assert.ok(block.x + block.width <= other.x || other.x + other.width <= block.x || block.z + block.depth <= other.z || other.z + other.depth <= block.z);
    }
    assert.ok(!map.blocks.some(block => map.spawn.x >= block.x && map.spawn.x < block.x + block.width && map.spawn.y >= block.z && map.spawn.y < block.z + block.depth));
    assert.equal(new Set(map.instances.map(value => value.id)).size, map.instances.length);
  }
});

test("exterior edge paths join at the correct signed offsets", () => {
  const maps = worldPlan();
  for (const connection of connections) {
    const source = maps.find(map => map.id === connection.mapId)!;
    const target = maps.find(map => map.id === connection.targetMapId)!;
    const exits = source.paths.filter(cell => connection.direction === "north" ? cell.y === 0 : cell.x === source.width - 1);
    assert.equal(exits.length, 3);
    for (const cell of exits) {
      const arrival = connection.direction === "north"
        ? { x: cell.x - connection.offset, y: target.height - 1 }
        : { x: 0, y: cell.y - connection.offset };
      assert.ok(target.paths.some(path => path.x === arrival.x && path.y === arrival.y), JSON.stringify(connection));
      assert.ok(!target.blocks.some(block => arrival.x >= block.x && arrival.x < block.x + block.width && arrival.y >= block.z && arrival.y < block.z + block.depth));
    }
  }
});

test("interior passages and named actors have reachable native positions", () => {
  const maps = worldPlan();
  for (const passage of passages) {
    for (const [id, position] of [[passage.mapId, passage.warp.pos], [passage.warp.targetMapId, passage.warp.targetPos]] as const) {
      const map = maps.find(value => value.id === id)!;
      assert.ok(position.x >= 0 && position.x < map.width && position.y >= 0 && position.y < map.height);
      assert.ok(!map.blocks.some(block => position.x >= block.x && position.x < block.x + block.width && position.y >= block.z && position.y < block.z + block.depth));
    }
  }
  for (const actor of actors) {
    const map = maps.find(value => value.id === actor.mapId)!;
    assert.ok(actor.x >= 0 && actor.y >= 0 && actor.x < map.width && actor.y < map.height);
    assert.ok(!map.blocks.some(block => actor.x >= block.x && actor.x < block.x + block.width && actor.y >= block.z && actor.y < block.z + block.depth), actor.id);
  }
});

test("encounter regions match visible tall grass and terrain has one accessible ramp", () => {
  const maps = worldPlan();
  for (const area of encounterAreas) {
    const map = maps.find(value => value.id === area.mapId)!;
    assert.equal(map.grass.filter(cell => cell.x >= area.x && cell.x < area.x + area.width && cell.y >= area.y && cell.y < area.y + area.height).length, area.width * area.height);
    assert.ok(!map.grass.some(cell => map.blocks.some(block => cell.x >= block.x && cell.x < block.x + block.width && cell.y >= block.z && cell.y < block.z + block.depth)));
  }
  const meadow = maps.find(map => map.id === "valbois-meadow")!;
  assert.equal(meadow.ramps.length, 1);
  assert.ok(meadow.levels.length > 0);
});

test("The healing room preserves a direct entrance-to-nurse corridor", () => {
  const care = worldPlan().find(map => map.id === "valbois-care")!;
  for (const y of [3, 4, 5, 6]) assert.ok(!care.blocks.some(block => 5 >= block.x && 5 < block.x + block.width &&
    y >= block.z && y < block.z + block.depth));
  const table = care.instances.find(value => value.id === "care-table")!;
  assert.deepEqual(table.position, { x: 7.5, y: 0, z: 3.5 });
  assert.equal(table.scale, 1.4);
});

test("Lina stands clear of the authentic greenhouse facade and leaves the garden path free", () => {
  const village = worldPlan().find(map => map.id === "first-map")!;
  const gardener = actors.find(actor => actor.id === "valbois-gardener")!;
  const greenhouse = village.instances.find(instance => instance.id === "village-greenhouse")!;
  const position = greenhouse.position as { x: number; y: number; z: number };
  const greenhouseMinX = position.x - 3.751953125 * Number(greenhouse.scale);
  assert.deepEqual([gardener.x, gardener.y], [17, 16]);
  assert.ok(gardener.x + 1 < greenhouseMinX);
  assert.ok(!village.paths.some(cell => cell.x === gardener.x && cell.y === gardener.y));
  assert.ok(!village.blocks.some(area => gardener.x < area.x + area.width && gardener.x + 1 > area.x &&
    gardener.y < area.z + area.depth && gardener.y + 1 > area.z));
});
