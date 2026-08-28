import { realpath, stat } from "node:fs/promises";
import { extname, isAbsolute, relative } from "node:path";

export interface ControlDescribe {
  name: string;
  protocolVersion: 1;
  capabilities: string[];
}

export interface ControlGame {
  gameId: string;
  title: string;
  gameVersion: string;
  canContinue: boolean;
  installationHealthy: boolean;
}

export interface ControlState {
  protocolVersion: 1;
  dashboardStatus: string;
  surface: "hub" | "player";
  activeGameId: string | null;
  install: {
    generation: number;
    status: "idle" | "running" | "succeeded" | "failed";
    message: string | null;
  };
  games: ControlGame[];
}

export interface AveluneApi {
  describe(): Promise<ControlDescribe>;
  state(): Promise<ControlState>;
  install(packagePath: string, timeoutMs: number): Promise<ControlState>;
  launch(gameId: string): Promise<ControlState>;
  returnToHub(): Promise<ControlState>;
}

export type AveluneWaitCondition =
  | "hubReady"
  | "playerOpened"
  | "gameInstalled";

export class AveluneMcpError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly retryable = false,
    readonly details: Record<string, unknown> = {},
  ) {
    super(message);
    this.name = "AveluneMcpError";
  }
}

export interface AveluneControllerDependencies {
  api: AveluneApi;
  allowedRoots: string[];
  now?: () => number;
  sleep?: (milliseconds: number) => Promise<void>;
}

export class AveluneController {
  private readonly api: AveluneApi;
  private readonly allowedRoots: string[];
  private readonly now: () => number;
  private readonly sleep: (milliseconds: number) => Promise<void>;

  constructor(dependencies: AveluneControllerDependencies) {
    this.api = dependencies.api;
    this.allowedRoots = [...dependencies.allowedRoots];
    this.now = dependencies.now ?? Date.now;
    this.sleep =
      dependencies.sleep ??
      ((milliseconds) =>
        new Promise((resolve) => setTimeout(resolve, milliseconds)));
  }

  describe(): Promise<ControlDescribe> {
    return this.api.describe();
  }

  state(): Promise<ControlState> {
    return this.api.state();
  }

  launch(gameId: string): Promise<ControlState> {
    return this.api.launch(gameId);
  }

  returnToHub(): Promise<ControlState> {
    return this.api.returnToHub();
  }

  async install(packagePath: string, timeoutMs: number): Promise<ControlState> {
    const safePath = await this.resolvePackage(packagePath);
    this.validateTimeout(timeoutMs);
    const baseline = await this.api.state();
    const result = await this.api.install(safePath, timeoutMs);
    if (
      result.install.generation <= baseline.install.generation ||
      result.install.status !== "succeeded"
    ) {
      throw new AveluneMcpError(
        "install.unproven",
        "Avelune did not prove a completed installation transition.",
        true,
      );
    }
    return result;
  }

  waitFor(
    condition: AveluneWaitCondition,
    gameId: string | undefined,
    timeoutMs: number,
  ): Promise<ControlState> {
    if (condition === "gameInstalled" && !gameId) {
      throw new AveluneMcpError(
        "wait.gameIdRequired",
        "gameInstalled requires a gameId.",
      );
    }
    return this.poll(timeoutMs, (state) => {
      switch (condition) {
        case "hubReady":
          return state.dashboardStatus === "ready" && state.surface === "hub";
        case "playerOpened":
          return (
            state.surface === "player" &&
            (gameId === undefined || state.activeGameId === gameId)
          );
        case "gameInstalled":
          return state.games.some(
            (game) =>
              game.gameId === gameId && game.installationHealthy,
          );
      }
    });
  }

  private async poll(
    timeoutMs: number,
    matches: (state: ControlState) => boolean,
  ): Promise<ControlState> {
    this.validateTimeout(timeoutMs);
    const deadline = this.now() + timeoutMs;
    while (true) {
      const state = await this.api.state();
      if (matches(state)) return state;
      if (this.now() >= deadline) {
        throw new AveluneMcpError(
          "wait.timeout",
          "Avelune did not reach the requested state before the timeout.",
          true,
        );
      }
      await this.sleep(150);
    }
  }

  private validateTimeout(timeoutMs: number): void {
    if (!Number.isInteger(timeoutMs) || timeoutMs < 100 || timeoutMs > 300_000) {
      throw new AveluneMcpError(
        "wait.invalidTimeout",
        "timeoutMs must be between 100 and 300000.",
      );
    }
  }

  private async resolvePackage(packagePath: string): Promise<string> {
    let resolved: string;
    try {
      resolved = await realpath(packagePath);
      if (!(await stat(resolved)).isFile()) throw new Error("not a file");
    } catch (error) {
      throw new AveluneMcpError(
        "package.unavailable",
        "The Avelune package does not exist or is not a file.",
        false,
        { cause: error instanceof Error ? error.message : String(error) },
      );
    }
    if (extname(resolved).toLowerCase() !== ".avelunegame") {
      throw new AveluneMcpError(
        "package.invalidExtension",
        "The package must use the .avelunegame extension.",
      );
    }
    for (const configuredRoot of this.allowedRoots) {
      const root = await realpath(configuredRoot);
      const candidate = relative(root, resolved);
      if (candidate === "" || (!candidate.startsWith("..") && !isAbsolute(candidate))) {
        return resolved;
      }
    }
    throw new AveluneMcpError(
      "package.pathOutsideAllowedRoots",
      "The package path is outside the configured Avelune roots.",
      false,
      { packagePath: resolved, allowedRoots: this.allowedRoots },
    );
  }
}
