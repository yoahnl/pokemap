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

test('L25 real MCP authors autonomous props and a group with atomic reference refusals',
  { timeout: 120_000 }, async () => {
    const root = await mkdtemp(join(tmpdir(), 'l25-moving-props-'));
    const mapPath = join(root, 'hall.json');
    const projectPath = join(root, 'project.json');
    const map: JsonRecord = {
      version: 'v8', id: 'hall', name: 'Hall', size: { width: 10, height: 10 },
      layers: [{ runtimeType: 'tile', id: 'art', name: 'Art', cells: Array(100).fill(0) }],
      placedElements: ['a', 'b'].map((id, index) => ({
        id: `${id}-art`, layerId: 'art', elementId: 'gate',
        pos: { x: 2, y: 2 + index * 2 }, applyCollision: false,
        properties: { pokemapPlacementOrigin: 'authored' },
      })),
    };
    const project = {
      version: 'v8', name: 'Moving props', pokemon: canonicalPokemonConfig(),
      settings: { tileWidth: 32, tileHeight: 32 },
      maps: [{ id: 'hall', name: 'Hall', relativePath: 'hall.json' }],
      tilesets: [{ id: 'tiles', name: 'Tiles', relativePath: 'tiles.png' }],
      elements: [{ id: 'gate', name: 'Gate', tilesetId: 'tiles', categoryId: 'props',
        frames: [{ source: { x: 0, y: 0, width: 1, height: 1 } }] }],
    };
    await writeFile(mapPath, JSON.stringify(map));
    await writeFile(projectPath, JSON.stringify(project));
    const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? 'dist/src/index.js'),
      '--root', root, '--authoring-timeout-ms', '60000'];
    if (process.env.POKEMAP_TEST_DART) args.push('--dart', process.env.POKEMAP_TEST_DART);
    const transport = new StdioClientTransport({ command: process.execPath, args,
      cwd: process.cwd(), stderr: 'pipe' });
    const client = new Client({ name: 'l25-props-test', version: '1.0.0' });
    async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
      const response = await client.callTool({ name, arguments: input });
      const envelope = record(response.structuredContent);
      assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
      return record(envelope[failure ? 'error' : 'data']);
    }
    try {
      await client.connect(transport);
      const catalog = await call('pokemap_describe');
      const actions = catalog.mutationActions as JsonRecord[];
      for (const id of ['map.prop.upsert', 'map.prop.delete']) {
        assert.ok(actions.some(action => action.id === id), id);
      }
      assert.match(JSON.stringify(actions.find(action => action.id === 'scene.upsert')), /setPropState/);
      let workspace = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
      let sequence = 0;
      async function mutate(actionId: string, parameters: JsonRecord, failure = false): Promise<JsonRecord> {
        const beforeMap = await readFile(mapPath);
        const beforeProject = await readFile(projectPath);
        const validation = await call('pokemap_validate', { projectHandle: workspace.projectHandle });
        const id = `props-${++sequence}`;
        const plan = await call('pokemap_plan', { projectHandle: workspace.projectHandle, request: {
          requestId: id, actionId, actionVersion: 1, parameters,
          workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision,
          idempotencyKey: id,
        } }, failure);
        assert.deepEqual(await readFile(mapPath), beforeMap);
        assert.deepEqual(await readFile(projectPath), beforeProject);
        if (failure) return plan;
        const applied = await call('pokemap_apply', { operation: 'apply',
          projectHandle: workspace.projectHandle, planId: plan.planId, operationId: id });
        assert.equal(record(applied.receipt).status, 'applied');
        return applied;
      }
      const definitions = ['a', 'b'].map((id, index) => ({
        id, placedElementId: `${id}-art`,
        closedPositionPx: { x: 64, y: 64 + index * 64 },
        openPositionPx: { x: 96, y: 64 + index * 64 },
        collisionRect: { leftPx: 0, topPx: 0, widthPx: 32, heightPx: 32 },
        initialState: index === 0 ? 'closed' : 'open',
      }));
      for (const prop of definitions) await mutate('map.prop.upsert', { mapId: 'hall', prop });
      const savedMap = record(JSON.parse(await readFile(mapPath, 'utf8')));
      assert.deepEqual(savedMap.movingProps, definitions);
      const placements = savedMap.placedElements as JsonRecord[];
      assert.deepEqual(placements.find(item => item.id === 'b-art')?.pos, { x: 3, y: 4 });
      const invalid = await mutate('map.prop.upsert', { mapId: 'hall', prop: {
        ...definitions[0], placedElementId: 'missing',
      } }, true);
      assert.equal(invalid.domainCode, 'map.prop_invalid');
      const command = { kind: 'setPropState', mapId: 'hall', propIds: ['a', 'b'],
        state: 'open', durationMs: 350 };
      const scene = { id: 'gates', name: 'Gates', graph: { startNodeId: 'start', nodes: [
        { id: 'start', kind: 'start' },
        { id: 'move', kind: 'action', payload: { kind: 'action', interactiveCommand: command } },
        { id: 'end', kind: 'end' },
      ], edges: [
        { id: 'entry', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'move', kind: 'default' },
        ...['moved', 'blocked'].map(port => ({ id: port, fromNodeId: 'move', fromPortId: port,
          toNodeId: 'end', kind: 'default' })),
      ] } };
      await mutate('scene.upsert', { scene });
      const refused = await mutate('map.prop.delete', { mapId: 'hall', propId: 'a' }, true);
      assert.equal(refused.domainCode, 'map.prop_referenced');
      await call('pokemap_workspace', { operation: 'close', workspaceHandle: workspace.workspaceHandle });
      workspace = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
      const reopened = record(JSON.parse(await readFile(projectPath, 'utf8')));
      const savedScene = record((reopened.scenes as JsonRecord[])[0]);
      const nodes = record(savedScene.graph).nodes as JsonRecord[];
      assert.deepEqual(record(nodes.find(node => node.id === 'move')?.payload).interactiveCommand, command);
      await mutate('map.prop.delete', { mapId: 'hall', propId: 'b' }, true);
      await call('pokemap_workspace', { operation: 'close', workspaceHandle: workspace.workspaceHandle });
    } finally {
      await client.close();
      await transport.close();
      await rm(root, { recursive: true, force: true });
    }
  });
