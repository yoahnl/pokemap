import { randomUUID } from "node:crypto";
import type { AuthoringGateway, JsonRecord } from "./authoring_client.js";
import { auditDuplicateModels, verifyDuplicateModelAudit } from "./model_duplicates.js";
import { PokeMapToolError } from "./tool_error.js";

type AuditJob = {
  id: string;
  projectHandle: string;
  status: "running" | "cancelling" | "cancelled" | "completed" | "failed";
  scannedModels: number;
  updatedAt: number;
  result?: JsonRecord;
  error?: unknown;
};

const retentionMs = 30 * 60 * 1000;
const maximumJobs = 4;
const maximumMembersPerGroup = 20;

export class ModelDuplicateJobs {
  readonly #jobs = new Map<string, AuditJob>();

  constructor(readonly authoring: AuthoringGateway) {}

  start(projectHandle: string): JsonRecord {
    const now = Date.now();
    for (const [id, job] of this.#jobs) {
      if (job.status !== "running" && job.status !== "cancelling" && now - job.updatedAt > retentionMs) {
        this.#jobs.delete(id);
      }
    }
    if (this.#jobs.size >= maximumJobs) {
      throw new PokeMapToolError("model_duplicates.job_limit",
        "Too many model audits are retained in this session.", false,
        ["Release a completed audit before starting another."]);
    }
    const job: AuditJob = { id: randomUUID(), projectHandle, status: "running",
      scannedModels: 0, updatedAt: now };
    this.#jobs.set(job.id, job);
    void auditDuplicateModels(this.authoring, projectHandle, 0, Number.MAX_SAFE_INTEGER,
      undefined, scannedModels => {
        if (job.status === "cancelling") {
          throw new PokeMapToolError("model_duplicates.cancelled", "The model audit was cancelled.");
        }
        job.scannedModels = scannedModels;
        job.updatedAt = Date.now();
      }).then(result => {
        if (job.status === "cancelling") {
          job.status = "cancelled";
        } else {
          job.result = result;
          job.status = "completed";
        }
        job.updatedAt = Date.now();
      }, error => {
        job.status = job.status === "cancelling" ? "cancelled" : "failed";
        job.error = error;
        job.updatedAt = Date.now();
      });
    return { jobId: job.id, status: job.status, scannedModels: 0 };
  }

  async status(projectHandle: string, jobId: string, offset: number,
    pageSize: number, expectedAuditRevision?: string, memberOffset = 0): Promise<JsonRecord> {
    const job = this.#job(projectHandle, jobId);
    job.updatedAt = Date.now();
    if (job.status === "failed") throw job.error;
    if (job.status !== "completed" || !job.result) {
      return { jobId, status: job.status, scannedModels: job.scannedModels };
    }
    const result = job.result;
    if (expectedAuditRevision && expectedAuditRevision !== result.auditRevision) {
      throw new PokeMapToolError("model_duplicates.stale",
        "The requested audit revision differs from the stored result.", true,
        ["Start a new audit before using its results."]);
    }
    await verifyDuplicateModelAudit(this.authoring, projectHandle,
      result.modelRevision as string, result.assetRevision as string);
    const groups = result.groups as JsonRecord[];
    return { ...result, jobId, status: job.status, scannedModels: job.scannedModels,
      groups: groups.slice(offset, offset + pageSize).map(group => {
        const models = group.models as JsonRecord[];
        return { ...group, models: models.slice(memberOffset, memberOffset + maximumMembersPerGroup),
          modelsTruncated: models.length > maximumMembersPerGroup,
          ...(memberOffset + maximumMembersPerGroup < models.length
            ? { nextMemberOffset: memberOffset + maximumMembersPerGroup } : {}) };
      }),
      ...(offset + pageSize < groups.length ? { nextOffset: offset + pageSize } : {}) };
  }

  cancel(projectHandle: string, jobId: string): JsonRecord {
    const job = this.#job(projectHandle, jobId);
    if (job.status === "running") job.status = "cancelling";
    job.updatedAt = Date.now();
    return { jobId, status: job.status, scannedModels: job.scannedModels };
  }

  release(projectHandle: string, jobId: string): JsonRecord {
    const job = this.#job(projectHandle, jobId);
    if (job.status === "running" || job.status === "cancelling") {
      throw new PokeMapToolError("model_duplicates.job_running",
        "Cancel the running audit before releasing it.", true);
    }
    this.#jobs.delete(jobId);
    return { jobId, released: true };
  }

  #job(projectHandle: string, jobId: string): AuditJob {
    const job = this.#jobs.get(jobId);
    if (!job || job.projectHandle !== projectHandle) {
      throw new PokeMapToolError("model_duplicates.job_not_found",
        "The audit is not available in this project session.", false,
        ["Start a new audit for the open project."]);
    }
    return job;
  }
}
