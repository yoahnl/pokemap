import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { mkdir, mkdtemp, readFile, rm } from 'node:fs/promises';
import { join, resolve } from 'node:path';
import { promisify } from 'node:util';
import test from 'node:test';
import { Client } from '@modelcontextprotocol/client';
import { StdioClientTransport } from '@modelcontextprotocol/client/stdio';
import type { JsonRecord } from '../src/authoring_client.js';

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === 'object' && !Array.isArray(value));
  return value as JsonRecord;
}

test('catalog companion and contact singleton queries stay local through live MCP', { timeout: 120_000 }, async () => {
  await mkdir('/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7/platforms', { recursive: true });
  const root = await mkdtemp('/Users/karim/Library/Caches/AveluneQA/ecorcia-chapitre7/platforms/config-mcp-');
  const dart = process.env.POKEMAP_TEST_DART ?? 'dart';
  const packageRoot = resolve('../../packages/map_authoring');
  const client = new Client({ name: 'catalog-companion-proof', version: '1.0.0' });
  const transport = new StdioClientTransport({ command: process.execPath, args: [resolve('dist/src/index.js'), '--root', root, '--dart', dart, '--authoring-timeout-ms', '60000'], cwd: process.cwd(), stderr: 'pipe' });
  async function call(name: string, parameters: JsonRecord, failed = false): Promise<JsonRecord> {
    const envelope = record((await client.callTool({ name, arguments: parameters })).structuredContent);
    assert.equal(envelope.ok, !failed, JSON.stringify(envelope));
    return record(envelope[failed ? 'error' : 'data']);
  }
  try {
    await promisify(execFile)(dart, [`--packages=${join(packageRoot, '.dart_tool/package_config.json')}`, join(packageRoot, 'test/support/create_working_catalog_fixture.dart'), root, '--companion'], { timeout: 60_000 });
    const descriptor = await readFile(join(root, 'project.json'));
    const foreign = await readFile(join(root, 'maps/foreign.json'));
    await client.connect(transport);
    const catalog = await call('pokemap_describe', {});
    assert.ok((catalog.resourceKinds as JsonRecord[]).some(value => value.id === 'partyCompanionConfiguration'));
    let opened = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
    async function query(kind: string, extensions: JsonRecord = {}): Promise<JsonRecord> {
      return call('pokemap_query', { projectHandle: opened.projectHandle, resourceKind: kind, operation: 'get', ids: ['project'], view: 'detail', extensions });
    }
    assert.equal(record(((await query('partyCompanionConfiguration')).items as JsonRecord[])[0]).enabled, false);
    assert.equal(record(((await query('contactDeviceConfiguration')).items as JsonRecord[])[0]).configuration, null);
    const parameters = { enabled: true, mappings: [{ speciesId: 'bird', formId: 'bronze', characterId: 'follower' }] };
    const before = await readFile(join(root, 'catalog/HEAD.json'));
    const scoped = await query('partyCompanionConfiguration', { actionId: 'party_companion.configure', parameters });
    const plan = await call('pokemap_plan', { projectHandle: opened.projectHandle, request: { requestId: 'configure', actionId: 'party_companion.configure', actionVersion: 1, workspaceHandle: opened.workspaceHandle, expectedRevision: scoped.snapshotRevision, parameters, idempotencyKey: 'configure' } });
    assert.deepEqual(await readFile(join(root, 'catalog/HEAD.json')), before);
    const applied = await call('pokemap_apply', { operation: 'apply', projectHandle: opened.projectHandle, planId: plan.planId, operationId: 'configure' });
    assert.equal(record(((await query('partyCompanionConfiguration')).items as JsonRecord[])[0]).enabled, true);
    const invalid = { enabled: true, mappings: [{ speciesId: 'bird', formId: 'bronze', characterId: 'missing' }] };
    const invalidScope = await query('partyCompanionConfiguration', { parameters: invalid });
    const accepted = await readFile(join(root, 'catalog/HEAD.json'));
    await call('pokemap_plan', { projectHandle: opened.projectHandle, request: { requestId: 'invalid', actionId: 'party_companion.configure', actionVersion: 1, workspaceHandle: opened.workspaceHandle, expectedRevision: invalidScope.snapshotRevision, parameters: invalid, idempotencyKey: 'invalid' } }, true);
    assert.deepEqual(await readFile(join(root, 'catalog/HEAD.json')), accepted);
    await call('pokemap_history', { operation: 'undo', projectHandle: opened.projectHandle, entryId: record(applied.receipt).receiptId, idempotencyKey: 'undo' });
    assert.deepEqual(await readFile(join(root, 'catalog/HEAD.json')), before);
    await call('pokemap_workspace', { operation: 'close', workspaceHandle: opened.workspaceHandle });
    opened = await call('pokemap_workspace', { operation: 'open', projectRoot: root });
    assert.equal(record(((await query('partyCompanionConfiguration')).items as JsonRecord[])[0]).enabled, false);
    assert.deepEqual(await readFile(join(root, 'project.json')), descriptor);
    assert.deepEqual(await readFile(join(root, 'maps/foreign.json')), foreign);
    await call('pokemap_workspace', { operation: 'close', workspaceHandle: opened.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(root, { recursive: true, force: true });
  }
});
