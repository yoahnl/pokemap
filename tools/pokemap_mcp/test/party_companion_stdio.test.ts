import assert from 'node:assert/strict';
import {mkdtemp, readFile, rm, writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
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

test('real MCP discovers companion authoring, clears a mapping and rejects invalid activation atomically',
  {timeout: 120_000}, async () => {
    const root = await mkdtemp(join(tmpdir(), 'party-companion-mcp-'));
    const projectFile = join(root, 'project.json');
    const args = [resolve(process.env.POKEMAP_TEST_MCP_ENTRY ?? 'dist/src/index.js'), '--root', root,
      '--authoring-timeout-ms', '60000'];
    if (process.env.POKEMAP_TEST_DART) args.push('--dart', process.env.POKEMAP_TEST_DART);
    if (process.env.POKEMAP_TEST_AUTHORING_PACKAGE) args.push('--authoring-package', process.env.POKEMAP_TEST_AUTHORING_PACKAGE);
    const client = new Client({name: 'party-companion-contract-test', version: '1.0.0'});
    let workspace: JsonRecord | undefined;
    let sequence = 0;
    async function call(name: string, parameters: JsonRecord = {}, failed = false): Promise<JsonRecord> {
      const response = await client.callTool({name, arguments: parameters});
      const envelope = record(response.structuredContent);
      assert.equal(envelope.ok, !failed, JSON.stringify(envelope));
      const data = record(envelope[failed ? 'error' : 'data']);
      if (failed) assert.notEqual(data.code, 'worker.internal');
      return data;
    }
    async function query(): Promise<JsonRecord> {
      return call('pokemap_query', {projectHandle: workspace!.projectHandle, operation: 'get',
        resourceKind: 'partyCompanionConfiguration', ids: ['project'], view: 'detail'});
    }
    async function plan(parameters: JsonRecord, failed = false): Promise<JsonRecord> {
      const validation = await call('pokemap_validate', {projectHandle: workspace!.projectHandle});
      const id = `companion-${++sequence}`;
      return call('pokemap_plan', {projectHandle: workspace!.projectHandle, request: {requestId: id,
        actionId: 'party_companion.configure', actionVersion: 1, workspaceHandle: workspace!.workspaceHandle,
        expectedRevision: validation.snapshotRevision, idempotencyKey: id, parameters}}, failed);
    }
    try {
      await writeFile(projectFile, JSON.stringify({name: 'Companion mappings', version: 'v8', maps: [],
        pokemon: canonicalPokemonConfig(),
        tilesets: [{id: 'sheet', name: 'Sheet', relativePath: 'assets/sheet.png', source: {kind: 'regular_atlas',
          assetId: 'sheet', pixelWidth: 32, pixelHeight: 32, tileWidth: 32, tileHeight: 32, tileProperties: []}}],
        characters: [{id: 'guide', name: 'Guide', tilesetId: 'sheet', animations:
          ['north', 'south', 'west', 'east'].map(direction => ({state: 'walk', direction, sourceAssetId: 'sheet',
            frames: [{source: {x: 0, y: 0, width: 32, height: 32}, durationMs: 100}]}))}],
        partyCompanion: {enabled: false, mappings: [{speciesId: 'clockbird', formId: 'bronze', characterId: 'guide'}]},
      }));
      await client.connect(new StdioClientTransport({command: process.execPath, args, cwd: process.cwd(), stderr: 'pipe'}));
      const description = await call('pokemap_describe');
      assert.ok((description.mutationActions as JsonRecord[]).some(action => action.id === 'party_companion.configure'));
      assert.ok((description.resourceKinds as JsonRecord[]).some(kind => kind.id === 'partyCompanionConfiguration'));
      workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: root});
      assert.equal(((await query()).items as JsonRecord[]).length, 1);
      const before = await readFile(projectFile, 'utf8');
      const planned = await plan({enabled: false, mappings: []});
      assert.equal(await readFile(projectFile, 'utf8'), before);
      await call('pokemap_apply', {operation: 'apply', projectHandle: workspace.projectHandle,
        planId: planned.planId, operationId: 'companion-apply'});
      await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
      workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: root});
      const current = record(((await query()).items as JsonRecord[])[0]);
      assert.equal(current.enabled, false);
      assert.deepEqual(current.mappings, []);
      const accepted = await readFile(projectFile, 'utf8');
      await plan({enabled: true, mappings: []}, true);
      await plan({enabled: false, mappings: [], unknown: true}, true);
      assert.equal(await readFile(projectFile, 'utf8'), accepted);
    } finally {
      if (workspace) await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
      await client.close();
      await rm(root, {recursive: true, force: true});
    }
  });
