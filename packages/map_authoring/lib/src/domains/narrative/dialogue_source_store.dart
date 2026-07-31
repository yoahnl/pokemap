String dialogueSourceResourceIdentity(String dialogueId) =>
    'dialogueSource:$dialogueId';

/// The manifest remains the sole authority for dialogue source storage keys.
/// This helper only centralizes path-free snapshot identities.
String dialogueSourceStorageKey(String relativePath) => relativePath;
