import { openAsBlob } from "node:fs";
import { basename } from "node:path";

import { z } from "zod";

import {
  AveluneMcpError,
  type AveluneApi,
  type ControlDescribe,
  type ControlState,
} from "./controller.js";
import type { AveluneControlSession } from "./session.js";

const installSchema = z.object({
  generation: z.number().int().nonnegative(),
  status: z.enum(["idle", "running", "succeeded", "failed"]),
  message: z.string().nullable(),
});
const gameSchema = z.object({
  gameId: z.string(),
  title: z.string(),
  gameVersion: z.string(),
  canContinue: z.boolean(),
  installationHealthy: z.boolean(),
});
const stateSchema = z.object({
  protocolVersion: z.literal(1),
  dashboardStatus: z.string(),
  surface: z.enum(["hub", "player"]),
  activeGameId: z.string().nullable(),
  install: installSchema,
  games: z.array(gameSchema),
});
const describeSchema = z.object({
  name: z.string(),
  protocolVersion: z.literal(1),
  capabilities: z.array(z.string()),
});

export class HttpAveluneApiClient implements AveluneApi {
  constructor(
    private readonly readSession: () => Promise<AveluneControlSession>,
  ) {}

  async describe(): Promise<ControlDescribe> {
    return describeSchema.parse(await this.request("GET", "/v1/describe"));
  }

  async state(): Promise<ControlState> {
    return stateSchema.parse(await this.request("GET", "/v1/state"));
  }

  async install(packagePath: string, timeoutMs: number): Promise<ControlState> {
    const packageBlob = await openAsBlob(packagePath, {
      type: "application/octet-stream",
    });
    const filename = encodeURIComponent(basename(packagePath));
    return stateSchema.parse(
      await this.request(
        "POST",
        `/v1/install?filename=${filename}`,
        packageBlob,
        timeoutMs,
      ),
    );
  }

  async launch(gameId: string): Promise<ControlState> {
    return stateSchema.parse(
      await this.request(
        "POST",
        "/v1/launch",
        JSON.stringify({ gameId }),
        5_000,
        "application/json",
      ),
    );
  }

  async returnToHub(): Promise<ControlState> {
    return stateSchema.parse(await this.request("POST", "/v1/hub"));
  }

  private async request(
    method: string,
    path: string,
    body?: string | Blob,
    timeoutMs = 5_000,
    contentType?: string,
  ): Promise<unknown> {
    const session = await this.readSession();
    let response: Response;
    try {
      response = await fetch(new URL(path, session.apiUrl), {
        method,
        headers: {
          authorization: `Bearer ${session.token}`,
          ...(contentType ? { "content-type": contentType } : {}),
        },
        ...(body ? { body } : {}),
        signal: AbortSignal.timeout(timeoutMs),
      });
    } catch (error) {
      throw new AveluneMcpError(
        "api.unavailable",
        "The controlled Avelune application is unavailable.",
        true,
        { cause: error instanceof Error ? error.message : String(error) },
      );
    }
    const payload = (await response.json()) as Record<string, unknown>;
    if (!response.ok) {
      throw new AveluneMcpError(
        typeof payload.code === "string" ? payload.code : "api.requestFailed",
        typeof payload.message === "string"
          ? payload.message
          : "The Avelune control request failed.",
        response.status >= 500,
        { statusCode: response.status },
      );
    }
    return payload;
  }
}
