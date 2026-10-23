part of 'scene_interactive_command.dart';

enum SceneWorldPresentationOperation {
  showPicture,
  movePicture,
  erasePicture,
  flash,
  shake,
}

enum SceneVisualScope { scene, map }

enum ScenePictureOrigin { topLeft, center }

@immutable
final class SceneWorldPresentationInteractiveCommand
    extends SceneInteractiveCommand {
  SceneWorldPresentationInteractiveCommand({
    required this.operation,
    this.scope = SceneVisualScope.map,
    this.slotId,
    this.mediaAssetId,
    this.referenceWidth,
    this.referenceHeight,
    this.x,
    this.y,
    this.scaleX = 1,
    this.scaleY = 1,
    this.opacity = 1,
    this.origin = ScenePictureOrigin.topLeft,
    this.red,
    this.green,
    this.blue,
    this.alpha,
    this.power,
    this.speed,
    this.durationMs = 0,
    this.waitForCompletion = false,
  }) {
    if (durationMs < 0 || durationMs > 60000) {
      throw ArgumentError.value(
        durationMs,
        'durationMs',
        'Must be within 0..60000.',
      );
    }
    final picture =
        operation == SceneWorldPresentationOperation.showPicture ||
        operation == SceneWorldPresentationOperation.movePicture;
    final slotted =
        picture || operation == SceneWorldPresentationOperation.erasePicture;
    if (slotted != (slotId != null) ||
        (slotId != null && (slotId! < 1 || slotId! > 100))) {
      throw ArgumentError.value(
        slotId,
        'slotId',
        'Pictures require a slot within 1..100.',
      );
    }
    if ((operation == SceneWorldPresentationOperation.showPicture) !=
            (mediaAssetId != null) ||
        (mediaAssetId != null &&
            (mediaAssetId!.trim().isEmpty ||
                mediaAssetId != mediaAssetId!.trim()))) {
      throw ArgumentError.value(
        mediaAssetId,
        'mediaAssetId',
        'Only showPicture requires an image identifier.',
      );
    }
    final framed =
        picture || operation == SceneWorldPresentationOperation.shake;
    if (framed != (referenceWidth != null && referenceHeight != null) ||
        (referenceWidth != null &&
            (referenceWidth! < 1 || referenceWidth! > 8192)) ||
        (referenceHeight != null &&
            (referenceHeight! < 1 || referenceHeight! > 8192)) ||
        (!framed && (referenceWidth != null || referenceHeight != null))) {
      throw ArgumentError(
        'Pictures and shake require a reference frame within 1..8192.',
      );
    }
    if (picture != (x != null && y != null) ||
        (!picture && (x != null || y != null))) {
      throw ArgumentError('Pictures require explicit x and y.');
    }
    if (picture) {
      _boundedPresentationNumber(x!, 'x', -1000000, 1000000);
      _boundedPresentationNumber(y!, 'y', -1000000, 1000000);
    } else if (scaleX != 1 ||
        scaleY != 1 ||
        opacity != 1 ||
        origin != ScenePictureOrigin.topLeft) {
      throw ArgumentError(
        'Picture composition is only valid for showPicture and movePicture.',
      );
    }
    _boundedPresentationNumber(scaleX, 'scaleX', double.minPositive, 16);
    _boundedPresentationNumber(scaleY, 'scaleY', double.minPositive, 16);
    _boundedPresentationNumber(opacity, 'opacity', 0, 1);
    final flash = operation == SceneWorldPresentationOperation.flash;
    if (flash !=
            (red != null && green != null && blue != null && alpha != null) ||
        (!flash && [red, green, blue, alpha].any((value) => value != null))) {
      throw ArgumentError('Flash requires an explicit RGBA color.');
    }
    if (flash) {
      _boundedPresentationNumber(red!, 'red', 0, 255);
      _boundedPresentationNumber(green!, 'green', 0, 255);
      _boundedPresentationNumber(blue!, 'blue', 0, 255);
      _boundedPresentationNumber(alpha!, 'alpha', 0, 255);
    }
    final shake = operation == SceneWorldPresentationOperation.shake;
    if (shake != (power != null && speed != null) ||
        (!shake && (power != null || speed != null))) {
      throw ArgumentError('Shake requires power and speed.');
    }
    if (shake) {
      _boundedPresentationNumber(power!, 'power', 0, 128);
      _boundedPresentationNumber(speed!, 'speed', .1, 60);
    }
    if ((flash || shake) && durationMs == 0) {
      throw ArgumentError('Flash and shake require a positive duration.');
    }
    if ((operation == SceneWorldPresentationOperation.showPicture ||
            operation == SceneWorldPresentationOperation.erasePicture) &&
        durationMs != 0) {
      throw ArgumentError('Show and erase are instantaneous.');
    }
  }

  factory SceneWorldPresentationInteractiveCommand.fromJson(
    Map<String, dynamic> json,
  ) {
    try {
      final operation = _requiredEnum(
        json,
        'operation',
        SceneWorldPresentationOperation.values,
      );
      final picture =
          operation == SceneWorldPresentationOperation.showPicture ||
          operation == SceneWorldPresentationOperation.movePicture;
      _presentationCommandFields(json, {
        'kind',
        'operation',
        'scope',
        'durationMs',
        'waitForCompletion',
        if (picture ||
            operation == SceneWorldPresentationOperation.erasePicture)
          'slotId',
        if (operation == SceneWorldPresentationOperation.showPicture)
          'mediaAssetId',
        if (picture || operation == SceneWorldPresentationOperation.shake) ...[
          'referenceWidth',
          'referenceHeight',
        ],
        if (picture) ...['x', 'y', 'scaleX', 'scaleY', 'opacity', 'origin'],
        if (operation == SceneWorldPresentationOperation.flash) ...[
          'red',
          'green',
          'blue',
          'alpha',
        ],
        if (operation == SceneWorldPresentationOperation.shake) ...[
          'power',
          'speed',
        ],
      });
      int? integer(String key) {
        if (!json.containsKey(key)) {
          return null;
        }
        if (json[key] is! int) {
          throw FormatException('$key must be an integer.');
        }
        return json[key] as int;
      }

      double? number(String key) =>
          json.containsKey(key) ? _presentationNumber(json, key) : null;
      if (json['kind'] != 'worldPresentation' ||
          (json.containsKey('waitForCompletion') &&
              json['waitForCompletion'] is! bool)) {
        throw const FormatException('Invalid world presentation command.');
      }
      return SceneWorldPresentationInteractiveCommand(
        operation: operation,
        scope: json.containsKey('scope')
            ? _requiredEnum(json, 'scope', SceneVisualScope.values)
            : SceneVisualScope.map,
        slotId: integer('slotId'),
        mediaAssetId: json.containsKey('mediaAssetId')
            ? _required(json, 'mediaAssetId')
            : null,
        referenceWidth: integer('referenceWidth'),
        referenceHeight: integer('referenceHeight'),
        x: number('x'),
        y: number('y'),
        scaleX: number('scaleX') ?? 1,
        scaleY: number('scaleY') ?? 1,
        opacity: number('opacity') ?? 1,
        origin: json.containsKey('origin')
            ? _requiredEnum(json, 'origin', ScenePictureOrigin.values)
            : ScenePictureOrigin.topLeft,
        red: number('red'),
        green: number('green'),
        blue: number('blue'),
        alpha: number('alpha'),
        power: number('power'),
        speed: number('speed'),
        durationMs: integer('durationMs') ?? 0,
        waitForCompletion: json['waitForCompletion'] as bool? ?? false,
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid world presentation command: $error');
    }
  }

  final SceneWorldPresentationOperation operation;
  final SceneVisualScope scope;
  final int? slotId;
  final String? mediaAssetId;
  final int? referenceWidth;
  final int? referenceHeight;
  final double? x;
  final double? y;
  final double scaleX;
  final double scaleY;
  final double opacity;
  final ScenePictureOrigin origin;
  final double? red;
  final double? green;
  final double? blue;
  final double? alpha;
  final double? power;
  final double? speed;
  final int durationMs;
  final bool waitForCompletion;

  @override
  SceneInteractiveCommandKind get kind =>
      SceneInteractiveCommandKind.worldPresentation;
  @override
  List<String> get outputPortIds => const ['completed', 'blocked'];
  @override
  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'operation': operation.name,
    'scope': scope.name,
    'durationMs': durationMs,
    'waitForCompletion': waitForCompletion,
    if (slotId != null) 'slotId': slotId,
    if (mediaAssetId != null) 'mediaAssetId': mediaAssetId,
    if (referenceWidth != null) 'referenceWidth': referenceWidth,
    if (referenceHeight != null) 'referenceHeight': referenceHeight,
    if (x != null) ...{
      'x': x,
      'y': y,
      'scaleX': scaleX,
      'scaleY': scaleY,
      'opacity': opacity,
      'origin': origin.name,
    },
    if (red != null) ...{
      'red': red,
      'green': green,
      'blue': blue,
      'alpha': alpha,
    },
    if (power != null) ...{'power': power, 'speed': speed},
  };
  @override
  bool operator ==(Object other) {
    if (other is! SceneWorldPresentationInteractiveCommand) {
      return false;
    }
    final own = toJson();
    final theirs = other.toJson();
    return own.length == theirs.length &&
        own.entries.every((entry) => theirs[entry.key] == entry.value);
  }

  @override
  int get hashCode => Object.hashAll(toJson().values);
}
