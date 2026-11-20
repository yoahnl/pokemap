import assert from 'node:assert/strict';
import { execFile } from 'node:child_process';
import { mkdir, mkdtemp, readFile, rm } from 'node:fs/promises';
import { homedir } from 'node:os';
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

test('MCP reopens and undoes file and usage replacements in a partitioned 3D catalog', { timeout: 210_000 }, async () => {
  const base = join(homedir(), 'Library/Caches/AveluneQA/model-replacement');
  await mkdir(base, { recursive: true });
  const temporary = await mkdtemp(join(base, 'mcp-'));
  const root = join(temporary, 'project');
  const authoring = resolve('../../packages/map_authoring');
  const dart = process.env.POKEMAP_TEST_DART ?? 'dart';
  const client = new Client({ name: 'model-replacement-proof', version: '1.0.0' });
  const transport = new StdioClientTransport({ command: process.execPath,
    args: [resolve('dist/src/index.js'), '--root', root, '--dart', dart, '--authoring-timeout-ms', '60000'],
    cwd: process.cwd(), stderr: 'pipe' });
  async function call(name: string, input: JsonRecord, fails = false) {
    const result = await client.callTool({ name, arguments: input });
    const envelope = record(result.structuredContent);
    assert.equal(envelope.ok, !fails, JSON.stringify(envelope));
    return record(envelope[fails ? 'error' : 'data']);
  }
  try {
    await promisify(execFile)(dart, [`--packages=${join(authoring, '.dart_tool/package_config.json')}`,
      join(authoring, 'test/support/create_model_replacement_fixture.dart'), root], { timeout: 90_000 });
    await client.connect(transport);
    const catalog = await call('pokemap_describe', {});
    for (const id of ['model3d.source.replace', 'resource.usages.replace']) {
      assert.ok((catalog.mutationActions as JsonRecord[]).some((action) => action.id === id));
    }
    const open = () => call('pokemap_workspace', { operation: 'open', projectRoot: root });
    let workspace = await open();
    async function reopen() {
      await call('pokemap_workspace', { operation: 'close', workspaceHandle: workspace.workspaceHandle });
      workspace = await open();
    }
    const original = {
      source: await readFile(join(root, 'assets/models3d/tree.glb')),
      other: await readFile(join(root, 'assets/models3d/alternate.glb')),
      map: await readFile(join(root, 'maps/map.json')),
    };
    const workshopRead = (actionId: string, parameters: JsonRecord) => call('pokemap_workshop', {
      operation: 'read', projectHandle: workspace.projectHandle, actionId, parameters,
    });
    async function plan(actionId: string, parameters: JsonRecord, id: string) {
      const snapshot = await workshopRead(actionId, parameters);
      return call('pokemap_plan', { projectHandle: workspace.projectHandle, request: {
        requestId: id, actionId, actionVersion: 1, workspaceHandle: workspace.workspaceHandle,
        parameters, expectedRevision: snapshot.snapshotRevision, extensions: snapshot.planExtensions, idempotencyKey: id,
      } });
    }
    async function undo(entryId: unknown, idempotencyKey: string) {
      await call('pokemap_history', { operation: 'undo', projectHandle: workspace.projectHandle, entryId, idempotencyKey });
      await reopen();
    }

    const incoming = join(root, 'candidate.glb');
    const staged = await call('pokemap_artifact_stage', { sourcePath: incoming, declaredMediaType: 'model/gltf-binary' });
    const file = await plan('model3d.source.replace', { modelId: 'tree', artifactHandle: staged.artifactHandle }, 'plan-file');
    assert.deepEqual(await readFile(join(root, 'assets/models3d/tree.glb')), original.source);
    const fileResult = await call('pokemap_apply', { operation: 'apply', projectHandle: workspace.projectHandle,
      planId: file.planId, operationId: 'replace-file' });
    await reopen();
    assert.deepEqual(await readFile(join(root, 'assets/models3d/tree.glb')), await readFile(incoming));
    assert.deepEqual(await readFile(join(root, 'assets/models3d/alternate.glb')), original.other);
    assert.deepEqual(await readFile(join(root, 'maps/map.json')), original.map);
    await undo(record(fileResult.receipt).receiptId, 'undo-file');
    assert.deepEqual(await readFile(join(root, 'assets/models3d/tree.glb')), original.source);

    const params = { family: 'models3d', resourceId: 'tree', replacementId: 'alternate' };
    const usages = await plan('resource.usages.replace', params, 'plan-usages');
    const impacts = record(record(usages.plan).preview);
    assert.equal(impacts.mapCount, 1);
    assert.equal(impacts.occurrenceCount, 3);
    assert.equal(impacts.regeneratedInstanceCount, 3);
    assert.deepEqual(impacts.repointedBorderIds, ['fence']);
    const apply = { operation: 'apply', projectHandle: workspace.projectHandle, planId: usages.planId };
    await call('pokemap_apply', { ...apply, operationId: 'repoint-model' }, true);
    assert.deepEqual(await readFile(join(root, 'maps/map.json')), original.map);
    const confirmation = await call('pokemap_apply', { ...apply, operation: 'confirm' });
    const replacement = await call('pokemap_apply', { ...apply,
      operationId: 'repoint-model', confirmationToken: confirmation.confirmationToken });
    await reopen();
    const updatedMap = record(JSON.parse(await readFile(join(root, 'maps/map.json'), 'utf8')));
    const instances = record(updatedMap.spatialScene).instances as JsonRecord[];
    assert.deepEqual(instances.map((instance) => instance.modelId), ['alternate', 'alternate', 'alternate']);
    const reverse = { ...params, resourceId: 'alternate', replacementId: 'tree' };
    async function borderSources(parameters: JsonRecord) {
      const view = await workshopRead('resource.usages.replace', parameters);
      const borders = record(record(view.project).borderCatalog).records as JsonRecord[];
      return [borders[0]?.draft, borders[0]?.latestPublished].flatMap((version) =>
        (record(record(version).definition).primitives as JsonRecord[]).map((piece) => piece.sourceModelId));
    }
    assert.deepEqual(new Set(await borderSources(reverse)), new Set(['alternate']));
    await undo(record(replacement.receipt).receiptId, 'undo-usages');
    assert.deepEqual(await readFile(join(root, 'maps/map.json')), original.map);
    assert.deepEqual(new Set(await borderSources(params)), new Set(['tree']));
    assert.deepEqual(await readFile(join(root, 'assets/models3d/tree.glb')), original.source);
    assert.deepEqual(await readFile(join(root, 'assets/models3d/alternate.glb')), original.other);
    await call('pokemap_workspace', { operation: 'close', workspaceHandle: workspace.workspaceHandle });
  } finally {
    await client.close();
    await transport.close();
    await rm(temporary, { recursive: true, force: true });
  }
});
