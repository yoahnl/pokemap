final class DialogueLineTextEdit {
  DialogueLineTextEdit({
    required this.nodeName,
    required this.lineIndex,
    required this.beforeText,
    required this.afterText,
  }) {
    if (nodeName.isEmpty ||
        nodeName != nodeName.trim() ||
        lineIndex < 0 ||
        beforeText.isEmpty ||
        afterText.isEmpty ||
        beforeText.contains('\u0000') ||
        afterText.contains('\u0000') ||
        beforeText == afterText) {
      throw ArgumentError(
          'A line text edit requires an exact changed line scope.');
    }
  }

  final String nodeName;
  final int lineIndex;
  final String beforeText;
  final String afterText;

  factory DialogueLineTextEdit.fromJson(Map<String, dynamic> json) {
    const fields = {'nodeName', 'lineIndex', 'beforeText', 'afterText'};
    if (json.length != fields.length ||
        !json.keys.toSet().containsAll(fields) ||
        json['nodeName'] is! String ||
        json['lineIndex'] is! int ||
        json['beforeText'] is! String ||
        json['afterText'] is! String) {
      throw const FormatException('Invalid line text edit fields.');
    }
    try {
      return DialogueLineTextEdit(
        nodeName: json['nodeName'] as String,
        lineIndex: json['lineIndex'] as int,
        beforeText: json['beforeText'] as String,
        afterText: json['afterText'] as String,
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  Map<String, Object?> toJson() => {
        'nodeName': nodeName,
        'lineIndex': lineIndex,
        'beforeText': beforeText,
        'afterText': afterText,
      };

  @override
  bool operator ==(Object other) =>
      other is DialogueLineTextEdit &&
      nodeName == other.nodeName &&
      lineIndex == other.lineIndex &&
      beforeText == other.beforeText &&
      afterText == other.afterText;

  @override
  int get hashCode => Object.hash(nodeName, lineIndex, beforeText, afterText);
}
