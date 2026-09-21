import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/verification/application/verification_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'verification_view_state.dart';

part 'verification_detail.dart';
part 'verification_graph_view.dart';
part 'verification_list.dart';
part 'verification_summary.dart';

class VerificationWorkspacePage extends StatefulWidget {
  const VerificationWorkspacePage({
    super.key,
    required this.controller,
    required this.view,
    required this.onBack,
    this.backLabel = 'Histoire',
    this.onOpen,
    this.openLabel,
  });

  final VerificationWorkspaceController controller;
  final VerificationViewState view;
  final VoidCallback onBack;
  final String backLabel;

  /// Opens the editor responsible for a diagnostic. The page never repairs.
  final Future<void> Function(NarrativeProjectDiagnostic)? onOpen;

  /// Names the destination a diagnostic can reach, or null when none is.
  final String? Function(NarrativeProjectDiagnostic)? openLabel;

  @override
  State<VerificationWorkspacePage> createState() =>
      _VerificationWorkspacePageState();
}

class _VerificationWorkspacePageState extends State<VerificationWorkspacePage> {
  VerificationWorkspaceController get controller => widget.controller;
  VerificationViewState get view => widget.view;

  void refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _run() async {
    await controller.run();
    refresh();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 1000 ||
          MediaQuery.textScalerOf(context).scale(14) > 20;
      final tight = constraints.maxWidth < 1200;
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(compact),
            if (controller.phase == VerificationPhase.reading ||
                controller.phase == VerificationPhase.analysing)
              const LinearProgressIndicator(),
            if (controller.error case final message?)
              StudioNotice(message, isError: true),
            if (controller.report != null && controller.stale)
              const StudioNotice(
                'Modifications depuis la vérification : ce rapport porte sur '
                'un état antérieur. Relancez le contrôle pour juger la version '
                'actuelle.',
              ),
            const SizedBox(height: 10),
            Expanded(child: compact ? _centre(true) : _wideBody(tight)),
          ],
        ),
      );
    },
  );

  Widget _header(bool compact) => StudioPageHeader(
    title: 'Vérification narrative',
    description: compact ? _shortSituation() : _situation(),
    alignActionsToEnd: true,
    actions: [
      StudioTool(
        label: 'Retour à ${widget.backLabel}',
        icon: Icons.arrow_back,
        onPressed: widget.onBack,
      ),
      if (compact)
        StudioTool(
          label: 'Graphe',
          icon: Icons.hub_outlined,
          onPressed: () => _sheet(_graphPanel()),
        ),
      if (compact)
        StudioTool(
          label: 'Synthèse',
          icon: Icons.insights_outlined,
          onPressed: () => _sheet(_summary()),
        ),
      if (compact)
        StudioTool(
          label: 'Détail',
          icon: Icons.article_outlined,
          onPressed: () => _sheet(_detail()),
        ),
      if (controller.running)
        StudioTool(
          label: 'Abandonner le contrôle',
          icon: Icons.close,
          onPressed: () {
            controller.abandon();
            refresh();
          },
        ),
      StudioButton(
        label: 'Lancer la vérification',
        icon: Icons.play_arrow,
        loading: controller.running,
        onPressed: controller.running ? null : () => unawaited(_run()),
      ),
    ],
  );

  /// Says what was controlled and when, never what was not.
  String _situation() {
    final report = controller.report;
    return switch (controller.phase) {
      VerificationPhase.reading => 'Lecture des documents du projet…',
      VerificationPhase.analysing => 'Analyse en cours…',
      VerificationPhase.cancelled =>
        'Contrôle abandonné. Aucun résultat n’a été adopté.',
      _ when report == null =>
        'Aucun contrôle lancé : rien n’a encore été analysé dans ce projet.',
      _ =>
        'Contrôle du ${_stamp(report.generatedAt)} sur la version de travail '
            '· ${report.scope.join(' · ')}',
    };
  }

  /// At small sizes the scope moves into the summary sheet: the header keeps
  /// the launch, the chosen problem and the editor within reach.
  String _shortSituation() {
    final report = controller.report;
    return switch (controller.phase) {
      VerificationPhase.reading => 'Lecture…',
      VerificationPhase.analysing => 'Analyse…',
      VerificationPhase.cancelled => 'Contrôle abandonné.',
      _ when report == null => 'Aucun contrôle lancé.',
      _ => 'Contrôle du ${_stamp(report.generatedAt)}',
    };
  }

  static String _stamp(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year} '
        'à ${two(value.hour)}:${two(value.minute)}';
  }

  Widget _wideBody(bool tight) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (view.summaryOpen) ...[
        SizedBox(width: tight ? 240 : 272, child: _summary()),
        const SizedBox(width: 10),
      ],
      Expanded(child: _centre()),
      if (view.detailOpen) ...[
        const SizedBox(width: 10),
        SizedBox(width: tight ? 280 : 312, child: _detail()),
      ],
    ],
  );

  /// At small sizes the graph joins the summary and the detail as a panel the
  /// author opens: the list, the launch and the editor keep the room.
  Widget _centre([bool compact = false]) => compact
      ? _listPanel(true)
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 4, child: _graphPanel()),
            const SizedBox(height: 10),
            Expanded(flex: 6, child: _listPanel(false)),
          ],
        );

  Future<void> _sheet(Widget child) async {
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 360,
          height: MediaQuery.sizeOf(context).height * .8,
          child: child,
        ),
      ),
    );
    refresh();
  }
}
