import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_button.dart';

class DialogueAddToolbar extends StatelessWidget {
  const DialogueAddToolbar({
    super.key,
    required this.onNode,
    required this.onLine,
    required this.onNarration,
    required this.onChoice,
  });
  final VoidCallback onNode, onLine, onNarration, onChoice;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          StudioButton(
            label: 'Nouvelle suite',
            secondary: true,
            icon: Icons.add,
            onPressed: onNode,
          ),
          const SizedBox(width: 6),
          StudioButton(
            label: 'Réplique',
            secondary: true,
            icon: Icons.chat_bubble_outline,
            onPressed: onLine,
          ),
          const SizedBox(width: 6),
          StudioButton(
            label: 'Narration',
            secondary: true,
            icon: Icons.notes,
            onPressed: onNarration,
          ),
          const SizedBox(width: 6),
          StudioButton(
            label: 'Choix',
            secondary: true,
            icon: Icons.alt_route,
            onPressed: onChoice,
          ),
        ],
      ),
    ),
  );
}
