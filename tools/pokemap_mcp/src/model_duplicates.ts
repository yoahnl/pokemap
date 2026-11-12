import { createHash } from "node:crypto";
import type { AuthoringGateway, JsonRecord } from "./authoring_client.js";
import { PokeMapToolError } from "./tool_error.js";

const modelFields = ["id", "name", "definition", "sourceAssetId", "relativePath",
  "familyId", "role", "placementContext", "category", "mapId", "tags", "description"];
const assetFields = ["id", "artifact", "logicalPath", "tags", "usages"];
const maximumModels = 50_000;

type Model = {
  id: string;
  name: unknown;
  sourceAssetId: string;
  logicalPath: string;
  settings: string;
};

type Group = {
  digest: string;
  byteLength: number;
  mediaType: string;
  models: Model[];
};

function asRecord(value: unknown): JsonRecord | undefined {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as JsonRecord : undefined;
}

function canonical(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(canonical);
  const record = asRecord(value);
  return record
    ? Object.fromEntries(Object.keys(record).sort().map(key => [key, canonical(record[key])]))
    : value;
}

function incomplete(): never {
  throw new PokeMapToolError("model_duplicates.incomplete",
    "The model inventory could not be read completely.", true,
    ["Retry the audit against a stable project."]);
}

function stale(): never {
  throw new PokeMapToolError("model_duplicates.stale",
    "The model or asset inventory changed during the audit.", true,
    ["Run the audit again before using its results."]);
}

async function query(authoring: AuthoringGateway, projectHandle: string,
  resourceKind: string, operation: "list" | "batch_get", ids: string[],
  fieldMask: string[], pageSize: number, cursor?: string): Promise<JsonRecord> {
  const response = await authoring.request("query", { projectHandle, request: {
    resourceKind, operation, ids, fieldMask, view: "detail", pageSize,
    filters: {}, sort: [], ...(cursor ? { cursor } : {}),
  } });
  return response.data;
}

function revision(data: JsonRecord): string {
  return typeof data.snapshotRevision === "string" && data.snapshotRevision
    ? data.snapshotRevision : incomplete();
}

function items(data: JsonRecord): JsonRecord[] {
  if (!Array.isArray(data.items)) incomplete();
  return data.items.map(value => asRecord(value) ?? incomplete());
}

export async function auditDuplicateModels(authoring: AuthoringGateway,
  projectHandle: string, offset: number, pageSize: number,
  expectedAuditRevision?: string,
  onProgress?: (scannedModels: number) => void): Promise<JsonRecord> {
  onProgress?.(0);
  const initialAssets = await query(authoring, projectHandle, "asset", "list", [], assetFields, 1);
  const assetRevision = revision(initialAssets);
  let modelRevision: string | undefined;
  let cursor: string | undefined;
  let modelCount = 0;
  let totalModels: number | undefined;
  let missingAssetCount = 0;
  let invalidAssetCount = 0;
  const groups = new Map<string, Group>();
  const families = new Map<string | null, number>();
  const roles = new Map<string | null, number>();
  const placements = new Map<string | null, number>();
  function count(collection: Map<string | null, number>, value: unknown, fallback: string | null): void {
    const key = typeof value === "string" && value ? value : fallback;
    collection.set(key, (collection.get(key) ?? 0) + 1);
  }
  function counts(collection: Map<string | null, number>): JsonRecord[] {
    return [...collection].sort((a, b) => b[1] - a[1] || (a[0] ?? "").localeCompare(b[0] ?? ""))
      .map(([id, count]) => ({ id, count }));
  }
  const seenModels = new Set<string>();
  const seenCursors = new Set<string>();
  do {
    onProgress?.(modelCount);
    const page = await query(authoring, projectHandle, "model3d", "list", [], modelFields, 200, cursor);
    const currentRevision = revision(page);
    if (modelRevision && modelRevision !== currentRevision) stale();
    modelRevision = currentRevision;
    if (!Number.isSafeInteger(page.totalAvailable) || (page.totalAvailable as number) < 0) incomplete();
    if (totalModels !== undefined && totalModels !== page.totalAvailable) incomplete();
    totalModels = page.totalAvailable as number;
    const models = items(page);
    modelCount += models.length;
    if (modelCount > maximumModels || totalModels > maximumModels) {
      throw new PokeMapToolError("model_duplicates.limit_exceeded",
        "The project exceeds the model audit limit.", false,
        ["Audit a smaller project inventory."], { maximumModels });
    }
    const ids = [...new Set(models.map(model => model.sourceAssetId)
      .filter((id): id is string => typeof id === "string" && id.length > 0))];
    let assets: JsonRecord[] = [];
    if (ids.length) {
      const result = await query(authoring, projectHandle, "asset", "batch_get", ids, assetFields, 200);
      if (revision(result) !== assetRevision) stale();
      if (result.nextCursor != null) incomplete();
      assets = items(result);
    }
    const assetsById = new Map(assets.map(asset => [asset.id, asset]));
    for (const model of models) {
      const definition = asRecord(model.definition);
      const id = model.id;
      const sourceAssetId = model.sourceAssetId;
      if (typeof id !== "string" || seenModels.has(id)) incomplete();
      seenModels.add(id);
      count(families, model.familyId, null);
      count(roles, model.role, "standard");
      count(placements, model.placementContext, null);
      if (typeof sourceAssetId !== "string" || !definition) {
        invalidAssetCount++;
        continue;
      }
      const asset = assetsById.get(sourceAssetId);
      if (!asset) {
        missingAssetCount++;
        continue;
      }
      const artifact = asRecord(asset.artifact);
      const digest = artifact?.digest;
      const byteLength = artifact?.byteLength;
      const mediaType = artifact?.mediaType;
      const logicalPath = asset.logicalPath;
      if (typeof digest !== "string" || !/^sha256:[a-f0-9]{64}$/.test(digest) ||
          typeof byteLength !== "number" || !Number.isSafeInteger(byteLength) || byteLength < 0 ||
          typeof mediaType !== "string" || typeof logicalPath !== "string" ||
          logicalPath !== model.relativePath) {
        invalidAssetCount++;
        continue;
      }
      const normalizedDefinition = { ...definition };
      delete normalizedDefinition.id;
      delete normalizedDefinition.sourceAssetId;
      delete normalizedDefinition.relativePath;
      const settings = JSON.stringify(canonical({ definition: normalizedDefinition,
        familyId: model.familyId ?? null, role: model.role ?? null,
        placementContext: model.placementContext ?? null, category: model.category ?? null,
        mapId: model.mapId ?? null,
        tags: model.tags ?? [], description: model.description ?? null,
        assetTags: asset.tags ?? [], assetUsages: asset.usages ?? [] }));
      const groupKey = JSON.stringify([digest, byteLength, mediaType]);
      let group = groups.get(groupKey);
      if (!group) {
        group = { digest, byteLength, mediaType, models: [] };
        groups.set(groupKey, group);
      }
      group.models.push({ id, name: model.name ?? null, sourceAssetId, logicalPath, settings });
    }
    const next = page.nextCursor;
    if (next != null && (typeof next !== "string" || !next || seenCursors.has(next))) incomplete();
    cursor = typeof next === "string" ? next : undefined;
    if (cursor) seenCursors.add(cursor);
    onProgress?.(modelCount);
  } while (cursor);

  if (modelCount !== totalModels) incomplete();
  await verifyDuplicateModelAudit(authoring, projectHandle, modelRevision!, assetRevision);
  const auditRevision = `sha256:${createHash("sha256")
    .update(JSON.stringify([modelRevision, assetRevision])).digest("hex")}`;
  if (expectedAuditRevision && expectedAuditRevision !== auditRevision) stale();
  const duplicates = [...groups.values()].filter(group => group.models.length > 1)
    .sort((a, b) => a.digest.localeCompare(b.digest) || a.byteLength - b.byteLength ||
      a.mediaType.localeCompare(b.mediaType));
  const familyCounts = counts(families);
  return {
    auditRevision, modelRevision, assetRevision, modelCount, missingAssetCount, invalidAssetCount,
    sourceEvidence: "registered_digest_only", referenceEvidence: "not_checked",
    families: familyCounts.slice(0, 100), familyCount: familyCounts.length,
    familiesTruncated: familyCounts.length > 100,
    roles: counts(roles), placementContexts: counts(placements),
    duplicateGroupCount: duplicates.length,
    duplicateDefinitionCount: duplicates.reduce((sum, group) => sum + group.models.length - 1, 0),
    groups: duplicates.slice(offset, offset + pageSize).map(group => {
      group.models.sort((a, b) => a.id.localeCompare(b.id));
      return { digest: group.digest, byteLength: group.byteLength, mediaType: group.mediaType,
        totalModels: group.models.length,
        distinctLogicalPaths: new Set(group.models.map(model => model.logicalPath)).size,
        sameSettings: new Set(group.models.map(model => model.settings)).size === 1,
        models: group.models.map(({ settings, ...model }) => ({
          ...model,
          settingsFingerprint: `sha256:${createHash("sha256").update(settings).digest("hex")}`,
        })) };
    }),
    ...(offset + pageSize < duplicates.length ? { nextOffset: offset + pageSize } : {}),
  };
}

export async function verifyDuplicateModelAudit(authoring: AuthoringGateway,
  projectHandle: string, modelRevision: string, assetRevision: string): Promise<void> {
  const lastModels = await query(authoring, projectHandle, "model3d", "list", [], ["id"], 1);
  const lastAssets = await query(authoring, projectHandle, "asset", "list", [], ["id"], 1);
  if (revision(lastModels) !== modelRevision || revision(lastAssets) !== assetRevision) stale();
}
