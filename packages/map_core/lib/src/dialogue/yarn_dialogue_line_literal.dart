import 'dart:convert';

final class YarnDialogueLineLiteral {
  const YarnDialogueLineLiteral({required this.text, this.speaker});

  final String text;
  final String? speaker;

  String get displayedText => speaker == null ? text : '$speaker: $text';

  String toSource() =>
      '<<line_v1 ${jsonEncode({'text': text, 'speaker': speaker})}>>';

  static bool matches(String source) => source.startsWith('<<line_v1');

  static YarnDialogueLineLiteral parse(String source) {
    if (!source.startsWith('<<line_v1 ') || !source.endsWith('>>')) {
      throw const FormatException('Invalid explicit dialogue line.');
    }
    final value = jsonDecode(
      source.substring('<<line_v1 '.length, source.length - 2),
    );
    if (value is! Map<String, dynamic> ||
        value.length != 2 ||
        !value.containsKey('text') ||
        !value.containsKey('speaker')) {
      throw const FormatException(
        'An explicit dialogue line requires text and speaker.',
      );
    }
    final text = value['text'];
    final speaker = value['speaker'];
    if (text is! String ||
        text.trim().isEmpty ||
        text.contains('\u0000') ||
        (speaker != null &&
            (speaker is! String ||
                speaker.trim().isEmpty ||
                speaker != speaker.trim() ||
                speaker.contains('\u0000')))) {
      throw const FormatException(
        'Invalid explicit dialogue line text or speaker.',
      );
    }
    return YarnDialogueLineLiteral(text: text, speaker: speaker as String?);
  }
}
