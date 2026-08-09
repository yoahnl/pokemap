/// Disables Riverpod 3's automatic provider retry.
///
/// Riverpod 2 surfaced provider failures immediately. The editor keeps that
/// behavior so dependency migration does not repeat I/O or worker operations.
Duration? disableAutomaticProviderRetry(int _, Object __) => null;
