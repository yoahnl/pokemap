import 'package:flutter/material.dart';

import 'pokemap_button.dart';

class PokeMapDisclosure extends StatelessWidget {
  const PokeMapDisclosure({
    super.key,
    required this.label,
    required this.expanded,
    required this.onExpandedChanged,
    required this.child,
    this.toggleKey,
    this.contentKey,
  });

  final String label;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final Widget child;
  final Key? toggleKey;
  final Key? contentKey;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: PokeMapButton(
          key: toggleKey,
          size: PokeMapButtonSize.medium,
          variant: PokeMapButtonVariant.ghost,
          semanticLabel: '$label, ${expanded ? 'développé' : 'réduit'}',
          onPressed: () => onExpandedChanged(!expanded),
          trailing: Icon(
            expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          ),
          child: Text(label),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 140),
        alignment: AlignmentDirectional.topStart,
        child: expanded
            ? Padding(
                key: contentKey,
                padding: const EdgeInsets.only(top: 8),
                child: child,
              )
            : const SizedBox.shrink(),
      ),
    ],
  );
}
