export interface ReadArtifact {
  uri: string;
  mediaType: string;
  text?: string;
  blob?: string;
}

export interface ArtifactReader {
  read(uri: string): Promise<ReadArtifact>;
}

export class ArtifactReadError extends Error {
  constructor(readonly code: string, message: string) {
    super(message);
    this.name = "ArtifactReadError";
  }
}
export class MemoryArtifactReader implements ArtifactReader {
  readonly #artifacts = new Map<string, ReadArtifact>();

  registerText(uri: string, mediaType: string, text: string): void {
    assertArtifactUri(uri);
    this.#artifacts.set(uri, { uri, mediaType, text });
  }

  registerBlob(uri: string, mediaType: string, blob: string): void {
    assertArtifactUri(uri);
    this.#artifacts.set(uri, { uri, mediaType, blob });
  }

  async read(uri: string): Promise<ReadArtifact> {
    assertArtifactUri(uri);
    const artifact = this.#artifacts.get(uri);
    if (!artifact) {
      throw new ArtifactReadError(
        "artifact.unknown",
        "The artifact handle is unknown or has expired.",
      );
    }
    return { ...artifact };
  }
}

function assertArtifactUri(uri: string): void {
  let parsed: URL;
  try {
    parsed = new URL(uri);
  } catch {
    throw new ArtifactReadError(
      "artifact.uri_invalid",
      "The artifact URI is invalid.",
    );
  }
  if (parsed.protocol !== "artifact:") {
    throw new ArtifactReadError(
      "artifact.scheme_forbidden",
      "Only opaque artifact:// handles can be read.",
    );
  }
}
