import 'package:flutter/widgets.dart';

List<Widget> journalBodyParagraphs(String? body, {required TextStyle style}) =>
    [
      for (final (index, paragraph) in _paragraphs(body).indexed)
        Text(
          paragraph,
          key: ValueKey('journal-selected-body-$index'),
          style: style,
        ),
    ];

List<String> _paragraphs(String? text) => [
  for (final line in (text ?? '').split('\n'))
    if (line.trim().isNotEmpty) line.trim(),
];
