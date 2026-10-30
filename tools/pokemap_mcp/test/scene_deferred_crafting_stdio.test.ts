import assert from 'node:assert/strict';
import {mkdir, mkdtemp, readFile, rm, writeFile} from 'node:fs/promises';
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
const command = (output = 'ball'): JsonRecord => ({kind: 'openCrafting', definition: {
  schemaVersion: 1, serviceId: 'artisan', label: 'Artisan', maximumBatchQuantity: 99, requiredDayChanges: 1,
  recipes: [{recipeId: 'red-ball', label: 'Red ball', inputItemId: 'fruit', inputQuantity: 2, outputItemId: output, outputQuantity: 1}],
}});
const scene: JsonRecord = {id: 'artisan', name: 'Artisan', graph: {startNodeId: 'start', nodes: [
  {id: 'start', kind: 'start'}, {id: 'craft', kind: 'action', payload: {interactiveCommand: command()}}, {id: 'end', kind: 'end'},
], edges: [{id: 'enter', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'craft', kind: 'default'},
  ...['completed', 'cancelled'].map(port => ({id: `leave-${port}`, fromNodeId: 'craft', fromPortId: port, toNodeId: 'end', kind: 'actionCompleted'})),
]}};

test('MCP authors crafting recipes in 2D/3D and refuses unknown items without writes', {timeout: 180000}, async () => {
  const qaRoot = process.env.AVELUNE_QA_ROOT ?? '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/crafting';
  await mkdir(qaRoot, {recursive: true});
  const root = await mkdtemp(join(qaRoot, 'crafting-mcp-'));
  const client = new Client({name: 'crafting-contract', version: '1.0.0'});
  const transport = new StdioClientTransport({command: process.execPath, args: [resolve('dist/src/index.js'), '--root', root, '--authoring-timeout-ms', '60000'], cwd: process.cwd(), stderr: 'pipe'});
  async function call(name: string, args: JsonRecord = {}, failed = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({name, arguments: args})).structuredContent);
    assert.equal(envelope.ok, !failed, JSON.stringify(envelope));
    return record(envelope[failed ? 'error' : 'data']);
  }
  try {
    for (const dimension of ['twoD', 'threeD']) {
      const directory = join(root, dimension);
      await mkdir(directory);
      await writeFile(join(directory, 'project.json'), JSON.stringify({name: 'Craft', version: dimension === 'twoD' ? 'v8' : 'v9', maps: [], tilesets: [], scenes: [], settings: {dimension}, pokemon: {...canonicalPokemonConfig(), enabled: true, catalogFiles: {items: 'items.json'}}}));
      await writeFile(join(directory, 'items.json'), JSON.stringify({schemaVersion: 1, entries: [{id: 'fruit', displayName: 'Fruit', pocketId: 'materials'}, {id: 'ball', displayName: 'Ball', pocketId: 'balls'}]}));
    }
    await client.connect(transport);
    const description = await call('pokemap_describe');
    for (const id of ['scene.upsert', 'scene.graph.patch', 'scene.interactive_command.set']) {
      const action = (description.mutationActions as JsonRecord[]).find(entry => entry.id === id);
      assert.ok(action);
      assert.equal(record(record(action.extensions).openCrafting).bagFull, 'pendingOrderPreserved');
    }
    let sequence = 0;
    for (const dimension of ['twoD', 'threeD']) {
      const directory = join(root, dimension);
      const file = join(directory, 'project.json');
      let workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: directory});
      async function plan(actionId: string, parameters: JsonRecord, failed = false): Promise<JsonRecord> {
        const validation = await call('pokemap_validate', {projectHandle: workspace.projectHandle});
        const before = await readFile(file);
        const key = `craft-${++sequence}`;
        const result = await call('pokemap_plan', {projectHandle: workspace.projectHandle, request: {requestId: key, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision, idempotencyKey: key, parameters}}, failed);
        assert.deepEqual(await readFile(file), before);
        return result;
      }
      const upsert = await plan('scene.upsert', {scene});
      const applied = await call('pokemap_apply', {operation: 'apply', projectHandle: workspace.projectHandle, planId: upsert.planId, operationId: `apply-${sequence}`});
      assert.equal(record(applied.receipt).status, 'applied');
      const before = await readFile(file);
      const refused = await plan('scene.interactive_command.set', {sceneId: 'artisan', nodeId: 'craft', command: command('missing')}, true);
      assert.equal(refused.domainCode, 'scene.publication_blocked');
      assert.deepEqual(await readFile(file), before);
      await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
      workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: directory});
      const queried = await call('pokemap_query', {projectHandle: workspace.projectHandle, resourceKind: 'scene', operation: 'get', ids: ['artisan'], view: 'detail'});
      assert.ok(JSON.stringify(queried).includes('openCrafting'));
      const stored = record(JSON.parse(await readFile(file, 'utf8')));
      const savedScene = record((stored.scenes as JsonRecord[])[0]);
      const savedNode = (record(savedScene.graph).nodes as JsonRecord[]).find(entry => entry.id === 'craft');
      assert.deepEqual(record(savedNode!.payload).interactiveCommand, command());
      await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
    }
  } finally {
    await client.close();
    await transport.close();
    await rm(root, {recursive: true, force: true});
  }
});
