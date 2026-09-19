import 'package:flutter/material.dart';

class StudioNotice extends StatelessWidget {
  const StudioNotice(this.message, {super.key, this.isError = false});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
