String mapFailureMessage(Object failure) =>
    failure is StateError ? failure.message : '$failure';
