export type ReliabilityTaskId = `T${1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10}`;
export type ReliabilityFixtureVariant =
  | "healthy" | "shoreGap" | "floatingCliff" | "missingCliff"
  | "interiorHole" | "dockOverlap" | "ambiguousMaterial" | "noWorkingMap";
export type ReliabilityBaseline = "manual_actions" | "partial";

export interface MapReliabilityCase {
  id: ReliabilityTaskId;
  fixture: ReliabilityFixtureVariant;
  instruction: string;
  criteria: readonly string[];
  baseline: ReliabilityBaseline;
  baselineLimit?: string;
  reservedVariants: readonly number[];
}

export const mapReliabilityCases: readonly MapReliabilityCase[] = [
  { id: "T1", fixture: "shoreGap", instruction: "Retirer la berge en préservant son sol avec le matériau Herbe.",
    criteria: ["feature_absent", "expected_ground_material", "outside_region_unchanged", "reopened_values_match"],
    baseline: "partial", baselineLimit: "Explicit paint then delete is tested; synthetic cliff has no ground replacement footprint. Atomic ground provenance remains unproven.", reservedVariants: [] },
  { id: "T2", fixture: "floatingCliff", instruction: "Réparer la falaise flottante en conservant son contour.",
    criteria: ["no_crown_base_diagnostics", "expected_contour", "outside_region_unchanged", "reopened_values_match"],
    baseline: "manual_actions", reservedVariants: [] },
  { id: "T3", fixture: "missingCliff", instruction: "Ajouter une falaise native sur la marche, avec la terre à droite.",
    criteria: ["fresh_feature", "expected_oriented_contour", "no_structural_diagnostics", "outside_region_unchanged", "reopened_values_match"],
    baseline: "manual_actions", reservedVariants: [1, 2, 3] },
  { id: "T4", fixture: "interiorHole", instruction: "Boucher le trou intérieur avec le sol environnant.",
    criteria: ["expected_ground_material", "outside_region_unchanged", "reopened_values_match"],
    baseline: "manual_actions", reservedVariants: [] },
  { id: "T5", fixture: "dockOverlap", instruction: "Dégager le ponton sans retirer les modules voisins.",
    criteria: ["conflicting_slots_absent", "unaffected_modules_preserved", "dock_preserved", "reopened_values_match"],
    baseline: "manual_actions", reservedVariants: [] },
  { id: "T6", fixture: "healthy", instruction: "Peindre la cellule et le nom de matériau indiqués dans le contexte public de la tâche.",
    criteria: ["expected_ground_material", "outside_region_unchanged", "reopened_values_match"],
    baseline: "partial", baselineLimit: "Reference resolves the name manually and supplies its ID. Canonical name resolution is not certified.", reservedVariants: [1, 2, 3] },
  { id: "T7", fixture: "noWorkingMap", instruction: "Créer une carte native avec terrain peint et relief à partir des ressources existantes.",
    criteria: ["new_map_present", "native_layers", "expected_ground_material", "fresh_feature", "resources_preserved", "reopened_values_match"],
    baseline: "partial", baselineLimit: "Reference covers map creation, terrain layer and paint; full relief creation baseline remains incomplete.", reservedVariants: [1, 2, 3] },
  { id: "T8", fixture: "ambiguousMaterial", instruction: "Demander le choix entre les matériaux homonymes sans écrire.",
    criteria: ["ambiguous_result", "useful_candidates", "zero_writes"],
    baseline: "partial", baselineLimit: "Fixture proves two distinct candidates; canonical ambiguity response remains unproven.", reservedVariants: [] },
  { id: "T9", fixture: "interiorHole", instruction: "Reprendre une application dont la réponse a été perdue, après réouverture.",
    criteria: ["same_receipt", "zero_replay_writes", "reopened_values_match"],
    baseline: "partial", baselineLimit: "Historical planId replay passes; semantic operation identity without a retained plan is not certified.", reservedVariants: [] },
  { id: "T10", fixture: "interiorHole", instruction: "Après undo, appliquer la même peinture avec une nouvelle identité.",
    criteria: ["undo_restored_original", "new_receipt", "new_durable_application", "reopened_values_match"],
    baseline: "manual_actions", reservedVariants: [] },
];

export interface ReliabilityOracleObservation {
  checks: Readonly<Record<string, boolean | undefined>>;
  mapHealthVerdict?: "pass" | "fail" | "incomplete";
  source: "persisted_independent_observation";
}

export interface ReliabilityOracleResult {
  verdict: "pass" | "fail" | "incomplete";
  failed: string[];
  missing: string[];
}

export function evaluateMapReliabilityCase(
  task: MapReliabilityCase,
  observation: ReliabilityOracleObservation,
): ReliabilityOracleResult {
  const failed = task.criteria.filter((criterion) => observation.checks[criterion] === false);
  const missing = task.criteria.filter((criterion) => observation.checks[criterion] === undefined);
  return {
    verdict: failed.length > 0 ? "fail" : missing.length > 0 ? "incomplete" : "pass",
    failed,
    missing,
  };
}

export function reliabilityCasesForSplit(split: "reference" | "reserved"): readonly {
  task: MapReliabilityCase;
  variant: number;
}[] {
  return mapReliabilityCases.flatMap((task) =>
    (split === "reference" ? [0] : task.reservedVariants).map((variant) => ({ task, variant })),
  );
}
