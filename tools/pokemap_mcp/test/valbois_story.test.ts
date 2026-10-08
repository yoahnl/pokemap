import assert from "node:assert/strict";
import { test } from "node:test";
import type { JsonRecord } from "../src/authoring_client.js";
import { guideCinematic, guideStagePoints, storyDoor, storyEvents, storyScenes, withStoryDoorNavigation } from "../tool/author_valbois_story.js";
import { questEvents, questIds } from "../tool/author_valbois_gameplay.js";

function record(value: unknown): JsonRecord { return value as JsonRecord; }

test("The doorway keeps the original building walls and only opens its real entrance", () => {
  const garden = { x: 19, z: 14, width: 8, depth: 3 };
  const before = { spawn: { x: 14.5, z: 14.5 }, ramps: [], blockedAreas: [{ x: 5, z: 4, width: 5, depth: 4 }, garden] };
  const after = withStoryDoorNavigation(before);
  const blocked = (x: number, z: number) => (after.blockedAreas as JsonRecord[]).some(area =>
    x >= Number(area.x) && x < Number(area.x) + Number(area.width) && z >= Number(area.z) && z < Number(area.z) + Number(area.depth));
  assert.equal(blocked(7.5, 7.5), false);
  for (const point of [[6.5, 7.5], [8.5, 7.5], [7.5, 6.5]]) assert.ok(blocked(point[0]!, point[1]!));
  assert.ok((after.blockedAreas as unknown[]).includes(garden));
  assert.equal(withStoryDoorNavigation(after), after);
  assert.throws(() => withStoryDoorNavigation({ ...before, blockedAreas: [{ x: 5, z: 4, width: 6, depth: 4 }] }));
  assert.deepEqual(storyDoor.warp.pos, { x: 7, y: 7 });
  assert.equal(storyDoor.instance.animationIndex, null);
  assert.equal(storyDoor.instance.blocksMovement, true);
});

test("A cancelled or blocked door action cannot advance its logical open state", () => {
  const values = storyScenes().filter(scene => ["valbois-door-open-scene", "valbois-door-close-scene"].includes(String(scene.id)));
  for (const value of values) {
    const graph = record(value.graph), nodes = graph.nodes as JsonRecord[], edges = graph.edges as JsonRecord[];
    const command = record(record(nodes.find(node => node.id === "door-animation")!.payload).interactiveCommand);
    assert.equal(command.kind, "playModelAnimation");
    assert.equal(command.mapId, storyDoor.mapId); assert.equal(command.instanceId, storyDoor.instanceId);
    const open = value.id === "valbois-door-open-scene";
    assert.equal(command.animationIndex, open ? 0 : 1);
    assert.equal(command.blocksMovementAfter, !open);
    const fact = record(record(nodes.find(node => node.id === "persist-door")!.payload).consequence);
    assert.deepEqual(fact, { kind: "setFact", factId: storyDoor.fact.id, value: open });
    assert.equal(edges.find(edge => edge.fromNodeId === "door-animation" && edge.fromPortId === "completed")!.toNodeId, "persist-door");
    for (const port of ["blocked", "cancelled"]) {
      const target = edges.find(edge => edge.fromNodeId === "door-animation" && edge.fromPortId === port)!.toNodeId;
      assert.equal(record(nodes.find(node => node.id === target)!.payload).outcomePolicy, "retryable");
    }
  }
});

test("Model interaction conditions partition the closed, open and pre-quest states", () => {
  const events = storyEvents().map(value => record(value.draft));
  for (const accepted of [false, true]) for (const open of [false, true]) {
    const facts = { [questIds.accepted]: accepted, [storyDoor.fact.id]: open };
    const matched = events.filter(event => (event.conditions as JsonRecord[]).every(value => facts[String(value.factId)] === value.expectedValue));
    assert.equal(matched.length, 1);
    assert.equal(matched[0]!.sceneId, !accepted ? "valbois-door-locked-scene" : open ? "valbois-door-close-scene" : "valbois-door-open-scene");
  }
  const original = questEvents().map(value => record(value.draft));
  assert.equal(original.filter(event => event.sceneId === "valbois-reward-scene").length, 1);
  assert.ok(events.every(event => event.reusePolicy === "reusable" && record(event.source).kind === "modelInteract"));
  assert.equal(new Set([...original, ...events].map(event => event.id)).size, original.length + events.length);
});

test("The guide persists near the door and the reward returns him before applying its consequences", () => {
  const points = new Map(guideStagePoints.map(point => [point.id, point]));
  for (const returning of [false, true]) {
    const cinematic = guideCinematic(returning), stage = record(cinematic.stageContext), timeline = record(cinematic.timeline);
    const moves = (timeline.steps as JsonRecord[]).filter(step => step.kind === "actorMove");
    assert.equal(moves.length, 1);
    const path = (stage.manualPaths as JsonRecord[])[0]!;
    assert.equal(path.ownerActorMoveStepId, moves[0]!.id);
    let from = points.get(returning ? "guide-door-side" : "guide-start")!;
    for (const id of path.waypointStagePointIds as string[]) {
      const target = points.get(id)!; assert.ok(target);
      assert.ok(from.x === target.x || from.y === target.y);
      assert.ok(target.x >= 8.5 && target.x <= 12.5 && target.y >= 9.5 && target.y <= 12.5);
      from = target;
    }
    assert.equal(from.id, returning ? "guide-start" : "guide-door-side");
    assert.ok(moves.every(move => record(move.metadata)["authoring.block"] === "actorMove" && record(move.metadata)["actor.pathMode"] === "manual"));
  }
  const quest = storyScenes().find(scene => scene.id === "valbois-quest-start-scene")!;
  const graph = record(quest.graph);
  assert.equal((graph.edges as JsonRecord[]).find(edge => edge.fromNodeId === "guide-route")!.toNodeId, "accept");
  const consequences = (graph.nodes as JsonRecord[]).filter(node => node.kind === "action").map(node => record(record(node.payload).consequence));
  assert.deepEqual(consequences, [{ kind: "setFact", factId: questIds.accepted, value: true }]);
  const reward = storyScenes().find(scene => scene.id === "valbois-reward-scene")!;
  assert.equal((record(reward.graph).edges as JsonRecord[]).find(edge => edge.fromNodeId === "guide-return")!.toNodeId, "effect-0");
});
