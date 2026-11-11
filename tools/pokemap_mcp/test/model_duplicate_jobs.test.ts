import assert from "node:assert/strict";
import test from "node:test";
import type { AuthoringGateway } from "../src/authoring_client.js";
import { ModelDuplicateJobs } from "../src/model_duplicate_jobs.js";

test("a running audit can be cancelled and cannot be read from another project", async () => {
  let unblock!: () => void;
  const waiting = new Promise<void>(resolve => { unblock = resolve; });
  let requests = 0;
  const authoring: AuthoringGateway = {
    async request() {
      requests++;
      await waiting;
      return { requestId: "test", artifacts: [], data: { items: [], snapshotRevision: "revision" } };
    },
    async close() {},
  };
  const jobs = new ModelDuplicateJobs(authoring);
  const started = jobs.start("project-a");
  const jobId = String(started.jobId);
  await assert.rejects(jobs.status("project-b", jobId, 0, 25),
    error => (error as { code?: string }).code === "model_duplicates.job_not_found");
  assert.equal((await jobs.status("project-a", jobId, 0, 25)).status, "running");
  assert.throws(() => jobs.release("project-a", jobId),
    error => (error as { code?: string }).code === "model_duplicates.job_running");
  assert.equal(jobs.cancel("project-a", jobId).status, "cancelling");
  unblock();
  let status;
  for (let attempt = 0; attempt < 20; attempt++) {
    status = await jobs.status("project-a", jobId, 0, 25);
    if (status.status === "cancelled") break;
    await new Promise(resolve => setTimeout(resolve, 0));
  }
  assert.equal(status?.status, "cancelled");
  assert.equal(requests, 1);
  assert.equal(jobs.release("project-a", jobId).released, true);
  await assert.rejects(jobs.status("project-a", jobId, 0, 25),
    error => (error as { code?: string }).code === "model_duplicates.job_not_found");
});

test("completed audit pages are refused if their catalogue changes later", async () => {
  let assetChanged = false;
  const authoring: AuthoringGateway = {
    async request(_command, args) {
      const request = args?.request as { resourceKind: string };
      return { requestId: "test", artifacts: [], data: { items: [], totalAvailable: 0,
        snapshotRevision: request.resourceKind === "asset" && assetChanged ? "changed" : "original" } };
    },
    async close() {},
  };
  const jobs = new ModelDuplicateJobs(authoring);
  const started = jobs.start("project");
  const jobId = String(started.jobId);
  let status;
  for (let attempt = 0; attempt < 20; attempt++) {
    status = await jobs.status("project", jobId, 0, 25);
    if (status.status === "completed") break;
    await new Promise(resolve => setTimeout(resolve, 0));
  }
  assert.equal(status?.status, "completed");
  assetChanged = true;
  await assert.rejects(jobs.status("project", jobId, 0, 25),
    error => (error as { code?: string }).code === "model_duplicates.stale");
  jobs.release("project", jobId);
});
