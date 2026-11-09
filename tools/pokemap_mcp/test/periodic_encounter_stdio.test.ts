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

test('fresh MCP exposes, persists and selects a typed periodic wild battle claim', {timeout: 120000}, async () => {
  const qa = '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/c7-07/tests-authoring/tmp';
  await mkdir(qa, {recursive: true});
  const root = await mkdtemp(join(qa, 'periodic-encounter-mcp-'));
  const file = join(root, 'project.json');
  const edge = (id: string, from: string, to: string, port = 'completed', kind = 'default') =>
    ({id, fromNodeId: from, fromPortId: port, toNodeId: to, kind});
  const policy = {schemaVersion: 1, rewardId: 'daily-visitor', label: 'Visiteur', consumeOnOutcomes: ['captured', 'fled']};
  const battle = {id: 'battle', kind: 'battle', payload: {battleKind: 'wild', battleTemplateId: 'fixed'}};
  await writeFile(file, JSON.stringify({name: 'Periodic encounter', version: 'v8', maps: [], tilesets: [],
    pokemon: {...canonicalPokemonConfig(), enabled: false},
    encounterTables: [{id: 'fixed', name: 'Fixed', encounterKind: 'walk', entries: [{speciesId: 'target', minLevel: 2, maxLevel: 2, weight: 1}]}],
    scenes: [{id: 'source', name: 'Source', graph: {startNodeId: 'start', nodes: [
      {id: 'start', kind: 'start'}, battle, {id: 'end', kind: 'end'}], edges: [edge('enter', 'start', 'battle'),
      edge('win', 'battle', 'end', 'victory', 'battleVictory'), edge('lose', 'battle', 'end', 'defeat', 'battleDefeat')]}},
      {id: 'consumer', name: 'Consumer', graph: {startNodeId: 'start', nodes: [
        {id: 'start', kind: 'start'}, {id: 'gate', kind: 'condition', payload: {conditionSource: {sourceKind: 'factLikeStoryFlag', sourceId: 'old', operator: 'isTrue'}}},
        {id: 'end', kind: 'end'}], edges: [edge('enter', 'start', 'gate'), edge('yes', 'gate', 'end', 'true', 'conditionTrue'),
        edge('no', 'gate', 'end', 'false', 'conditionFalse')]}}]}));
  const transport = new StdioClientTransport({command: process.execPath,
    args: [resolve('dist/src/index.js'), '--root', root, '--authoring-timeout-ms', '60000'], cwd: process.cwd(), stderr: 'pipe'});
  const client = new Client({name: 'periodic-encounter-contract', version: '1.0.0'});
  async function call(name: string, args: JsonRecord = {}, failed = false): Promise<JsonRecord> {
    const result = record((await client.callTool({name, arguments: args})).structuredContent);
    assert.equal(result.ok, !failed, JSON.stringify(result));
    return record(result[failed ? 'error' : 'data']);
  }
  try {
    await client.connect(transport);
    const described = await call('pokemap_describe');
    const action = (described.mutationActions as JsonRecord[]).find(action => action.id === 'scene.graph.patch');
    assert.ok(action);
    const contract = record(record(action.extensions).periodicEncounter);
    assert.equal(contract.capability, 'gameplay.periodic-encounter@1');
    assert.deepEqual(contract.consumeOnOutcomes, ['victory', 'captured', 'fled']);
    let workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: root});
    let sequence = 0;
    async function plan(actionId: string, parameters: JsonRecord, invalid = false): Promise<JsonRecord> {
      const scoped = record((await client.callTool({name: 'pokemap_workshop', arguments: {
        operation: 'read', projectHandle: workspace.projectHandle, actionId, parameters, includeDocuments: false,
      }})).structuredContent);
      if (scoped.ok !== true) {
        assert.equal(invalid, true, JSON.stringify(scoped));
        const error = record(scoped.error);
        assert.ok(['invalid_request', 'validation_failed'].includes(String(error.code)), JSON.stringify(error));
        return error;
      }
      const scope = record(scoped.data);
      const identity = `encounter-${++sequence}`;
      return call('pokemap_plan', {projectHandle: workspace.projectHandle, request: {requestId: identity,
        idempotencyKey: identity, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        expectedRevision: scope.snapshotRevision, parameters, ...(scope.planExtensions ? {extensions: scope.planExtensions} : {})}}, invalid);
    }
    const patchedBattle = {...battle, payload: {...battle.payload, periodicEncounter: policy}};
    const planned = await plan('scene.graph.patch', {sceneId: 'source', upsertNodes: [patchedBattle]});
    await call('pokemap_apply', {operation: 'apply', projectHandle: workspace.projectHandle, planId: planned.planId, operationId: 'apply-encounter'});
    const nodes = await call('pokemap_query', {projectHandle: workspace.projectHandle, resourceKind: 'periodicRewardNode',
      operation: 'list', filters: {sceneId: 'source'}});
    const choice = record((nodes.items as JsonRecord[])[0]);
    assert.equal(choice.variant, 'encounter');
    assert.equal(choice.label, 'Visiteur');
    assert.ok(!('itemId' in choice));
    assert.ok(!('quantity' in choice));
    const reference = record(choice.reference);
    const conditionSource = {sourceKind: 'periodicRewardAvailable', sourceId: reference.rewardId, operator: 'isTrue', rewardReference: reference};
    const condition = await plan('scene.condition.set', {sceneId: 'consumer', nodeId: 'gate', conditionSource});
    await call('pokemap_apply', {operation: 'apply', projectHandle: workspace.projectHandle, planId: condition.planId, operationId: 'apply-condition'});
    const before = await readFile(file);
    await plan('scene.graph.patch', {sceneId: 'source', upsertNodes: [{...battle,
      payload: {...battle.payload, periodicEncounter: {...policy, consumeOnOutcomes: ['defeat']}}}]}, true);
    assert.deepEqual(await readFile(file), before);
    await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
    workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: root});
    const stored = record(JSON.parse(await readFile(file, 'utf8')));
    const source = (stored.scenes as JsonRecord[]).find(scene => scene.id === 'source')!;
    const savedBattle = (record(source.graph).nodes as JsonRecord[]).find(node => node.id === 'battle')!;
    assert.deepEqual(record(savedBattle.payload).periodicEncounter, policy);
    await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
  } finally {
    await client.close();
    await transport.close();
    await rm(root, {recursive: true, force: true});
  }
});
