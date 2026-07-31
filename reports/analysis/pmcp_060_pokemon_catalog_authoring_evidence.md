# PMCP-060 — Evidence Pack Catalogues Pokémon

Date : 2026-07-31
Lot : `PMCP-060 — Catalogues, espèces et données associées`
Verdict proposé : `DONE`

## Résumé exécutif

Le lot ajoute une façade pure Dart pour les catalogues génériques et les
documents species/learnset/evolution/media. Les champs JSON inconnus sont
conservés, les références inter-documents sont validées en batch, et les
écritures utilisent les transactions atomiques existantes avec préimage exacte
en base64 pour les remplacements/suppressions.

L’import externe reste un plan sans effet de bord : une source réseau n’est
applicable qu’après `allowNetwork=true`, et aucun client HTTP n’est caché dans
le package d’authoring.

## Audit initial et verdicts

État Git initial du scope : commit `69f22c9b feat(authoring): add cinematic
authoring gate`, sans changement PMCP-060. L’audit a confirmé que les données
Pokémon runtime/editor vivent en fichiers JSON externes déclarés par
`ProjectPokemonConfig`, alors que `map_authoring` doit rester indépendant de
Flutter et de `map_editor`.

| Passe | Verdict | Signal |
|---|---|---|
| Audit gameplay | Conforme | Familles et chemins canoniques identifiés |
| Audit architecture | Conforme | Aucun lien `map_authoring -> map_editor` ajouté |
| TDD | Conforme | RED sur les quatre façades, puis 4 preuves vertes |
| Tests authoring | Conforme | 273 tests passent |
| Analyse authoring | Conforme | Aucune issue |
| Critique finale | Conforme avec limites | Modèle JSON volontairement générique |

Trois fichiers de tests `map_editor` hors scope ont été observés modifiés
pendant la vérification. Ils n’ont été ni lus, ni modifiés, ni staged par ce lot.
Le dossier externe `.superpowers/...` reste également hors scope.

## Fichiers et zones modifiées

Créés :

- `packages/map_authoring/lib/src/domains/gameplay/pokemon_catalog_actions.dart`
- `packages/map_authoring/test/domains/gameplay/pokemon_catalog_authoring_test.dart`
- `reports/analysis/pmcp_060_pokemon_catalog_authoring_evidence.md`
- `reports/analysis/pmcp_060_pokemon_catalog_authoring_evidence_appendix.md`

Modifiés :

- `packages/map_authoring/lib/map_authoring.dart` : export public.
- `packages/map_authoring/lib/src/domains/maps/map_mutation_dispatcher.dart` :
  neuf actions documentaires enregistrées.
- `packages/map_authoring/lib/src/registry/resource_kind_registry.dart` :
  ressource `pokemonDocument`.
- `packages/map_authoring/test/registry/action_registry_test.dart` : liste
  canonique exacte mise à jour.

L’annexe contient le texte intégral des deux fichiers créés hors rapports. Le
diff du commit dédié fournit les zones exactes des fichiers modifiés.

## Contrat livré

- Catalogue générique avec upsert/delete par identité stable `id` ou `slug`.
- Documents typés par famille, mais payloads conservés sans perte de champs.
- Validation batch : doublons, document orphelin, cible d’évolution inconnue,
  variante média par défaut absente.
- Neuf actions write/delete limitées aux répertoires de
  `ProjectPokemonConfig` et aux fichiers `.json`.
- Remplacement/suppression avec préimage exacte et CAS transactionnel ; une
  création omet volontairement la préimage et échoue si le fichier existe.
- Import preview déterministe, fingerprinté, sans I/O et avec consentement
  réseau explicite.

## Commandes et résultats exacts

```text
cd packages/map_authoring && dart test \
  test/domains/gameplay/pokemon_catalog_authoring_test.dart
RED initial : PokemonJsonDocument, PokemonCatalogAuthoringService,
PokemonDataBatchValidator et PokemonImportPlanner absents.
Résultat final : 00:00 +4: All tests passed!

cd packages/map_authoring && dart test
00:14 +273: All tests passed!

cd packages/map_authoring && dart analyze
Analyzing map_authoring...
No issues found!
```

## Roadmap gameplay

Le lot fournit l’authoring de données consommées par les familles
`FG-020–FG-053`, `FG-060–FG-079`, `FG-100–FG-108` et `FG-140–FG-147`. Il ne
prouve pas leurs parcours runtime de bout en bout : leurs statuts restent donc
`TODO` ou `PARTIAL` conformément au roadmap. Aucun statut n’est modifié.

## Limites, risques et auto-critique

La validation est intentionnellement structurelle et extensible : elle ne
réplique pas toutes les règles métier du gros modèle Flutter existant. Ce choix
préserve la frontière de packages et les extensions JSON, mais les validations
spécifiques moves/abilities/items seront complétées par PMCP-061. Les fichiers
externes ne sont pas chargés implicitement dans le snapshot : l’appelant doit
fournir la préimage exacte, ce qui rend le CAS sûr mais plus explicite.

État Git final attendu : un commit PMCP-060 dédié ; modifications concurrentes
`map_editor` et `.superpowers/...` laissées hors staging.
