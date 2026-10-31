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
const command = (itemId = 'fruit', quantity = 2): JsonRecord => ({kind: 'claimPeriodicReward', definition: {schemaVersion: 1, rewardId: 'tree-fruit', label: 'Fruit quotidien', itemId, quantity}});
const scene: JsonRecord = {id: 'periodic', name: 'Récompense quotidienne', graph: {startNodeId: 'start', nodes: [
  {id: 'start', kind: 'start'}, {id: 'talk-node', kind: 'yarnDialogue', payload: {dialogueId: 'talk'}}, {id: 'reward-node', kind: 'action', payload: {interactiveCommand: command()}}, {id: 'end', kind: 'end'},
], edges: [{id: 'enter', fromNodeId: 'start', fromPortId: 'completed', toNodeId: 'talk-node', kind: 'default'}, {id: 'talk-completed', fromNodeId: 'talk-node', fromPortId: 'completed', toNodeId: 'reward-node', kind: 'default'},
  ...['received', 'alreadyClaimed', 'bagFull', 'blocked'].map(port => ({id: `leave-${port}`, fromNodeId: 'reward-node', fromPortId: port, toNodeId: 'end', kind: 'actionCompleted'})),
]}};

test('live MCP describes and authors periodic rewards in 2D/3D; invalid items and quantities never write', {timeout: 180000}, async () => {
  const qaRoot = process.env.AVELUNE_QA_ROOT ?? '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/periodic-authoring';
  await mkdir(qaRoot, {recursive: true});
  const root = await mkdtemp(join(qaRoot, 'periodic-mcp-'));
  const client = new Client({name: 'periodic-contract', version: '1.0.0'});
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
      await writeFile(join(directory, 'project.json'), JSON.stringify({name: 'Periodic', version: dimension === 'twoD' ? 'v8' : 'v9', maps: [], tilesets: [], scenes: [], dialogues: [{id: 'talk', name: 'Talk', relativePath: 'dialogues/talk.yarn'}], settings: {dimension}, pokemon: {...canonicalPokemonConfig(), enabled: false, catalogFiles: {items: 'items.json'}}}));
      await mkdir(join(directory, 'dialogues'));
      await writeFile(join(directory, 'dialogues/talk.yarn'), 'title: Start\n---\nFound!\n-> Oui\n    Bonjour.\n-> Non\n    Au revoir.\n===\n');
      await writeFile(join(directory, 'items.json'), JSON.stringify({schemaVersion: 1, entries: [{id: 'fruit', displayName: 'Noigrume rouge', pocketId: 'materials'}]}));
    }
    await client.connect(transport);
    const description = await call('pokemap_describe');
    for (const id of ['scene.upsert', 'scene.graph.patch', 'scene.interactive_command.set']) {
      const action = (description.mutationActions as JsonRecord[]).find(entry => entry.id === id);
      assert.ok(action);
      assert.equal(record(record(action.extensions).claimPeriodicReward).period, 'civilDay');
      assert.deepEqual(record(record(action.extensions).claimPeriodicReward).outputPorts, ['received', 'alreadyClaimed', 'bagFull', 'blocked']);
    }
    let sequence = 0;
    for (const dimension of ['twoD', 'threeD']) {
      const directory = join(root, dimension);
      const file = join(directory, 'project.json');
      let workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: directory});
      async function plan(actionId: string, parameters: JsonRecord, failed = false): Promise<JsonRecord> {
        const validation = await call('pokemap_validate', {projectHandle: workspace.projectHandle});
        const before = await readFile(file);
        const key = `periodic-${++sequence}`;
        const result = await call('pokemap_plan', {projectHandle: workspace.projectHandle, request: {requestId: key, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle, expectedRevision: validation.snapshotRevision, idempotencyKey: key, parameters}}, failed);
        assert.deepEqual(await readFile(file), before);
        return result;
      }
      const upsert = await plan('scene.upsert', {scene});
      const applied = await call('pokemap_apply', {operation: 'apply', projectHandle: workspace.projectHandle, planId: upsert.planId, operationId: `apply-${sequence}`});
      assert.equal(record(applied.receipt).status, 'applied');
      const before = await readFile(file);
      const refused = await plan('scene.interactive_command.set', {sceneId: 'periodic', nodeId: 'reward-node', command: command('missing')}, true);
      assert.equal(refused.domainCode, 'scene.publication_blocked');
      assert.deepEqual(await readFile(file), before);
      const malformed = command(); record(malformed.definition).quantity = 0;
      await plan('scene.interactive_command.set', {sceneId: 'periodic', nodeId: 'reward-node', command: malformed}, true);
      assert.deepEqual(await readFile(file), before);
      const update = await plan('scene.interactive_command.set', {sceneId: 'periodic', nodeId: 'reward-node', command: command('fruit', 3)});
      await call('pokemap_apply', {operation: 'apply', projectHandle: workspace.projectHandle, planId: update.planId, operationId: `set-${sequence}`});
      const patch = await plan('scene.graph.patch', {sceneId: 'periodic', upsertNodes: [{id: 'reward-node', kind: 'action', title: 'Récompense configurée', payload: {interactiveCommand: command()}}]});
      await call('pokemap_apply', {operation: 'apply', projectHandle: workspace.projectHandle, planId: patch.planId, operationId: `patch-${sequence}`});
      for (const actionId of ['scene.dialogue.choicePolicy.update', 'scene.dialogue.lineFeedback.update']) {
        const parameters: JsonRecord = {sceneId: 'periodic', nodeId: 'talk-node', ...(actionId.includes('choicePolicy') ? {choicePolicy: {nodeName: 'Start'}} : {linePolicy: {nodeName: 'Start', lineIndex: 0, feedback: {segments: [{kind: 'text', text: 'Found!'}], advance: {kind: 'confirm'}}}})};
        const policy = await plan(actionId, parameters);
        await call('pokemap_apply', {operation: 'apply', projectHandle: workspace.projectHandle, planId: policy.planId, operationId: `policy-${sequence}`});
      }
      await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
      workspace = await call('pokemap_workspace', {operation: 'open', projectRoot: directory});
      const queried = await call('pokemap_query', {projectHandle: workspace.projectHandle, resourceKind: 'scene', operation: 'get', ids: ['periodic'], view: 'detail'});
      assert.ok(JSON.stringify(queried).includes('claimPeriodicReward'));
      const stored = record(JSON.parse(await readFile(file, 'utf8')));
      const savedScene = record((stored.scenes as JsonRecord[])[0]);
      const savedNode = (record(savedScene.graph).nodes as JsonRecord[]).find(entry => entry.id === 'reward-node');
      assert.deepEqual(record(savedNode!.payload).interactiveCommand, command());
      await call('pokemap_workspace', {operation: 'close', workspaceHandle: workspace.workspaceHandle});
    }
  } finally {
    await client.close();
    await transport.close();
    await rm(root, {recursive: true, force: true});
  }
});
