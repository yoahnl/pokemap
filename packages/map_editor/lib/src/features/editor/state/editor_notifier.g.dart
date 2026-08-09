// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EditorNotifier)
final editorNotifierProvider = EditorNotifierProvider._();

final class EditorNotifierProvider
    extends $NotifierProvider<EditorNotifier, EditorState> {
  EditorNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editorNotifierProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editorNotifierHash();

  @$internal
  @override
  EditorNotifier create() => EditorNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditorState>(value),
    );
  }
}

String _$editorNotifierHash() => r'484a52cb1b0d41209092bbf882068324646c6a65';

abstract class _$EditorNotifier extends $Notifier<EditorState> {
  EditorState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<EditorState, EditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EditorState, EditorState>,
              EditorState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
