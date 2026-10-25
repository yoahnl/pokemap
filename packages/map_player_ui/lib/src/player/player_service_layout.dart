import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundation/player_components.dart';
import '../foundation/player_paged_layout.dart';
import '../theme/pokemap_player_menu_theme.dart';

class PlayerServiceContent extends StatefulWidget {
  const PlayerServiceContent({
    super.key,
    required this.title,
    required this.children,
    required this.contentIdentity,
    this.actions,
  });

  final Widget title;
  final List<Widget> children;
  final Object contentIdentity;
  final Widget? actions;

  @override
  State<PlayerServiceContent> createState() => _PlayerServiceContentState();
}

class _PlayerServiceContentState extends State<PlayerServiceContent> {
  double? _contentHeight;
  Object? _signature;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      widget.title,
      const SizedBox(height: 8),
      Flexible(
        fit: FlexFit.loose,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final signature = (
              constraints.maxWidth,
              MediaQuery.textScalerOf(context),
              widget.contentIdentity,
            );
            if (_signature != signature) {
              _signature = signature;
              _contentHeight = null;
            }
            return SizedBox(
              height: math.min(
                _contentHeight ?? constraints.maxHeight,
                constraints.maxHeight,
              ),
              child: PlayerPagedList(
                key: ValueKey(signature),
                onContentHeightChanged: (height) {
                  if (mounted &&
                      _signature == signature &&
                      (_contentHeight == null ||
                          (_contentHeight! - height).abs() > .5)) {
                    setState(() => _contentHeight = height);
                  }
                },
                children: widget.children,
              ),
            );
          },
        ),
      ),
      if (widget.actions != null) ...[
        const SizedBox(height: 12),
        widget.actions!,
      ],
    ],
  );
}

class PlayerServiceActions extends StatelessWidget {
  const PlayerServiceActions({super.key, required this.children});

  final List<PlayerActionButton> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (children.isEmpty) return const SizedBox.shrink();
      final slot =
          (constraints.maxWidth - (children.length - 1) * 8) / children.length;
      final stacked = children.any((action) {
        final painter = TextPainter(
          text: TextSpan(
            text: action.label,
            style: context.playerMenuTheme.actionLabel,
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final width = painter.width + 28 + (action.icon == null ? 0 : 28);
        painter.dispose();
        return width > slot;
      });
      return stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  children[i],
                ],
              ],
            )
          : Row(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: children[i]),
                ],
              ],
            );
    },
  );
}
