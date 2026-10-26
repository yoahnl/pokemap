import { isAbsolute } from "node:path";
import type { McpServer } from "@modelcontextprotocol/server";
import { z } from "zod";
import type { AuthoringGateway } from "../authoring_client.js";
import { authoringResult, toolEnvelopeSchema } from "./result.js";

export function registerVisualSettingsTools(server: McpServer, authoring: AuthoringGateway): void {
  const settings = z.object({
    pitchDegrees: z.number().min(1).max(89).optional(),
    yawDegrees: z.number().min(-360).max(360).optional(),
    fieldOfViewDegrees: z.number().min(1.01).max(119.99).optional(),
    cameraDistance: z.number().min(.01).max(10000).optional(),
    lockVerticalFraming: z.boolean().optional(),
    dayNightEnabled: z.boolean().optional(),
    dayDurationSeconds: z.number().min(10).max(86400).optional(),
    minuteOfDay: z.number().min(0).max(1439).optional(),
    depthOfFieldEnabled: z.boolean().optional(),
    depthOfFieldStrength: z.number().min(0).max(1).optional(),
    depthOfFieldFocusRange: z.number().min(2).max(40).optional(),
    halosEnabled: z.boolean().optional(),
    haloStrength: z.number().min(0).max(2).optional(),
    haloSpread: z.number().min(.1).max(3).optional(),
    depthFogEnabled: z.boolean().optional(),
    fogOpacity: z.number().min(0).max(.5).optional(),
    fogStart: z.number().min(0).max(99999.99).optional(),
    fogEnd: z.number().min(.01).max(100000).optional(),
    waterAnimated: z.boolean().optional(),
    waterStrength: z.number().min(0).max(2).optional(),
    waterSpeed: z.number().min(0).max(3).optional(),
    windowsLit: z.boolean().optional(),
    windowStrength: z.number().min(0).max(2).optional(),
    fireflies: z.boolean().optional(),
    fireflyDensity: z.number().min(0).max(2).optional(),
    fireflyLighting:z.boolean().optional(),
    fireflyYellowAmount:z.number().min(0).max(1).optional(),
    fireflyGreenAmount:z.number().min(0).max(1).optional(),
    fireflyBlueAmount:z.number().min(0).max(1).optional(),
    fireflyPinkAmount:z.number().min(0).max(1).optional(),
    fireflyLightStrength:z.number().min(0).max(1).optional(),
    fireflyLightRadius:z.number().min(0.25).max(2.5).optional(),
    weatherEnabled:z.boolean().optional(),
    weatherKind:z.enum(["clear","cloudy","drizzle","rain","downpour","storm","snow","blizzard","hail","mist","fog","dust","sandstorm","petals","leaves"]).optional(),
    weatherIntensity:z.number().min(0).max(1).optional(),
    weatherDensity:z.number().min(0).max(1).optional(),
    weatherSpeed:z.number().min(.1).max(3).optional(),
    weatherWindStrength:z.number().min(0).max(2).optional(),
    weatherWindDirection:z.number().min(-180).max(180).optional(),
    weatherParticleSize:z.number().min(.25).max(2).optional(),
    weatherOpacity:z.number().min(0).max(1).optional(),
    weatherCloudCover:z.number().min(0).max(1).optional(),
    weatherFogStrength:z.number().min(0).max(1).optional(),
    weatherTransitionSeconds:z.number().min(0).max(5).optional(),
    weatherLightning:z.boolean().optional(),
    weatherIndoors:z.boolean().optional(),

  }).strict().refine(value => value.fogStart === undefined || value.fogEnd === undefined || value.fogStart < value.fogEnd, "Fog must end after its start");
  const identity = {
    projectRoot: z.string().min(1).refine(isAbsolute, "projectRoot must be absolute"),
    mapId: z.string().min(1).max(120).optional(),
    mapRelativePath: z.string().min(1).max(1024).optional(),
  };
  const mutation = {...identity, expectedRevision:z.string().min(1).max(128), operationId:z.string().min(1).max(120)};
  server.registerTool("pokemap_visual_settings_inspect", {
    title:"Inspect project or map visual settings",
    description:"Read a bounded visual settings document. Omit mapId for project defaults; supply mapId for local overrides. Missing fields inherit existing values. Reads only document bytes and source metadata, never project content, maps, assets or global history.",
    inputSchema:z.object(identity).strict(), outputSchema:toolEnvelopeSchema,
    annotations:{readOnlyHint:true, destructiveHint:false, idempotentHint:true, openWorldHint:false},
  }, async args => authoringResult(()=>authoring.request("visual_settings_inspect",args)));
  server.registerTool("pokemap_visual_settings_set", {
    title:"Save project or map visual settings",
    description:"Save a typed visual patch through canonical visual.settings.set. Project defaults use project.visual.json; map overrides use maps/<mapId>.visual.json. Includes named weather styles, numeric sliders and boolean controls; instance-specific water, window, halo and firefly bindings stay in the map atmosphere document. Supply the exact revision from inspect and a unique operationId; replay identical arguments after an unknown outcome. Atomic, revision checked, scoped undo and bounded writes. Removing a field restores inheritance.",
    inputSchema:z.object({...mutation,settings}).strict(), outputSchema:toolEnvelopeSchema,
    annotations:{readOnlyHint:false, destructiveHint:false, idempotentHint:true, openWorldHint:false},
  }, async args => authoringResult(()=>authoring.request("visual_settings_set",args)));
  server.registerTool("pokemap_visual_settings_undo", {
    title:"Undo one visual settings save",
    description:"Undo one current project or map visual settings receipt with its exact revision. Only targeted immutable history is read; no global replay. Concurrent changes are rejected.",
    inputSchema:z.object({...mutation,receiptId:z.string().regex(/^receipt_document_[a-f0-9]{32}$/)}).strict(), outputSchema:toolEnvelopeSchema,
    annotations:{readOnlyHint:false, destructiveHint:false, idempotentHint:true, openWorldHint:false},
  }, async args => authoringResult(()=>authoring.request("visual_settings_undo",args)));
}
