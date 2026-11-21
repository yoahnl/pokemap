import 'package:map_runtime/map_runtime.dart';

/// Local player presentation preferences owned by the standalone runtime host.
///
/// These values are deliberately separate from gameplay saves: moving a save
/// between devices must not overwrite accessibility or device-control choices.
final class RuntimePlayerOptions {
  const RuntimePlayerOptions({
    this.dialogueTextSpeed = RuntimeDialogueTextSpeed.normal,
    this.showTouchControls = true,
  });

  final RuntimeDialogueTextSpeed dialogueTextSpeed;
  final bool showTouchControls;

  factory RuntimePlayerOptions.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const RuntimePlayerOptions();
    }
    final rawTouchControls = json['showTouchControls'];
    return RuntimePlayerOptions(
      dialogueTextSpeed: RuntimeDialogueTextSpeed.fromStorage(
        json['dialogueTextSpeed'],
        fallback: RuntimeDialogueTextSpeed.normal,
      ),
      showTouchControls: rawTouchControls is bool ? rawTouchControls : true,
    );
  }

  RuntimePlayerOptions copyWith({
    RuntimeDialogueTextSpeed? dialogueTextSpeed,
    bool? showTouchControls,
  }) {
    return RuntimePlayerOptions(
      dialogueTextSpeed: dialogueTextSpeed ?? this.dialogueTextSpeed,
      showTouchControls: showTouchControls ?? this.showTouchControls,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'dialogueTextSpeed': dialogueTextSpeed.name,
        'showTouchControls': showTouchControls,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuntimePlayerOptions &&
          dialogueTextSpeed == other.dialogueTextSpeed &&
          showTouchControls == other.showTouchControls;

  @override
  int get hashCode => Object.hash(dialogueTextSpeed, showTouchControls);
}
