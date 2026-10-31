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

test('fresh MCP publishes bounded periodic reward Scene and selected-node choices', {timeout: 120000}, async () => {
  const qa = '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/periodic-availability-authoring';
  await mkdir(qa, {recursive: true});
  const root = await mkdtemp(join(qa, 'mcp-query-'));
  const file = join(root, 'project.json');
  const scene = {id: 'orchard', name: 'Verger', graph: {startNodeId: 'start', nodes: [
    {id: 'start', kind: 'start'},
    {id: 'claim', kind: 'action', payload: {interactiveCommand: {kind: 'claimPeriodicReward', definition: {
      schemaVersion: 1, rewardId: 'fruit', label: 'Noigrume rouge', itemId: 'red-fruit', quantity: 2,
    }}}},
    {id: 'end', kind: 'end'},
  ], edges: []}};
  await writeFile(file, JSON.stringify({name: 'Picker', version: 'v8', maps: [], tilesets: [], scenes: [scene],
    pokemon: {...canonicalPokemonConfig(), enabled: false}}));
  const original = await readFile(file);
  const client = new Client({name: 'periodic-reward-picker', version: '1.0.0'});
  const transport = new StdioClientTransport({command: process.execPath,
    args: [resolve('dist/src/index.js'), '--root', root, '--authoring-timeout-ms', '60000'],
    cwd: process.cwd(), stderr: 'pipe'});
  async function call(name: string, args: JsonRecord = {}, failed = false): Promise<JsonRecord> {
    const result = record((await client.callTool({name, arguments: args})).structuredContent);
    assert.equal(result.ok, !failed, JSON.stringify(result));
    return record(result[failed ? 'error' : 'data']);
  }
  try {
    await client.connect(transport);
    const description = await call('pokemap_describe');
    const kinds = description.resourceKinds as JsonRecord[];
    assert.ok(kinds.find(kind => kind.id === 'periodicRewardScene'));
    const nodeKind = kinds.find(kind => kind.id === 'periodicRewardNode');
    assert.ok(nodeKind);
    assert.deepEqual(record(record(nodeKind.extensions).requiredFilters).sceneId, {type: 'string', minLength: 1});
    const workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: root});
    const base = {projectHandle: workspace.projectHandle, operation: 'list', view: 'summary', pageSize: 1};
    const scenes = await call('pokemap_query', {...base, resourceKind: 'periodicRewardScene'});
    const source = record((scenes.items as JsonRecord[])[0]);
    assert.equal(source.label, 'Verger');
    assert.equal(source.graph, undefined);
    assert.equal(source.runtimeBuildable, undefined);
    const nodes = await call('pokemap_query', {...base, resourceKind: 'periodicRewardNode',
      filters: {sceneId: source.sceneId}, extensions: {sourceRevision: source.revision}});
    const choice = record((nodes.items as JsonRecord[])[0]);
    assert.equal(choice.label, 'Noigrume rouge');
    assert.equal(choice.quantity, 2);
    assert.deepEqual(choice.reference, {schemaVersion: 1, sceneId: 'orchard', nodeId: 'claim', rewardId: 'fruit'});
    const missing = await call('pokemap_query', {...base, resourceKind: 'periodicRewardNode'}, true);
    assert.equal(missing.domainCode, 'query.periodic_reward_scope_invalid');
    const stale = await call('pokemap_query', {...base, resourceKind: 'periodicRewardNode',
      filters: {sceneId: 'orchard'}, extensions: {sourceRevision: 'obsolete'}}, true);
    assert.equal(stale.domainCode, 'query.periodic_reward_source_stale');
    assert.deepEqual(await readFile(file), original);
    await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
  } finally {
    await client.close();
    await transport.close();
    await rm(root, {recursive: true, force: true});
  }
});
