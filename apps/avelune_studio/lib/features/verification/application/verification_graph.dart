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
    return focus == null
        ? _overview(current)
        : _context(current, focus) ?? _missing(current, focus);
  }

  /// A diagnostic whose element is not in the index points at something that
  /// does not exist. It is drawn as missing, with the owners that name it,
  /// never replaced by a look-alike document.
  VerificationGraph _missing(
    VerificationReport current,
    NarrativeProjectDiagnostic diagnostic,
  ) {
    final label = current.labelFor(diagnostic);
    final nodes = <VerificationGraphNode>[
      VerificationGraphNode(
        id: diagnostic.stableKey,
        label: label,
        kind: _diagnosticKind(diagnostic),
        role: VerificationNodeRole.focus,
        missing: true,
      ),
    ];
    final edges = <VerificationGraphEdge>[];
    for (final issue in current.dependencies.issues) {
      if (issue.target.id != label && issue.target.id != diagnostic.factId) {
        continue;
      }
      if (issue.owner case final owner?) {
        nodes.insert(
          0,
          VerificationGraphNode(
            id: owner.id,
            label: current.labels[owner.id] ?? owner.id,
            kind: owner.kind,
            role: VerificationNodeRole.owner,
          ),
        );
        edges.add(
          VerificationGraphEdge(
            from: owner.id,
            to: diagnostic.stableKey,
            sense: _sense(issue.target.kind),
            unresolved: true,
          ),
        );
      }
    }
    return VerificationGraph(
      nodes: nodes,
      edges: edges,
      title: 'Référence introuvable : $label',
      focusId: diagnostic.stableKey,
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

  NarrativeDependencyKey? _keyOf(
    VerificationReport current,
    NarrativeProjectDiagnostic diagnostic,
  ) {
    final ids = <String>[
      for (final id in [
        diagnostic.worldRuleId,
        diagnostic.factId,
        diagnostic.dialogueId,
        diagnostic.cinematicId,
        diagnostic.stepId,
        diagnostic.chapterId,
        diagnostic.storylineId,
        diagnostic.sceneId,
        diagnostic.eventId,
        diagnostic.mapId,
      ])
        if (id != null && id.isNotEmpty) id,
    ];
    for (final id in ids) {
      for (final definition in current.dependencies.definitions) {
        if (definition.key.id == id) return definition.key;
      }
    }
    return null;
  }

  VerificationGraph? _context(
    VerificationReport current,
    NarrativeProjectDiagnostic diagnostic,
  ) {
    final key = _keyOf(current, diagnostic);
    if (key == null) return null;
    final index = current.dependencies;
    final nodes = <String, VerificationGraphNode>{};
    final edges = <VerificationGraphEdge>[];
    var hidden = 0;

    void put(
      NarrativeDependencyKey item,
      VerificationNodeRole role, {
      bool missing = false,
    }) {
      if (nodes.containsKey(item.id)) return;
      if (nodes.length >= _budget) {
        hidden++;
        return;
      }
      nodes[item.id] = VerificationGraphNode(
        id: item.id,
        label: current.labels[item.id] ?? item.id,
        kind: item.kind,
        role: role,
        missing: missing,
      );
    }

    put(key, VerificationNodeRole.focus);
    for (final usage in index.usagesFor(key)) {
      put(usage.owner, VerificationNodeRole.owner);
      if (!nodes.containsKey(usage.owner.id)) continue;
      edges.add(
        VerificationGraphEdge(
          from: usage.owner.id,
          to: key.id,
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
      if (!nodes.containsKey(usage.target.id)) continue;
      edges.add(
        VerificationGraphEdge(
          from: key.id,
          to: usage.target.id,
          sense: _sense(usage.target.kind),
          unresolved: !resolved,
        ),
      );
    }
    return VerificationGraph(
      nodes: nodes.values.toList(),
      edges: edges,
      title: 'Contexte de ${current.labels[key.id] ?? key.id}',
      focusId: key.id,
      hiddenCount: hidden,
    );
  }

  /// Without a selection, show the spine the author recognises: histories,
  /// their steps and the scenes they link, bounded and grouped.
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
      nodes[definition.key.id] = VerificationGraphNode(
        id: definition.key.id,
        label: definition.label,
        kind: definition.key.kind,
        role: VerificationNodeRole.context,
      );
    }
    for (final usage in index.usages) {
      if (!nodes.containsKey(usage.owner.id)) continue;
      if (!nodes.containsKey(usage.target.id)) continue;
      edges.add(
        VerificationGraphEdge(
          from: usage.owner.id,
          to: usage.target.id,
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
