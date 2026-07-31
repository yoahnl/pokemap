import type { JsonRecord } from "./authoring_client.js";

/**
 * Transport-safe error raised by MCP adapters outside the Dart worker.
 * Codes and remediation remain stable, while callers never receive private
 * process errors, command lines, or filesystem paths.
 */
export class PokeMapToolError extends Error {
  constructor(
    readonly code: string,
    message: string,
    readonly retryable = false,
    readonly remediation: readonly string[] = [],
    readonly details: JsonRecord = {},
  ) {
    super(message);
    this.name = "PokeMapToolError";
  }
}
