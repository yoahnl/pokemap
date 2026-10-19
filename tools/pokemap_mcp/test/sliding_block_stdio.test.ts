import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
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

test('L26b real MCP composes a movable obstacle and sliding terrain with atomic plans and cold reopen',
  { timeout: 120_000 }, async () => {
    const root = await mkdtemp(join(tmpdir(), 'sliding-block-mcp-'));
    const mapFile = join(root, 'puzzle.json');
    const projectFile = join(root, 'project.json');
    await writeFile(projectFile, JSON.stringify({ name: 'Sliding block puzzle', version: 'v8',
      pokemon: canonicalPokemonConfig(), settings: { tileWidth: 32, tileHeight: 32 },
      maps: [{ id: 'puzzle', name: 'Puzzle', relativePath: 'puzzle.json' }],
      tilesets: [{ id: 'tiles', name: 'Tiles', relativePath: 'tiles.png' }],
      elements: [{ id: 'block-art', name: 'Block', tilesetId: 'tiles', categoryId: 'props',
        frames: [{ source: { x: 0, y: 0, width: 1, height: 1 } }] }],
    }));
    await writeFile(mapFile, JSON.stringify({ id: 'puzzle', name: 'Puzzle', version: 'v8',
      size: { width: 12, height: 8 }, layers: [], entities: [{ id: 'block', kind: 'custom',
        pos: { x: 3, y: 2 }, blocksMovement: true,
        editorVisual: { elementId: 'block-art' }, properties: { preserved: 'yes' },
      }] }));
    const projectBefore = await readFile(projectFile);
    const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? 'dist/src/index.js'),
      '--root', root, '--authoring-timeout-ms', '60000',
      '--dart', process.env.POKEMAP_TEST_DART ?? 'dart'];
    const transport = new StdioClientTransport({ command: process.execPath, args,
      cwd: process.cwd(), stderr: 'pipe' });
    let serverStderr = '';
    transport.stderr?.on('data', (chunk: Buffer) => {
      serverStderr = (serverStderr + chunk.toString()).slice(-4000);
    });
    const client = new Client({ name: 'sliding-block-test', version: '1.0.0' });
    let workspace: JsonRecord | undefined;
    let sequence = 0;
    async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
      const result = await client.callTool({ name, arguments: input }).catch(error => {
        throw new Error(`${name}: ${String(error)}\n${serverStderr}`);
      });
      const envelope = record(result.structuredContent);
      assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
      return record(envelope[failure ? 'error' : 'data']);
    }
    async function plan(actionId: string, parameters: JsonRecord,
      failure = false, revision?: unknown): Promise<JsonRecord> {
      assert.ok(workspace);
      const validation = await call('pokemap_validate', { projectHandle: workspace.projectHandle });
      const before = await readFile(mapFile);
      const id = `block-${++sequence}`;
      const planned = await call('pokemap_plan', { projectHandle: workspace.projectHandle,
        request: { requestId: id, actionId, actionVersion: 1,
          workspaceHandle: workspace.workspaceHandle,
          expectedRevision: revision ?? validation.snapshotRevision, idempotencyKey: id,
          parameters: { mapId: 'puzzle', ...parameters } } }, failure);
      assert.deepEqual(await readFile(mapFile), before);
      assert.deepEqual(await readFile(projectFile), projectBefore);
      return planned;
    }
    async function apply(actionId: string, parameters: JsonRecord): Promise<void> {
      const planned = await plan(actionId, parameters);
      const result = await call('pokemap_apply', { operation: 'apply',
        projectHandle: workspace!.projectHandle, planId: planned.planId,
        operationId: `block-apply-${++sequence}` });
      assert.equal(record(result.receipt).status, 'applied');
    }
    async function savedMap(): Promise<JsonRecord> {
      return record(JSON.parse(await readFile(mapFile, 'utf8')));
    }
    async function undo(): Promise<void> {
      const history = await call('pokemap_history', { operation: 'list',
        projectHandle: workspace!.projectHandle, limit: 1 });
      await call('pokemap_history', { operation: 'undo', projectHandle: workspace!.projectHandle,
        entryId: (history.entries as JsonRecord[])[0]!.entryId,
        idempotencyKey: `block-undo-${++sequence}` });
    }
    try {
      await client.connect(transport).catch(error => {
        throw new Error(`connect: ${String(error)}\n${serverStderr}`);
      });
      const description = await call('pokemap_describe');
      const actions = description.mutationActions as JsonRecord[];
      const obstacleAction = actions.find(action => action.id === 'entity.set_field_obstacle');
      const slideAction = actions.find(action => action.id === 'gameplay_zone.set_movement_effect_payload');
      assert.ok(obstacleAction);
      assert.ok(slideAction);
      const blockContract = record(record(record(obstacleAction.extensions).fieldObstacle).strengthBoulder);
      assert.equal(blockContract.ordinaryPushCells, 1);
      assert.equal(blockContract.slideZone, 'movementEffect.slide');
      assert.deepEqual(blockContract.stops, ['obstacle', 'zoneExit']);
      assert.equal(blockContract.saveDuringTraversal, false);
      assert.equal(blockContract.checkpointDuringTraversal, false);
      assert.deepEqual(record(record(record(slideAction.extensions).movementEffectZone).slide)
        .affectedActors, ['player', 'strengthBoulder']);
      workspace = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
      const initial = await call('pokemap_validate', { projectHandle: workspace.projectHandle });
      const obstacle = { kind: 'strengthBoulder', resetPolicy: 'mapInstance' };
      const slide = { effectKind: 'slide', movementCost: 1 };
      await apply('entity.set_field_obstacle', { entityId: 'block', fieldObstacle: obstacle });
      await apply('gameplay_zone.create', { zone: { id: 'floor', name: 'Glissade',
        kind: 'movementEffect', area: { pos: { x: 2, y: 2 }, size: { width: 7, height: 1 } },
        movementEffect: slide } });
      await plan('gameplay_zone.set_movement_effect_payload', {
        zoneId: 'floor', payload: { effectKind: 'movementCost', movementCost: 2 },
      });
      await apply('entity.set_field_obstacle', { entityId: 'block', fieldObstacle: null });
      const clearedBlock = ((await savedMap()).entities as JsonRecord[])
        .find(entity => entity.id === 'block')!;
      assert.equal(Object.hasOwn(clearedBlock, 'fieldObstacle'), false);
      await undo();
      const stale = await plan('entity.set_field_obstacle',
        { entityId: 'block', fieldObstacle: obstacle }, true, initial.snapshotRevision);
      assert.equal(stale.domainCode, 'plan.stale');
      for (const [actionId, parameters] of [
        ['entity.set_field_obstacle', { entityId: 'block', fieldObstacle: { ...obstacle, sliding: true } }],
        ['gameplay_zone.set_movement_effect_payload', { zoneId: 'floor', payload: { ...slide, unknown: true } }],
      ] as const) {
        const refused = await plan(actionId, parameters, true);
        assert.notEqual(refused.domainCode, 'worker.internal');
      }
      await call('pokemap_workspace', { operation: 'close', workspaceHandle: workspace.workspaceHandle });
      workspace = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
      const queried = await call('pokemap_query', { projectHandle: workspace.projectHandle,
        resourceKind: 'map', operation: 'get', ids: ['puzzle'], view: 'detail' });
      assert.match(JSON.stringify(queried), /"kind":"strengthBoulder"/);
      assert.match(JSON.stringify(queried), /"effectKind":"slide"/);
      const map = await savedMap();
      const block = (map.entities as JsonRecord[]).find(entity => entity.id === 'block')!;
      assert.deepEqual(block.fieldObstacle, obstacle);
      assert.deepEqual(block.pos, { x: 3, y: 2 });
      assert.deepEqual(block.properties, { preserved: 'yes' });
      assert.deepEqual((map.gameplayZones as JsonRecord[])[0]!.movementEffect, slide);
      assert.deepEqual(await readFile(projectFile), projectBefore);
      if (process.env.POKEMAP_TEST_SLIDING_BLOCK_RECEIPT) {
        await writeFile(process.env.POKEMAP_TEST_SLIDING_BLOCK_RECEIPT, JSON.stringify({
          live: true, transport: 'MCP stdio', actions: [obstacleAction, slideAction],
          serverSha256: createHash('sha256').update(await readFile(resolve(args[0]!))).digest('hex'),
          verified: ['describe', 'composedPuzzle', 'nonMutatingPlan', 'set', 'clear',
            'undo', 'stale', 'strictRefusal', 'query', 'coldReopen'],
        }, null, 2));
      }
    } finally {
      if (workspace) await call('pokemap_workspace', { operation: 'close', workspaceHandle: workspace.workspaceHandle });
      await client.close();
      await transport.close();
      await rm(root, { recursive: true, force: true });
    }
  });
