import assert from 'node:assert/strict';
import {mkdir, readFile, rm, writeFile} from 'node:fs/promises';
import {join, resolve} from 'node:path';
import {test} from 'node:test';
import {Client} from '@modelcontextprotocol/client';
import {StdioClientTransport} from '@modelcontextprotocol/client/stdio';
import type {JsonRecord} from '../src/authoring_client.js';
import {canonicalPokemonConfig} from './pokemon_fixture.js';

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === 'object' && !Array.isArray(value));
  return value as JsonRecord;
}

test('fresh MCP discovers model visibility and persists a daily condition with stable anchors and undo', {timeout: 120000}, async () => {
  const root = '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/periodic-availability-authoring/fixture';
  await mkdir(join(root, 'maps'), {recursive: true});
  const mapFile = join(root, 'maps/route.json');
  const reference = {schemaVersion: 1, sceneId: 'source', nodeId: 'claim', rewardId: 'daily'};
  const condition = {kind: 'leaf', condition: {kind: 'periodicRewardAvailable', rewardReference: reference, expectedValue: true}};
  const originalInstance = {id: 'tree', modelId: 'tree-model', entityId: 'anchor', position: {x: 1.5, y: .25, z: 1.5}, rotationDegrees: 23.5, scale: 1, blocksMovement: true};
  await writeFile(join(root, 'project.json'), JSON.stringify({name: 'Visibility', version: 'v9', settings: {dimension: 'threeD'}, tilesets: [],
    pokemon: {...canonicalPokemonConfig(), enabled: false}, maps: [{id: 'route', name: 'Route', relativePath: 'maps/route.json'}],
    scenes: [{id: 'source', name: 'Verger', graph: {startNodeId: 'start', nodes: [{id: 'start', kind: 'start'},
      {id: 'claim', kind: 'action', payload: {interactiveCommand: {kind: 'claimPeriodicReward', definition: {schemaVersion: 1, rewardId: 'daily', label: 'Fruit', itemId: 'fruit', quantity: 1}}}},
      {id: 'end', kind: 'end'}], edges: []}}]}));
  await writeFile(mapFile, JSON.stringify({id: 'route', name: 'Route', version: 'v9', size: {width: 4, height: 4}, layers: [],
    entities: [{id: 'anchor', name: 'Anchor', kind: 'custom', pos: {x: 1, y: 1}}], spatialScene: {schemaVersion: 1, width: 4, depth: 4, levelHeight: 1,
      heightLevels: Array(16).fill(0), camera: {mode: 'fixed', pitchDegrees: 48.7, yawDegrees: 0, fieldOfViewDegrees: 16.2, distance: 42},
      navigation: {spawn: {x: .5, z: .5}, allowDiagonalMovement: false, ramps: [], blockedAreas: []}, instances: [originalInstance]}}));
  const client = new Client({name: 'model-visibility-contract', version: '1.0.0'});
  const transport = new StdioClientTransport({command: process.execPath, args: [resolve('dist/src/index.js'), '--root', root, '--authoring-timeout-ms', '60000'], cwd: process.cwd(), stderr: 'pipe'});
  async function call(name: string, args: JsonRecord = {}): Promise<JsonRecord> {
    const result = record((await client.callTool({name, arguments: args})).structuredContent);
    assert.equal(result.ok, true, JSON.stringify(result));
    return record(result.data);
  }
  try {
    await client.connect(transport);
    const described = await call('pokemap_describe');
    const descriptor = (described.mutationActions as JsonRecord[]).find(action => action.id === 'map3d.instance.visibility.set');
    assert.ok(descriptor);
    assert.equal(record(record(descriptor.extensions).visibility).capability, 'map3d.conditional-visibility@1');
    const filtered = await call('pokemap_describe', {
      domain: 'map3d', view: 'full', actionIds: ['map3d.instance.visibility.set'],
    });
    assert.deepEqual(filtered.mutationActions, [descriptor]);

    let workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: root});
    const choices = await call('pokemap_query', {projectHandle: workspace.projectHandle, resourceKind: 'periodicRewardNode', operation: 'list', filters: {sceneId: 'source'}});
    assert.deepEqual(record((choices.items as JsonRecord[])[0]).reference, reference);
    const parameters = {mapId: 'route', instanceId: 'tree', visibilityCondition: condition};
    const scope = await call('pokemap_workshop', {operation: 'read', projectHandle: workspace.projectHandle, actionId: 'map3d.instance.visibility.set', parameters, includeDocuments: false});
    const planned = await call('pokemap_plan', {projectHandle: workspace.projectHandle, request: {requestId: 'visibility', actionId: 'map3d.instance.visibility.set', actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: scope.snapshotRevision, idempotencyKey: 'visibility', parameters, ...(scope.planExtensions ? {extensions: scope.planExtensions} : {})}});
    const applied = await call('pokemap_apply', {operation: 'apply', projectHandle: workspace.projectHandle, planId: planned.planId, operationId: 'visibility'});
    const saved = record(JSON.parse(await readFile(mapFile, 'utf8')));
    const instance = record((record(saved.spatialScene).instances as unknown[])[0]);
    assert.deepEqual(instance.visibilityCondition, condition);
    for (const key of ['id', 'entityId', 'position', 'rotationDegrees', 'scale', 'blocksMovement']) assert.deepEqual(instance[key], originalInstance[key as keyof typeof originalInstance]);
    assert.equal((saved.entities as unknown[]).length, 1);
    await call('pokemap_history', {operation: 'undo', projectHandle: workspace.projectHandle, entryId: record(applied.receipt).receiptId, idempotencyKey: 'undo-visibility'});
    const undone = record(JSON.parse(await readFile(mapFile, 'utf8')));
    assert.equal(record((record(undone.spatialScene).instances as unknown[])[0]).visibilityCondition, undefined);
    await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
    workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: root});
    await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
  } finally { await client.close(); await transport.close(); await rm(root, {recursive: true, force: true}); }
});
