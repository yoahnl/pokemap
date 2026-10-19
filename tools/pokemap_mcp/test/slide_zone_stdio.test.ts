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

test('L26a live MCP authors sliding zones with strict plans, undo and cold reopen',
  { timeout: 120_000 }, async () => {
    const root = await mkdtemp(join(tmpdir(), 'slide-zone-mcp-'));
    const mapFile = join(root, 'puzzle.json');
    const projectFile = join(root, 'project.json');
    await writeFile(projectFile, JSON.stringify({
      name: 'Sliding puzzle', version: 'v8', pokemon: canonicalPokemonConfig(),
      maps: [{ id: 'puzzle', name: 'Puzzle', relativePath: 'puzzle.json' }], tilesets: [],
    }));
    await writeFile(mapFile, JSON.stringify({
      id: 'puzzle', name: 'Puzzle', version: 'v8', size: { width: 12, height: 8 }, layers: [],
    }));
    const projectBefore = await readFile(projectFile);
    const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? 'dist/src/index.js'),
      '--root', root, '--authoring-timeout-ms', '60000',
      '--dart', process.env.POKEMAP_TEST_DART ?? 'dart'];
    const transport = new StdioClientTransport({ command: process.execPath, args,
      cwd: process.cwd(), stderr: 'pipe' });
    const client = new Client({ name: 'slide-zone-test', version: '1.0.0' });
    let workspace: JsonRecord | undefined;
    let sequence = 0;
    async function call(name: string, input: JsonRecord = {}, failure = false): Promise<JsonRecord> {
      const result = await client.callTool({ name, arguments: input });
      const envelope = record(result.structuredContent);
      assert.equal(envelope.ok, !failure, JSON.stringify({ name, envelope }));
      return record(envelope[failure ? 'error' : 'data']);
    }
    async function plan(actionId: string, parameters: JsonRecord,
      failure = false, revision?: unknown): Promise<JsonRecord> {
      assert.ok(workspace);
      const validation = await call('pokemap_validate', { projectHandle: workspace.projectHandle });
      const before = await readFile(mapFile);
      const id = `slide-${++sequence}`;
      const result = await call('pokemap_plan', { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        expectedRevision: revision ?? validation.snapshotRevision, idempotencyKey: id,
        parameters: { mapId: 'puzzle', ...parameters },
      } }, failure);
      assert.deepEqual(await readFile(mapFile), before);
      assert.deepEqual(await readFile(projectFile), projectBefore);
      return result;
    }
    async function apply(actionId: string, parameters: JsonRecord): Promise<void> {
      const planned = await plan(actionId, parameters);
      const applied = await call('pokemap_apply', { operation: 'apply',
        projectHandle: workspace!.projectHandle, planId: planned.planId,
        operationId: `slide-apply-${++sequence}` });
      assert.equal(record(applied.receipt).status, 'applied');
    }
    async function zones(): Promise<JsonRecord[]> {
      return record(JSON.parse(await readFile(mapFile, 'utf8'))).gameplayZones as JsonRecord[];
    }
    try {
      await client.connect(transport);
      const description = await call('pokemap_describe');
      const action = (description.mutationActions as JsonRecord[])
        .find(entry => entry.id === 'gameplay_zone.set_movement_effect_payload');
      assert.ok(action);
      const contract = record(record(action.extensions).movementEffectZone);
      assert.ok((contract.effectKinds as string[]).includes('slide'));
      assert.equal(record(contract.slide).mapMode, '2d');
      workspace = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
      const initial = await call('pokemap_validate', { projectHandle: workspace.projectHandle });
      const slide = { effectKind: 'slide', movementCost: 1 };
      await apply('gameplay_zone.create', { zone: {
        id: 'ice', name: 'Glissade', kind: 'movementEffect', priority: 3,
        area: { pos: { x: 1, y: 1 }, size: { width: 8, height: 5 } },
        movementEffect: slide,
      } });
      assert.deepEqual((await zones())[0]!.movementEffect, slide);
      const cost = { effectKind: 'movementCost', movementCost: 2 };
      await plan('gameplay_zone.set_movement_effect_payload', { zoneId: 'ice', payload: cost });
      assert.deepEqual((await zones())[0]!.movementEffect, slide);
      await apply('gameplay_zone.set_movement_effect_payload', { zoneId: 'ice', payload: cost });
      assert.deepEqual((await zones())[0]!.movementEffect, cost);
      const history = await call('pokemap_history', { operation: 'list',
        projectHandle: workspace.projectHandle, limit: 1 });
      await call('pokemap_history', { operation: 'undo', projectHandle: workspace.projectHandle,
        entryId: (history.entries as JsonRecord[])[0]!.entryId, idempotencyKey: 'slide-undo' });
      assert.deepEqual((await zones())[0]!.movementEffect, slide);
      const stale = await plan('gameplay_zone.set_movement_effect_payload',
        { zoneId: 'ice', payload: slide }, true, initial.snapshotRevision);
      assert.equal(stale.domainCode, 'plan.stale');
      for (const payload of [{ ...slide, extra: true }, { effectKind: 'unknown' },
        { ...slide, directedJump: {} }, { effectKind: 'directedJump' }]) {
        const refused = await plan('gameplay_zone.set_movement_effect_payload',
          { zoneId: 'ice', payload }, true);
        assert.notEqual(refused.domainCode, 'worker.internal');
      }
      await apply('gameplay_zone.move', { zoneId: 'ice', x: 2, y: 1 });
      await apply('gameplay_zone.set_priority', { zoneId: 'ice', priority: 7 });
      await call('pokemap_workspace', { operation: 'close', workspaceHandle: workspace.workspaceHandle });
      workspace = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
      const reopened = await call('pokemap_query', { projectHandle: workspace.projectHandle,
        resourceKind: 'map', operation: 'get', ids: ['puzzle'], view: 'detail' });
      assert.match(JSON.stringify(reopened), /"effectKind":"slide"/);
      assert.deepEqual((await zones())[0]!.movementEffect, slide);
      assert.equal((await zones())[0]!.priority, 7);
      assert.deepEqual(record((await zones())[0]!.area).pos, { x: 2, y: 1 });
      assert.deepEqual(await readFile(projectFile), projectBefore);
    } finally {
      if (workspace) await call('pokemap_workspace', { operation: 'close', workspaceHandle: workspace.workspaceHandle });
      await client.close();
      await transport.close();
      await rm(root, { recursive: true, force: true });
    }
  });
