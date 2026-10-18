import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { promisify } from "node:util";
import test from "node:test";
import { resourcePackToolSchema } from "../src/tools/resource_packs.js";
import { connectPackMcp, controlledPackDart, packRecord } from "./resource_pack_stdio_support.js";

test("diagnostic schema accepts readonly scope and refuses quota overrides", () => {
  const base = { projectHandle: "project", verb: "diagnose", input: {
    expectedRevision: `sha256:${"0".repeat(64)}`,
  } };
  assert.ok(resourcePackToolSchema.safeParse(base).success);
  assert.ok(resourcePackToolSchema.safeParse({ ...base, input: {
    ...base.input, selectionHandle: "selection", revision: base.input.expectedRevision,
  } }).success);
  assert.equal(resourcePackToolSchema.safeParse({ ...base, input: {
    ...base.input, maxSupports: 50000,
  } }).success, false);
  assert.equal(resourcePackToolSchema.safeParse({ ...base, input: {
    ...base.input, selectionHandle: "selection",
  } }).success, false);
});

test("live MCP prepares a selection above the former 10000 definition limit", { timeout: 120000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "l0-pack-refusal-"));
  let mcp: Awaited<ReturnType<typeof connectPackMcp>> | undefined;
  try {
    const generated = await promisify(execFile)("dart", ["run", "test/support/resource_pack_transport_fixture.dart", root], {
      cwd: resolve("../../packages/map_authoring"),
    });
    const metadata = packRecord(JSON.parse(generated.stdout.trim())).metadata;
    mcp = await connectPackMcp(root, process.env.POKEMAP_RESOURCE_PACK_TEST_WORKER
      ? await controlledPackDart(root) : undefined);
    let opened = await mcp.call("pokemap_workspace", { operation: "open", projectRoot: join(root, "target") });
    const plan = await mcp.plan(opened, "l0-fixture-import");
    const archiveSelection = packRecord(plan.selection);
    const archiveValidation = await mcp.call("pokemap_validate", { projectHandle: opened.projectHandle });
    const archiveDiagnosis = await mcp.result(opened, await mcp.pack(opened, "diagnose", {
      selectionHandle: archiveSelection.selectionHandle, revision: archiveSelection.revision,
      expectedRevision: archiveValidation.snapshotRevision,
    }));
    const archiveReport = (archiveDiagnosis.budgetReports as Record<string, unknown>[])
      .find((value) => value.scope === "inspectedArchive")!;
    assert.ok(Number(packRecord(archiveReport.totals).fileBytes) > 0);
    assert.ok(Number(packRecord(archiveReport.totals).imagePixels) > 0);
    await mcp.result(opened, await mcp.pack(opened, "start_apply", { planId: plan.planId, operationId: "l0-fixture-import" }));
    await mcp.call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
    const path = join(root, "target", "project.json");
    const fixture = JSON.parse(await readFile(path, "utf8")) as Record<string, unknown>;
    const element = packRecord((fixture.elements as unknown[])[0]);
    fixture.elements = [...fixture.elements as unknown[], ...Array.from({ length: 10001 }, (_, index) => ({ ...element,
      id: `l0-element-${index}`,
    }))];
    await writeFile(path, JSON.stringify(fixture));
    const before = await readFile(path);
    opened = await mcp.call("pokemap_workspace", { operation: "open", projectRoot: join(root, "target") });
    const selected = await mcp.pack(opened, "selection.create", { mode: "native" });
    const chosen = await mcp.pack(opened, "selection.select_filtered", {
      selectionHandle: selected.selectionHandle, revision: selected.revision, filter: { kind: "element" },
    });
    const input = { selectionHandle: chosen.selectionHandle, revision: chosen.revision,
      expectedRevision: selected.sourceRevision };
    const settle = async (start: Record<string, unknown>) => {
      for (let attempt = 0; attempt < 300; attempt++) {
        const state = await mcp!.pack(opened, "get", { jobId: start.jobId });
        if (["succeeded", "failed", "cancelled"].includes(String(packRecord(state.snapshot).state))) return state;
        await new Promise((done) => setTimeout(done, 200));
      }
      throw new Error("The bounded budget job did not settle.");
    };
    const diagnosed = await settle(await mcp.pack(opened, "diagnose", input));
    assert.equal(packRecord(diagnosed.snapshot).state, "succeeded");
    const diagnosis = packRecord(diagnosed.result);
    const report = (diagnosis.budgetReports as Record<string, unknown>[]).find((value) => value.scope === "nativeSelection")!;
    assert.deepEqual(report.violations, []);
    const preparedStart = await mcp.pack(opened, "prepare", { ...input, metadata, author: "L4 fixture" });
    const prepared = await settle(preparedStart);
    assert.equal(packRecord(prepared.snapshot).state, "succeeded", JSON.stringify(prepared));
    assert.equal(typeof packRecord(prepared.result).preparedExportHandle, "string");
    const queried = await mcp.call("pokemap_query", { projectHandle: opened.projectHandle,
      resourceKind: "resourcePackJob", operation: "get", ids: [preparedStart.jobId] });
    assert.deepEqual(packRecord((queried.items as unknown[])[0]).result, prepared.result);
    assert.deepEqual(await readFile(path), before);
    await mcp.call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await mcp?.close();
    await rm(root, { recursive: true, force: true });
  }
});

test("live MCP advertises volume diagnostics and leaves the project intact", { timeout: 120000 }, async () => {
  const root = await mkdtemp(join(tmpdir(), "l0-pack-budget-"));
  let mcp: Awaited<ReturnType<typeof connectPackMcp>> | undefined;
  try {
    await promisify(execFile)("dart", ["run", "test/support/resource_pack_transport_fixture.dart", root], {
      cwd: resolve("../../packages/map_authoring"),
    });
    const path = join(root, "target", "project.json");
    const before = await readFile(path);
    mcp = await connectPackMcp(root, process.env.POKEMAP_RESOURCE_PACK_TEST_WORKER
      ? await controlledPackDart(root) : undefined);
    const description = await mcp.call("pokemap_describe");
    const contract = packRecord(description.resourcePackTransfer);
    assert.ok((contract.verbs as string[]).includes("diagnose"));
    const opened = await mcp.call("pokemap_workspace", { operation: "open", projectRoot: join(root, "target") });
    const validation = await mcp.call("pokemap_validate", { projectHandle: opened.projectHandle });
    const result = await mcp.result(opened, await mcp.pack(opened, "diagnose", {
      expectedRevision: validation.snapshotRevision,
    }));
    const reports = result.budgetReports as Record<string, unknown>[];
    assert.equal(reports.length, 1);
    assert.equal(reports[0]!.scope, "sourceProjectDistribution");
    assert.equal(packRecord(reports[0]!.totals).sourceDocumentBytes, before.length);
    assert.ok(Number(packRecord(reports[0]!.totals).catalogBytes) > 0);
    assert.equal(result.mergedProjectMeasured, false);
    assert.deepEqual(await readFile(path), before);
    await mcp.call("pokemap_workspace", { operation: "close", workspaceHandle: opened.workspaceHandle });
  } finally {
    await mcp?.close();
    await rm(root, { recursive: true, force: true });
  }
});
