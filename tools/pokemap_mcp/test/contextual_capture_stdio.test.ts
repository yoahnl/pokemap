import assert from 'node:assert/strict';
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { test } from 'node:test';
import { Client } from '@modelcontextprotocol/client';
import { StdioClientTransport } from '@modelcontextprotocol/client/stdio';
import { Ajv } from 'ajv';
import type { JsonRecord } from '../src/authoring_client.js';
import { canonicalPokemonConfig, canonicalPokemonRulesetProfile } from './pokemon_fixture.js';

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === 'object' && !Array.isArray(value));
  return value as JsonRecord;
}

test('fresh MCP discovers and authors contextual capture with explicit profile and reversible admission', { timeout: 180000 }, async () => {
  const qaRoot = '/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7-annexes/capture-authoring';
  await mkdir(qaRoot, { recursive: true });
  const root = await mkdtemp(join(qaRoot, 'contextual-mcp-'));
  const file = join(root, 'project.json');
  const items = join(root, 'items.json');
  const beta = canonicalPokemonRulesetProfile();
  const profile = { ...beta, profileId: 'pokemap-contextual-v1', capturePolicyId: 'pokemap-contextual-items-mvp-fallback-v1', disabledFeatures: ['breeding', 'modern-gimmicks', 'online'] };
  await writeFile(file, JSON.stringify({ name: 'Contextual fixture', version: 'v8', maps: [], tilesets: [], pokemon: { ...canonicalPokemonConfig(), enabled: false, catalogFiles: { items: 'items.json' } } }));
  await writeFile(items, JSON.stringify({ schemaVersion: 1, entries: [{ id: 'eighth-synthetic-orb', displayName: 'Orb', pocketId: 'balls' }] }));
  const originalItems = await readFile(items);
  const policy = { policyId: 'pokemap-contextual-capture-v1', rateRules: [{ when: { kind: 'all', conditions: [{ kind: 'match', field: 'targetSpecies', values: ['eighth-synthetic-species'] }, { kind: 'numeric', left: { field: 'targetLevel' }, comparison: 'lessThan', right: { field: 'attackerLevel', divisor: 2 } }] }, adjustment: { kind: 'multiply', numerator: 7, denominator: 3 } }], successEffects: [{ kind: 'setFriendship', value: 123 }] };
  const parameters = { itemId: 'eighth-synthetic-orb', capture: { rateNumerator: 3, rateDenominator: 2, allowedEncounterKinds: ['walk'], contextualPolicy: policy } };
  const client = new Client({ name: 'contextual-capture-proof', version: '1.0.0' });
  const transport = new StdioClientTransport({ command: process.execPath, args: [resolve('dist/src/index.js'), '--root', root, '--authoring-timeout-ms', '60000'], cwd: process.cwd(), stderr: 'pipe' });
  let workspace: JsonRecord;
  let sequence = 0;
  async function call(name: string, args: JsonRecord = {}, failure = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: args })).structuredContent);
    assert.equal(envelope.ok, !failure, JSON.stringify(envelope));
    return record(envelope[failure ? 'error' : 'data']);
  }
  async function plan(actionId: string, params: JsonRecord, failure = false): Promise<JsonRecord> {
    const scope = await call('pokemap_workshop', { operation: 'read', projectHandle: workspace.projectHandle, actionId, parameters: params });
    const key = `contextual-${++sequence}`;
    return call('pokemap_plan', { projectHandle: workspace.projectHandle, request: { requestId: key, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle, expectedRevision: scope.snapshotRevision, idempotencyKey: key, parameters: params, extensions: scope.planExtensions } }, failure);
  }
  async function apply(planned: JsonRecord): Promise<JsonRecord> {
    return call('pokemap_apply', { operation: 'apply', projectHandle: workspace.projectHandle, planId: planned.planId, operationId: `apply-${sequence}` });
  }
  try {
    await client.connect(transport);
    const description = await call('pokemap_describe', { actionIds: ['pokemon.ruleset.set', 'item.set_capture_effect'] });
    const actions = description.mutationActions as JsonRecord[];
    const ruleset = record(actions.find(entry => entry.id === 'pokemon.ruleset.set'));
    assert.ok(JSON.stringify(ruleset).includes('pokemap-contextual-v1'));
    const capture = record(actions.find(entry => entry.id === 'item.set_capture_effect'));
    const schema = record(record(capture.extensions).inputSchema);
    const ajv = new Ajv({ strict: false, allowUnionTypes: true });
    const validate = ajv.compile(schema);
    assert.equal(validate(parameters), true, JSON.stringify(validate.errors));
    assert.equal(validate({ ...parameters, capture: { ...parameters.capture, contextualPolicy: { ...policy, rateRules: [{ when: { kind: 'eval', code: 'true' }, adjustment: { kind: 'add', amount: 1 } }] } } }), false);
    workspace = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
    const refused = await plan('item.set_capture_effect', parameters, true);
    assert.equal(refused.domainCode, 'item.catalog_invalid');
    assert.deepEqual(await readFile(items), originalItems);
    await apply(await plan('pokemon.ruleset.set', { profile }));
    const beforeItems = await readFile(file);
    const planned = await plan('item.set_capture_effect', parameters);
    assert.deepEqual(await readFile(items), originalItems);
    const applied = await apply(planned);
    assert.deepEqual(record(record((record(JSON.parse(await readFile(items, 'utf8'))).entries as JsonRecord[])[0]).capture).contextualPolicy, policy);
    assert.deepEqual(await readFile(file), beforeItems);
    const savedItems = await readFile(items);
    const downgrade = await plan('pokemon.ruleset.set', { profile: beta }, true);
    assert.equal(downgrade.domainCode, 'pokemon.ruleset.contextual_items_in_use');
    assert.deepEqual(await readFile(items), savedItems);
    const receipt = record(applied.receipt);
    await call('pokemap_history', { operation: 'undo', projectHandle: workspace.projectHandle, entryId: receipt.receiptId, idempotencyKey: 'contextual-undo' });
    assert.deepEqual(await readFile(items), originalItems);
    await call('pokemap_workspace', { operation: 'close', workspaceHandle: workspace.workspaceHandle });
    workspace = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
    await apply(await plan('pokemon.ruleset.set', { profile: beta }));
    assert.deepEqual(await readFile(items), originalItems);
    await call('pokemap_workspace', { operation: 'close', workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});
