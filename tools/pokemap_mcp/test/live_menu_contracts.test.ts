import assert from "node:assert/strict";
import { cp, mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { test } from "node:test";

import { Client } from "@modelcontextprotocol/client";
import { StdioClientTransport } from "@modelcontextprotocol/client/stdio";

import type { JsonRecord } from "../src/authoring_client.js";

function record(value: unknown): JsonRecord {
  assert.ok(value && typeof value === "object" && !Array.isArray(value));
  return value as JsonRecord;
}

async function toolData(
  client: Client,
  name: string,
  args: JsonRecord = {},
): Promise<JsonRecord> {
  const result = await client.callTool({ name, arguments: args });
  assert.equal(result.isError, undefined, JSON.stringify(result.structuredContent));
  const envelope = record(result.structuredContent);
  assert.equal(envelope.ok, true);
  return record(envelope.data);
}

test(
  "MENU-A packaged MCP authors quests and profile labels and scene visibility",
  { timeout: 120_000 },
  async () => {
    const temporaryRoot = await mkdtemp(join(tmpdir(), "pokemap-live-menu-"));
    const projectRoot = join(temporaryRoot, "project");
    await cp(
      resolve(process.cwd(), "../../examples/playable_runtime_host/golden_item_system"),
      projectRoot,
      { recursive: true },
    );
    const projectPath = join(projectRoot, "project.json");
    const transport = new StdioClientTransport({
      command: process.execPath,
      args: [resolve(process.cwd(), "dist/src/index.js"), "--root", projectRoot],
      cwd: process.cwd(),
      stderr: "pipe",
    });
    const client = new Client({ name: "pokemap-live-menu-contracts", version: "1.0.0" });

    try {
      await client.connect(transport);
      const description = await toolData(client, "pokemap_describe");
      const actions = description.mutationActions as JsonRecord[];
      for (const actionId of [
        "presentation.update",
        "scene.upsert",
        "scene.pause_menu_visibility.set",
      ]) {
        assert.ok(actions.some((action) => action.id === actionId), actionId);
      }
      const presentationKind = (description.resourceKinds as JsonRecord[]).find(
        (kind) => kind.id === "projectPresentationProfile",
      );
      assert.equal(presentationKind?.version, 10);

      const opened = await toolData(client, "pokemap_workspace", {
        operation: "open",
        projectRoot,
      });
      const projectHandle = String(opened.projectHandle);
      const workspaceHandle = String(opened.workspaceHandle);
      const baseline = await toolData(client, "pokemap_validate", { projectHandle });
      let revision = String(baseline.snapshotRevision);

      async function apply(actionId: string, parameters: JsonRecord, sequence: string) {
        const planned = await toolData(client, "pokemap_plan", {
          projectHandle,
          request: {
            requestId: `menu-${sequence}`,
            actionId,
            actionVersion: 1,
            workspaceHandle,
            parameters,
            expectedRevision: revision,
            idempotencyKey: `menu-${sequence}`,
            dryRun: false,
          },
        });
        assert.equal(record(planned.receipt).status, "planned");
        assert.equal(record(planned.plan).applicable, true);
        assert.ok(record(record(planned.plan).preview));
        const applied = await toolData(client, "pokemap_apply", {
          operation: "apply",
          projectHandle,
          planId: planned.planId,
          operationId: `menu-${sequence}`,
        });
        assert.equal(record(applied.receipt).status, "applied");
        assert.equal(record(applied.receipt).actionId, actionId);
        assert.notEqual(applied.snapshotRevision, revision);
        revision = String(applied.snapshotRevision);
      }

      const pauseActions = [
        { id: "quests", label: "Journal", icon: "book", visible: true },
        { id: "profile", label: "Dresseur", icon: "person", visible: true },
        { id: "resume", label: "Reprendre", icon: "play", visible: true },
      ];
      await apply("presentation.update", {
        profile: {
          schemaVersion: 10,
          pause: { title: "Escale", actions: pauseActions },
        },
      }, "presentation");
      const presentationQuery = await toolData(client, "pokemap_query", {
        projectHandle,
        resourceKind: "projectPresentationProfile",
        operation: "list",
        view: "detail",
      });
      assert.equal(presentationQuery.snapshotRevision, revision);
      const profile = record(record((presentationQuery.items as unknown[])[0]).profile);
      assert.equal(profile.schemaVersion, 10);
      assert.deepEqual(record(profile.pause).actions, pauseActions);

      await apply("scene.upsert", {
        scene: {
          id: "menu_visibility",
          name: "Menu visibility",
          graph: {
            startNodeId: "start",
            nodes: [
              { id: "start", kind: "start" },
              ...["quests", "profile"].map((id) => ({
                id,
                kind: "action",
                payload: {
                  kind: "action",
                  interactiveCommand: { kind: "openPc" },
                },
              })),
              { id: "end", kind: "end" },
            ],
            edges: [
              { id: "start_quests", fromNodeId: "start", fromPortId: "completed", toNodeId: "quests", kind: "default" },
              { id: "quests_profile", fromNodeId: "quests", fromPortId: "completed", toNodeId: "profile", kind: "actionCompleted" },
              { id: "profile_end", fromNodeId: "profile", fromPortId: "completed", toNodeId: "end", kind: "actionCompleted" },
            ],
          },
        },
      }, "scene");

      for (const actionId of ["quests", "profile"]) {
        await apply("scene.pause_menu_visibility.set", {
          sceneId: "menu_visibility",
          nodeId: actionId,
          actionId,
          visible: false,
        }, `hide-${actionId}`);
      }

      const sceneQuery = await toolData(client, "pokemap_query", {
        projectHandle,
        resourceKind: "scene",
        operation: "get",
        view: "detail",
        ids: ["menu_visibility"],
      });
      assert.equal(sceneQuery.snapshotRevision, revision);
      const queriedScene = record((sceneQuery.items as unknown[])[0]);
      const persisted = record(JSON.parse(await readFile(projectPath, "utf8")));
      const persistedScene = (persisted.scenes as JsonRecord[]).find(
        (scene) => scene.id === "menu_visibility",
      );
      assert.ok(persistedScene);
      for (const scene of [queriedScene, persistedScene]) {
        const nodes = record(scene.graph).nodes as JsonRecord[];
        for (const actionId of ["quests", "profile"]) {
          const node = nodes.find((candidate) => candidate.id === actionId);
          assert.deepEqual(record(record(node).payload).consequence, {
            kind: "setPauseMenuEntryVisibility",
            actionId,
            visible: false,
          });
        }
      }
      assert.deepEqual(record(record(persisted.presentation).pause).actions, pauseActions);

      const beforeRejectedPlan = await readFile(projectPath, "utf8");
      const rejected = await client.callTool({
        name: "pokemap_plan",
        arguments: {
          projectHandle,
          request: {
            requestId: "menu-invalid-entry",
            actionId: "scene.pause_menu_visibility.set",
            actionVersion: 1,
            workspaceHandle,
            parameters: { sceneId: "menu_visibility", nodeId: "quests", actionId: "inventedMenu", visible: false },
            expectedRevision: revision,
            idempotencyKey: "menu-invalid-entry",
            dryRun: false,
          },
        },
      });
      assert.equal(rejected.isError, true);
      assert.equal(record(rejected.structuredContent).ok, false);
      assert.equal(record(record(rejected.structuredContent).error).code, "invalid_request");
      assert.equal(record(record(rejected.structuredContent).error).domainCode, "worker.request_invalid");
      assert.equal(await readFile(projectPath, "utf8"), beforeRejectedPlan);

      const validated = await toolData(client, "pokemap_validate", { projectHandle });
      assert.equal(validated.snapshotRevision, revision);
      assert.deepEqual(validated.structure, baseline.structure);
      assert.equal(record(validated.structure).valid, true);
      assert.deepEqual(
        record(validated.references).diagnostics,
        record(baseline.references).diagnostics,
      );
      assert.equal(record(validated.references).valid, true);
      assert.deepEqual(validated.pokemonCatalog, baseline.pokemonCatalog);
      const closed = await toolData(client, "pokemap_workspace", {
        operation: "close",
        workspaceHandle,
      });
      assert.equal(closed.closed, true);
    } finally {
      await client.close();
      await rm(temporaryRoot, { recursive: true, force: true });
    }
  },
);
