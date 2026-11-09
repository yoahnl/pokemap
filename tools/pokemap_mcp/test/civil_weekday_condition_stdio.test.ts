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

test('fresh MCP guides and persists one typed civil weekday Scene condition', {timeout: 120000}, async () => {
  const qa = '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/c7-07/tests-civil';
  await mkdir(qa, {recursive: true});
  const root = await mkdtemp(join(qa, 'scene-condition-mcp-'));
  const file = join(root, 'project.json');
  const edge = (id: string, from: string, to: string, port = 'completed', kind = 'default') =>
    ({id, fromNodeId: from, fromPortId: port, toNodeId: to, kind});
  await writeFile(file, JSON.stringify({name: 'Typed condition', version: 'v8', maps: [], tilesets: [],
    pokemon: {...canonicalPokemonConfig(), enabled: false}, scenes: [
      {id: 'consumer', name: 'Consumer', graph: {startNodeId: 'start', nodes: [
        {id: 'start', kind: 'start'}, {id: 'gate', kind: 'condition', payload: {conditionSource: {
          sourceKind: 'factLikeStoryFlag', sourceId: 'old', operator: 'isTrue'}}}, {id: 'end', kind: 'end'},
      ], edges: [edge('enter', 'start', 'gate'), edge('yes', 'gate', 'end', 'true', 'conditionTrue'), edge('no', 'gate', 'end', 'false', 'conditionFalse')]}},
      {id: 'source', name: 'Source', graph: {startNodeId: 'start', nodes: [
        {id: 'start', kind: 'start'}, {id: 'talk', kind: 'yarnDialogue', payload: {dialogueId: 'foreign'}},
        {id: 'claim', kind: 'action', payload: {interactiveCommand: {kind: 'claimPeriodicReward', definition: {
          schemaVersion: 1, rewardId: 'daily-fruit', label: 'Fruit', itemId: 'fruit', quantity: 2,
        }}}}, {id: 'end', kind: 'end'},
      ], edges: [edge('enter', 'start', 'talk'), edge('talk', 'talk', 'claim'),
        ...['received', 'alreadyClaimed', 'bagFull', 'blocked'].map(port => edge(port, 'claim', 'end', port, 'actionCompleted'))]}},
    ], dialogues: [{id: 'foreign', name: 'Foreign', relativePath: 'dialogues/must-not-read.yarn'}]}));
  const client = new Client({name: 'civil-weekday-condition-contract', version: '1.0.0'});
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
    const described = await call('pokemap_describe');
    const action = (described.mutationActions as JsonRecord[]).find(action => action.id === 'scene.condition.set');
    assert.ok(action);
    assert.equal(record(record(action.extensions).civilWeekday).sourceKind, 'civilWeekday');
    let workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: root});
    const conditionSource = {sourceKind: 'civilWeekday', sourceId: 'civilWeekday',
      operator: 'isTrue', weekday: 'friday'};
    const parameters = {sceneId: 'consumer', nodeId: 'gate', conditionSource};
    const scoped = await call('pokemap_workshop', {operation: 'read', projectHandle: workspace.projectHandle,
      actionId: 'scene.condition.set', parameters, includeDocuments: false});
    const planned = await call('pokemap_plan', {projectHandle: workspace.projectHandle, request: {
      requestId: 'condition', actionId: 'scene.condition.set', actionVersion: 1,
      workspaceHandle: workspace.workspaceHandle, expectedRevision: scoped.snapshotRevision,
      idempotencyKey: 'condition', parameters, ...(scoped.planExtensions ? {extensions: scoped.planExtensions} : {}),
    }});
    await call('pokemap_apply', {operation: 'apply', projectHandle: workspace.projectHandle,
      planId: planned.planId, operationId: 'apply-condition'});
    await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
    workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: root});
    const stored = record(JSON.parse(await readFile(file, 'utf8')));
    const consumer = (stored.scenes as JsonRecord[]).find(scene => scene.id === 'consumer')!;
    const gate = (record(consumer.graph).nodes as JsonRecord[]).find(node => node.id === 'gate')!;
    assert.deepEqual(record(gate.payload).conditionSource, conditionSource);
    await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
  } finally {
    await client.close();
    await transport.close();
    await rm(root, {recursive: true, force: true});
  }
});
