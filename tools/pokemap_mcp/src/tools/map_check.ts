import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import type { AuthoringGateway, JsonRecord } from "../authoring_client.js";
import type { RuntimeGateway, RuntimeToolResult } from "../runtime_gateway.js";
import { readOnlyAnnotations, toolEnvelopeSchema, toolResult } from "./result.js";

export interface MapCheckRequest {
  projectHandle: string;
  mapId: string;
  visual: "none" | "targets" | "full";
}

export async function checkMapHealth(
  authoring: AuthoringGateway,
  runtime: Pick<RuntimeGateway, "scan3d"> | undefined,
  request: MapCheckRequest,
): Promise<RuntimeToolResult> {
  const response = await authoring.request("query", {
    projectHandle: request.projectHandle,
    request: {resourceKind:"mapHealth",operation:"get",ids:[request.mapId],view:"detail"},
  });
  const item = Array.isArray(response.data.items) ? response.data.items[0] : undefined;
  if (!isRecord(item) || !["pass","fail","incomplete"].includes(String(item.verdict))) {
    throw new Error("The canonical map health response is invalid.");
  }
  const health: JsonRecord = {...item};
  const checks: JsonRecord = isRecord(item.checks) ? {...item.checks} : {};
  const coverage: JsonRecord = {...(isRecord(item.coverage) ? item.coverage : {}), requested:request.visual};
  const issues: JsonRecord[] = Array.isArray(item.issues)
    ? item.issues.filter(isRecord).slice(0,20) : [];
  let count = typeof item.issueCount === "number" ? item.issueCount : issues.length;
  let failed = item.verdict === "fail";
  let incomplete = item.verdict === "incomplete";
  let artifacts: JsonRecord[] = [];
  function issue(code: string, severity: "error" | "unknown", details: JsonRecord = {}): void {
    count++;
    if (issues.length < 20) issues.push({code,severity,...details});
    if (severity === "error") failed = true; else incomplete = true;
  }
  if (request.visual !== "none") {
    if (!runtime) {
      issue("map_check.visual_unavailable","unknown");
      checks.visual = {status:"incomplete",reason:"native_renderer_unavailable"};
    } else {
      try {
        const scan = await runtime.scan3d({...request,maxViews:32,magnification:4,grid:request.visual === "full"});
        const data = scan.data;
        const views = Array.isArray(data.views) ? data.views.filter(isRecord) : [];
        const sameRevision = data.revision === health.revision;
        const complete = sameRevision && Array.isArray(data.errors) && data.errors.length === 0 &&
          data.skippedTargetCount === 0 && typeof data.viewCount === "number" &&
          data.viewCount > 0 && data.viewCount === views.length &&
          (request.visual !== "full" || typeof data.gridViewCount === "number" && data.gridViewCount > 0);
        const visualIssues: JsonRecord[] = [];
        for (const view of views) {
          if (typeof view.holeRatio !== "number" || !Number.isFinite(view.holeRatio) ||
              view.holeRatio < 0 || view.holeRatio > 1) {
            visualIssues.push({code:"map_check.invalid_measurement",severity:"unknown"});
          } else if (view.holeRatio > 0 && sameRevision) {
            visualIssues.push({code:"map_check.enclosed_background",severity:"error",
              kind:view.kind,center:view.center,holeRatio:view.holeRatio,
              ...(view.artifactUri ? {artifactUri:view.artifactUri} : {})});
          }
        }
        if (!complete) issue(sameRevision ? "map_check.coverage_incomplete" : "map_check.revision_changed","unknown");
        for (const problem of visualIssues) issue(String(problem.code),problem.severity as "error" | "unknown",problem);
        const retained = new Set(views.filter(view =>
          typeof view.holeRatio === "number" && view.holeRatio > 0 ||
          view.kind === "borderObjectOverlap" || view.kind === "groundGap")
          .map(view => view.artifactUri));
        artifacts = (scan.artifacts ?? []).filter(artifact => retained.has(artifact.uri));
        checks.visual = {status:!complete || visualIssues.some(problem => problem.severity === "unknown")
          ? "incomplete" : visualIssues.length > 0 ? "fail" : "pass"};
        Object.assign(coverage, {scanRevision:data.revision,viewCount:data.viewCount,
          skippedTargetCount:data.skippedTargetCount,gridViewCount:data.gridViewCount,
          visualProof:"enclosed sentinel-background pixels in the requested views; no universal geometry or fidelity proof"});
      } catch {
        issue("map_check.visual_failed","unknown");
        checks.visual = {status:"incomplete",reason:"native_scan_failed"};
      }
    }
  }
  issues.sort((left,right) => (left.severity === "error" ? 0 : 1) -
    (right.severity === "error" ? 0 : 1) || String(left.code).localeCompare(String(right.code)));
  return {data:{...health,verdict:failed ? "fail" : incomplete ? "incomplete" : "pass",
    checks,coverage,issues,issueCount:count},artifacts};
}

export function registerMapCheckTool(server: McpServer, authoring: AuthoringGateway,
  runtime?: RuntimeGateway): void {
  server.registerTool("pokemap_map_check", {
    title:"Check a map at a known revision",
    description:'Combines canonical map health with optional native views. Reports pass, fail or incomplete and exact coverage. Example: {"projectHandle":"<handle>","mapId":"field","visual":"full"}.',
    inputSchema:z.object({projectHandle:z.string().min(1),mapId:z.string().min(1),
      visual:z.enum(["none","targets","full"]).default("full")}).strict(),
    outputSchema:toolEnvelopeSchema,annotations:readOnlyAnnotations,
  }, async request => toolResult(() => checkMapHealth(authoring,runtime,request)));
}

function isRecord(value: unknown): value is JsonRecord {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
