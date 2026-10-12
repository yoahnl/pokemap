import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { test } from 'node:test';
import { Client } from '@modelcontextprotocol/client';
import { StdioClientTransport } from '@modelcontextprotocol/client/stdio';
import type { JsonRecord } from '../src/authoring_client.js';
import { canonicalPokemonConfig } from './pokemon_fixture.js';

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === 'object' && !Array.isArray(value));
  return value as JsonRecord;
}

test('packaged MCP discovers and authors moving platforms without whole-map persistence', { timeout: 120_000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), 'pokemap-moving-platform-'));
  const mapPath = join(root, 'gym.json');
  const cells = [{ x: 0, y: 0 }];
  const platform: JsonRecord = { id: 'bridge', placedElementId: 'art',
    initialPose: { leftPx: 64, topPx: 64, quarterTurns: 0 },
    lattice: { widthPx: 32, heightPx: 24.03323336836951, originLeftPx: 0, originTopPx: 0,
      cellOffsetLeftPx: 0, cellOffsetTopPx: 0 },
    translationDistanceCells: 5, terrainLayerIds: ['magma'], travelCells: [{ x: 2, y: 2 }],
    variants: Array.from({ length: 4 }, () => ({ elementId: 'platform', anchorOffsetPx: { x: 0, y: 0 },
      supportCells: cells, clearanceCells: cells, forwardClearanceCells: cells,
      backwardClearanceCells: cells, rotationClearanceCells: cells })),
  };
  const map: JsonRecord = { id: 'gym', name: 'Gym', version: 'v8', size: { width: 10, height: 10 },
    layers: [{ runtimeType: 'tile', id: 'magma', name: 'Magma', isVisible: true, opacity: 1, purpose: 'visual', palette: [], cells: Array(100).fill(0) },
      { runtimeType: 'collision', id: 'walls', name: 'Walls', isVisible: true, opacity: 1, collisions: Array(100).fill(false) }],
    placedElements: [{ id: 'art', layerId: 'magma', elementId: 'platform', pos: { x: 2, y: 2 },
      applyCollision: false, properties: { pokemapPlacementOrigin: 'authored' } }],
  };
  await writeFile(mapPath, JSON.stringify(map));
  await writeFile(join(root, 'project.json'), JSON.stringify({ name: 'Moving Platform MCP', version: 'v8',
    pokemon: canonicalPokemonConfig(), settings: { tileWidth: 32, tileHeight: 32 },
    maps: [{ id: 'gym', name: 'Gym', relativePath: 'gym.json' }],
    tilesets: [{ id: 'tiles', name: 'Tiles', relativePath: 'tiles.png' }],
    elements: [{ id: 'platform', name: 'Platform', tilesetId: 'tiles', categoryId: 'platform',
      frames: [{ source: { x: 0, y: 0, width: 1, height: 2 } }] }],
  }));
  const args = [resolve('dist/src/index.js'), '--root', root, '--authoring-timeout-ms', '60000'];
  if (process.env.POKEMAP_TEST_DART) args.push('--dart', process.env.POKEMAP_TEST_DART);
  const transport = new StdioClientTransport({ command: process.execPath, args, cwd: process.cwd(), stderr: 'pipe' });
  const client = new Client({ name: 'moving-platform-test', version: '1.0.0' });
  async function call(name: string, parameters: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const response = await client.callTool({ name, arguments: parameters });
    assert.equal(response.isError, failure ? true : undefined, JSON.stringify(response.structuredContent));
    const envelope = record(response.structuredContent);
    assert.equal(envelope.ok, !failure);
    return record(failure ? envelope.error : envelope.data);
  }
  try {
    await client.connect(transport);
    const catalog = await call('pokemap_describe');
    const actions = catalog.mutationActions as JsonRecord[];
    assert.ok(actions.some((action) => action.id === 'map.platform.upsert'));
    assert.ok(actions.some((action) => action.id === 'map.platform.delete'));
    const sceneAction = actions.find((action) => action.id === 'scene.upsert');
    assert.ok(JSON.stringify(sceneAction).includes('movePlatform'));
    const workspace = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
    let sequence = 0;
    async function mutate(actionId: string, parameters: JsonRecord, failure = false) {
      const before = await readFile(mapPath);
      const validation = await call('pokemap_validate', { projectHandle: workspace.projectHandle });
      const id = `platform-${++sequence}`;
      const planned = await call('pokemap_plan', { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        parameters, expectedRevision: validation.snapshotRevision, idempotencyKey: id,
      } }, failure);
      assert.deepEqual(await readFile(mapPath), before);
      if (failure) return planned;
      const applied = await call('pokemap_apply', { operation: 'apply', projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: id });
      assert.equal(record(applied.receipt).status, 'applied');
      return applied;
    }
    await mutate('map.platform.upsert', { mapId: 'gym', platform });
    let saved = record(JSON.parse(await readFile(mapPath, 'utf8')));
    assert.deepEqual(saved.movingPlatforms, [platform]);
    assert.deepEqual(saved.layers, map.layers);
    assert.deepEqual(record((saved.placedElements as JsonRecord[])[0]).id, 'art');
    const invalid = await mutate('map.platform.upsert', { mapId: 'gym', platform: { ...platform, terrainLayerIds: ['walls'] } }, true);
    assert.equal(invalid.domainCode, 'map.platform_invalid');
    await call('pokemap_workspace', { operation: 'close', workspaceHandle: workspace.workspaceHandle });
    const reopened = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
    workspace.projectHandle = reopened.projectHandle;
    workspace.workspaceHandle = reopened.workspaceHandle;
    await mutate('map.platform.delete', { mapId: 'gym', platformId: 'bridge' });
    saved = record(JSON.parse(await readFile(mapPath, 'utf8')));
    assert.deepEqual(saved.movingPlatforms, []);
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});
