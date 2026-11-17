import '../models/dialogue_line_feedback.dart';

DialogueLineFeedback? retargetDialogueLineFeedback(
  DialogueLineFeedback? feedback, {
  required String sourceText,
  required String text,
}) {
  if (feedback == null) return null;
  feedback.validateText(sourceText);
  if (sourceText == text) return feedback;
  final segments = feedback.segments;
  if (segments.isNotEmpty &&
      (segments.length != 1 || segments.single is! DialogueTextSegment)) {
    throw const FormatException(
      'Translating a rich dialogue line requires explicit segment-aware authoring.',
    );
  }
  final result = DialogueLineFeedback(
    segments: segments.isEmpty
        ? const []
        : [
            DialogueTextSegment(
              text,
              style: (segments.single as DialogueTextSegment).style,
            ),
          ],
    revealIntervalMicros: feedback.revealIntervalMicros,
    advance: feedback.advance,
    audioCue: feedback.audioCue,
  );
  result.validateText(text);
  return result;
}
