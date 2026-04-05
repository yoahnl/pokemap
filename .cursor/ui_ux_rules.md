# UI / UX — PokeMap (desktop, no-code)

## Public

Créateurs de jeu **non développeurs** en priorité. Tout écran doit être défendable comme « compréhensible sans README technique ».

## Layout type studio (Cutscene et analogues)

- **Gauche** : navigation légère ou **palette** (briques, pas arborescence technique).
- **Centre** : **structure** du contenu (flow, timeline, carte logique) — jamais un mur de champs.
- **Droite** : **détails** du sélectionné — inspecteur, pas répétition du centre.

## Interdits visuels / cognitifs

- Graphe **spaghetti** ou nœuds libres pour le public no-code Cutscene.
- **Jargon moteur** dans les libellés (`ScenarioNode`, `payload`, `edge`, etc.).
- **Piles de formulaires** au centre « parce que c’est plus simple à coder ».

## Desktop

- Cibles **macOS / desktop** : densité raisonnable, colonnes redimensionnables quand c’est déjà le pattern (ex. Cutscene Workbench).
- Feedback clair : sauvegarde, erreurs, **advisories** runtime séparés des erreurs bloquantes.

## Cohérence

- Réutiliser les motifs chrome existants (`EditorChrome`, panneaux îlots) plutôt que d’inventer un troisième style par feature.

## Relation code

- Si une contrainte UX impose une structure de données, la **documenter** dans `.cursor/cutscene_studio_rules.md` ou dans un rapport `reports/` plutôt que de laisser la complexité dans un seul widget géant.
