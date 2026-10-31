final class PeriodicRewardReference {
  PeriodicRewardReference({
    required this.sceneId,
    required this.nodeId,
    required this.rewardId,
  }) {
    for (final value in [sceneId, nodeId, rewardId]) {
      if (value.isEmpty || value.trim() != value) {
        throw ArgumentError(
          'A reward reference requires canonical identities.',
        );
      }
    }
  }

  factory PeriodicRewardReference.fromJson(Map<String, dynamic> json) {
    if (json.length != 4 ||
        json['schemaVersion'] is! int ||
        json['schemaVersion'] != 1 ||
        json['sceneId'] is! String ||
        json['nodeId'] is! String ||
        json['rewardId'] is! String) {
      throw const FormatException(
        'Invalid or unsupported periodic reward reference.',
      );
    }
    try {
      return PeriodicRewardReference(
        sceneId: json['sceneId'] as String,
        nodeId: json['nodeId'] as String,
        rewardId: json['rewardId'] as String,
      );
    } on ArgumentError {
      throw const FormatException(
        'Invalid periodic reward reference identities.',
      );
    }
  }

  final String sceneId, nodeId, rewardId;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'sceneId': sceneId,
    'nodeId': nodeId,
    'rewardId': rewardId,
  };

  @override
  bool operator ==(Object other) =>
      other is PeriodicRewardReference &&
      other.sceneId == sceneId &&
      other.nodeId == nodeId &&
      other.rewardId == rewardId;

  @override
  int get hashCode => Object.hash(sceneId, nodeId, rewardId);
}
