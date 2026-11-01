export 'narrative_fingerprint_sha256_portable.dart'
    if (dart.library.ffi) 'narrative_fingerprint_sha256_native.dart'
    show
        createNarrativeFingerprintSha256Sink,
        nativeNarrativeFingerprintSha256Available;
