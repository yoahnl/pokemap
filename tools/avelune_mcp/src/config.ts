import { resolve } from "node:path";

export interface AveluneMcpConfig {
  sessionFile: string;
  allowedRoots: string[];
}

export class AveluneMcpConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AveluneMcpConfigError";
  }
}

export function parseConfig(args: readonly string[]): AveluneMcpConfig {
  const allowedRoots: string[] = [];
  let sessionFile: string | undefined;
  for (let index = 0; index < args.length; index += 1) {
    const option = args[index];
    const value = args[index + 1];
    if (!value || value.startsWith("--")) {
      throw new AveluneMcpConfigError(
        `The configuration option ${option ?? "<missing>"} needs a value.`,
      );
    }
    index += 1;
    switch (option) {
      case "--session-file":
        sessionFile = resolve(value);
        break;
      case "--root":
        allowedRoots.push(resolve(value));
        break;
      default:
        throw new AveluneMcpConfigError(
          `Unknown configuration option ${option}.`,
        );
    }
  }
  if (!sessionFile) {
    throw new AveluneMcpConfigError("A --session-file option is required.");
  }
  if (allowedRoots.length === 0) {
    throw new AveluneMcpConfigError("At least one --root option is required.");
  }
  return { sessionFile, allowedRoots };
}
