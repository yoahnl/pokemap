part of 'verification_workspace_controller.dart';

extension VerificationGraphs on VerificationWorkspaceController {
  static const _budget = 24;

  /// The context of the current selection, or a bounded overview when nothing
  /// is selected. Both stay inside a node budget: the drawing is a reading
  /// aid, not a thousand-node picture kept for the sake of the mockup.
  VerificationGraph get graph {
    final current = report;
    if (current == null) {
      return const VerificationGraph(
        nodes: [],
        edges: [],
        title: 'Aucun contrôle lancé',
      );
    }
    final focus = selected;
    if (focus == null) return _overview(current);
    final resolved = verificationResolve(current.dependencies, focus);
    if (resolved.key case final key?) return _context(current, key);
    return _missing(current, focus, resolved.ambiguous);
  }

  VerificationGraph _context(
    VerificationReport current,
    NarrativeDependencyKey key,
  ) {
    final index = current.dependencies;
    final nodes = <String, VerificationGraphNode>{};
    final edges = <VerificationGraphEdge>[];
    var hidden = 0;

    void put(
      NarrativeDependencyKey item,
      VerificationNodeRole role, {
      bool missing = false,
    }) {
      final id = verificationKeyId(item);
      if (nodes.containsKey(id)) return;
      if (nodes.length >= _budget) {
        hidden++;
        return;
      }
      nodes[id] = VerificationGraphNode(
        key: item,
        label: current.labelOf(item),
        role: role,
        missing: missing,
      );
    }

    put(key, VerificationNodeRole.focus);
    for (final usage in index.usagesFor(key)) {
      put(usage.owner, VerificationNodeRole.owner);
      if (!nodes.containsKey(verificationKeyId(usage.owner))) continue;
      edges.add(
        VerificationGraphEdge(
          from: verificationKeyId(usage.owner),
          to: verificationKeyId(key),
          sense: _sense(key.kind),
          unresolved:
              usage.resolution != NarrativeDependencyResolution.resolved,
        ),
      );
    }
    for (final usage in index.usagesOwnedBy(key)) {
      final resolved =
          usage.resolution == NarrativeDependencyResolution.resolved;
      put(usage.target, VerificationNodeRole.target, missing: !resolved);
      if (!nodes.containsKey(verificationKeyId(usage.target))) continue;
      edges.add(
        VerificationGraphEdge(
          from: verificationKeyId(key),
          to: verificationKeyId(usage.target),
          sense: _sense(usage.target.kind),
          unresolved: !resolved,
        ),
      );
    }
    return VerificationGraph(
      nodes: nodes.values.toList(),
      edges: edges,
      title: 'Contexte de ${current.labelOf(key)}',
      focusId: verificationKeyId(key),
      hiddenCount: hidden,
    );
  }

  /// A diagnostic whose element is not in the index points at something that
  /// does not exist, or at a name several documents answer to. Both are drawn
  /// as such, never replaced by a look-alike.
  VerificationGraph _missing(
    VerificationReport current,
    NarrativeProjectDiagnostic diagnostic,
    bool ambiguous,
  ) {
    final candidate = verificationCandidates(diagnostic).firstOrNull;
    final key = NarrativeDependencyKey(
      candidate?.$1 ?? _diagnosticKind(diagnostic),
      candidate?.$2 ?? diagnostic.path,
    );
    final label = candidate?.$2 ?? diagnostic.path;
    final nodes = <VerificationGraphNode>[
      VerificationGraphNode(
        key: key,
        label: label,
        role: VerificationNodeRole.focus,
        missing: true,
      ),
    ];
    final edges = <VerificationGraphEdge>[];
    if (!ambiguous) {
      for (final issue in current.dependencies.issues) {
        if (issue.target.kind != key.kind || issue.target.id != key.id) {
          continue;
        }
        if (issue.owner case final owner?) {
          nodes.insert(
            0,
            VerificationGraphNode(
              key: owner,
              label: current.labelOf(owner),
              role: VerificationNodeRole.owner,
            ),
          );
          edges.add(
            VerificationGraphEdge(
              from: verificationKeyId(owner),
              to: verificationKeyId(key),
              sense: _sense(key.kind),
              unresolved: true,
            ),
          );
        }
      }
    }
    return VerificationGraph(
      nodes: nodes,
      edges: edges,
      title: ambiguous
          ? 'Cible ambiguë : plusieurs documents répondent à « $label »'
          : 'Référence introuvable : $label',
      focusId: verificationKeyId(key),
    );
  }

  NarrativeDependencyTargetKind _diagnosticKind(
    NarrativeProjectDiagnostic diagnostic,
  ) => switch (diagnostic.domain) {
    NarrativeProjectDiagnosticDomain.fact => NarrativeDependencyTargetKind.fact,
    NarrativeProjectDiagnosticDomain.scene =>
      NarrativeDependencyTargetKind.scene,
    NarrativeProjectDiagnosticDomain.dialogue =>
      NarrativeDependencyTargetKind.dialogue,
    NarrativeProjectDiagnosticDomain.cinematic =>
      NarrativeDependencyTargetKind.cinematic,
    NarrativeProjectDiagnosticDomain.storyline =>
      NarrativeDependencyTargetKind.storyline,
    NarrativeProjectDiagnosticDomain.worldRule =>
      NarrativeDependencyTargetKind.worldRule,
    NarrativeProjectDiagnosticDomain.event =>
      NarrativeDependencyTargetKind.eventV2,
    _ => NarrativeDependencyTargetKind.sourceMap,
  };

  /// Without a selection, show the spine the author recognises: histories,
  /// their chapters and steps, the scenes and the rules, bounded and grouped.
  VerificationGraph _overview(VerificationReport current) {
    final index = current.dependencies;
    final nodes = <String, VerificationGraphNode>{};
    final edges = <VerificationGraphEdge>[];
    var hidden = 0;
    const spine = {
      NarrativeDependencyTargetKind.storyline,
      NarrativeDependencyTargetKind.chapter,
      NarrativeDependencyTargetKind.step,
      NarrativeDependencyTargetKind.scene,
      NarrativeDependencyTargetKind.worldRule,
      NarrativeDependencyTargetKind.fact,
    };
    for (final definition in index.definitions) {
      if (!spine.contains(definition.key.kind)) continue;
      if (nodes.length >= _budget) {
        hidden++;
        continue;
      }
      nodes[verificationKeyId(definition.key)] = VerificationGraphNode(
        key: definition.key,
        label: definition.label,
        role: VerificationNodeRole.context,
      );
    }
    for (final usage in index.usages) {
      final from = verificationKeyId(usage.owner);
      final to = verificationKeyId(usage.target);
      if (!nodes.containsKey(from) || !nodes.containsKey(to)) continue;
      edges.add(
        VerificationGraphEdge(
          from: from,
          to: to,
          sense: _sense(usage.target.kind),
          unresolved:
              usage.resolution != NarrativeDependencyResolution.resolved,
        ),
      );
    }
    return VerificationGraph(
      nodes: nodes.values.toList(),
      edges: edges,
      title: nodes.isEmpty
          ? 'Aucune histoire à relier dans ce projet'
          : 'Vue globale des histoires',
      hiddenCount: hidden,
    );
  }

  VerificationEdgeSense _sense(NarrativeDependencyTargetKind kind) =>
      switch (kind) {
        NarrativeDependencyTargetKind.fact ||
        NarrativeDependencyTargetKind.badge ||
        NarrativeDependencyTargetKind.item => VerificationEdgeSense.condition,
        NarrativeDependencyTargetKind.storyline ||
        NarrativeDependencyTargetKind.chapter ||
        NarrativeDependencyTargetKind.step => VerificationEdgeSense.progression,
        NarrativeDependencyTargetKind.sourceMap =>
          VerificationEdgeSense.location,
        _ => VerificationEdgeSense.reference,
      };
}
