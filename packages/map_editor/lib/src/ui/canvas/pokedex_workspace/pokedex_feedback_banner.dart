part of 'pokedex_workspace_page.dart';

// Bannière de feedback locale du workspace.
//
// Elle sert à donner un retour humain et immédiat après import ou sauvegarde,
// sans introduire de système global de notifications.

class PokedexWorkspaceFeedbackBanner extends StatelessWidget {
  const PokedexWorkspaceFeedbackBanner({
    super.key,
    required this.message,
    required this.isError,
  });

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentJade;
    final label = EditorChrome.primaryLabel(context);

    return Container(
      key: const Key('pokedex-feedback-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? CupertinoIcons.exclamationmark_triangle_fill
                : CupertinoIcons.check_mark_circled_solid,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
