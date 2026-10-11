# AC-01 — Cœur de conversion et enveloppes

## Résultat et portée

AC-01 fournit `packages/avelune_converter_core`, package Dart pur : sept enveloppes strictes, invariants, IDs stables, empreintes canoniques, admission de plan avant port et protocole minimal de session/job. Les 231 tests passent, l’analyse ne remonte aucune issue, le probe public compile en AOT et s’exécute avec exit 0. Verdict technique : PASS, TO REVIEW ; DONE reste réservé à Yoahn.

La finalité confirmée est une application desktop qui transforme un jeu RPG Maker / Pokémon Essentials en projet Avelune natif éditable dans Studio, située dans `apps/avelune_converter`. AC-01 construit son cœur partagé. Le dossier applicatif, CLI, scanner, parseur RMXP/Marshal, writer et adaptateurs ne sont pas créés ici. Aucune conversion réelle, ouverture Studio ni trace gameplay n’est attestée.

## Gate 0 et audit initial

Demande directe : poursuivre AC-01 après AC-00, conserver l’emplacement applicatif et laisser les PID 6272/82303 tranquilles. Le kit constitue une spécification de lot ; il ne vaut pas autorisation de publication, mutation Git ou exécution du jeu source.

AC-00 a identifié les API publiques natives `map_authoring_api.dart` / `map_authoring_local.dart`, la frontière core/adapters/app et les inconnues du rendu/événementiel. Ses quatre artefacts restent préexistants et inchangés. Les contrats du kit décrivent le workspace du convertisseur ; ils ne deviennent pas le format natif du Player.

Audit des sept schémas/exemples du kit : version 1.0, propriétés interdites aux racines, IDs/hashes contraints, exampleOnly obligatoire, contextes et locators explicites. Les sept schémas embarqués sont sémantiquement égaux au kit et les sept fixtures identiques octet pour octet. Aucun changement de map_core ni import Flutter nécessaire.

Instructions lues : AGENTS ancêtres/racine, codex_rule.md, index des skills locaux, TDD, verification-before-completion et using-pokemap-mcp. Les cinq rôles audit, développement, tests, build/validation et critique sont couverts par le parent et les agents existants. Aucun commentaire dans le code, conformément à la consigne directe de Yoahn, prioritaire sur la demande générale de codex_rule.md.

État initial : main, HEAD `edb8a9aa079837653717b58da7dbad8926e40691`, 261 chemins dirty. Status complet et SHA par fichier dans evidence/index.json ; empreinte de contenu initial `722d4c735aa946bca0586a98d329b519214de71cbdc253642b9bd980c8f21eb5`.

## Décisions et invariants

- Un barrel public, parties privées, racines final/sealed et factories validantes ; projections typées et collections profondément immuables.
- JSON inerte : cycles, objets hôtes, clés non String et nombres non finis refusés ; quotas avant copie. Les clés comptent avant construction du path. maxLength des schémas compte les points de code Unicode ; quotas mémoire explicites en code units.
- Validation privée bornée aux mots clés utilisés par les sept schémas figés ; aucune prétention de moteur JSON Schema générique ou certification draft 2020-12.
- Canonisation : clés triées, listes sémantiques conservées. Identité s1: issue du tuple version/namespace/domaine/ID source ; noms et snapshots exclus de l’identité métier.
- IR : cellules largeur×hauteur, z/IDs uniques, événements/locators bornés. Assets : rectangles dans la source, canvas après D4, offsets/ancrages exacts, révision approuvée courante.
- PlanContext défensif : snapshot/profil/règles/décisions/session/version, références fermées, actions auditées et SHA de plan/candidats approuvés. Les reçus viennent de la revue ; ils ne sont pas calculés automatiquement pendant l’admission.
- AdmittedPlan a un constructeur privé. applyConversionPlan admet avant le port ; démos, contextes périmés, références inconnues et capacités non prouvées sont refusés.
- Toute opération planned consommant un candidat exige une approbation humaine courante, quel que soit son domaine. Les erreurs sécurité/source invalide ne sont pas consentables. Une perte acceptée est limitée à étude et à une décision confirmée au même locator.
- Rapports : extracted/adapted sont des étapes ; compteurs par dénominateur, sans somme naïve. verified/published exige sourceUnchanged passé, artefacts et aucun check failed ; conversion exige load/save-reload natifs ; playableSlice ajoute visuel/gameplay et refuse les pertes étude. Inventory conserve N/A natif. En étude, visuel/gameplay restent des gates séparées, notRun ne devient jamais passed.
- Sessions/jobs en mémoire : révisions positives, unités stables, compteurs monotones, total nullable, annulation terminale ; mises à jour étrangères/périmées/post-annulation refusées. Pas de store durable ni de worker réel.
- Ports abstraits seulement, aucun accès disque/réseau caché. Production : dart:collection, dart:convert et crypto ; aucune dépendance Flutter/Avelune cible.
- Parité MCP N/A ici : aucun authoring, modèle natif, import/export ou transport existant changé. Le futur adaptateur devra prouver ses transports via l’API canonique ; ce N/A ne prouve pas le writer.

## Inventaire complet et zones créées

Tous les fichiers produit/test ci-dessous sont nouveaux. Aucun fichier produit préexistant édité. Les zones constituent le découpage des changements ; sources et SHA sont les preuves canoniques, sans recopier tout le code dans ce rapport.

| Fichier | Zone, raison et impact |
|---|---|
| `packages/avelune_converter_core/analysis_options.yaml` | 1 : lints du nouveau package. |
| `packages/avelune_converter_core/lib/avelune_converter_core.dart` | 1–13 : barrel public et parties internes. |
| `packages/avelune_converter_core/lib/src/admission.dart` | 3–17 : identité ; 19–55 : contexte ; 57–248 : admission ; 250–294 : application/vision ; fin : locators. |
| `packages/avelune_converter_core/lib/src/domain_validation.dart` | 3–38 : unicité/chemins ; 39–223 : invariants ; 225–242 : diagnostics ; 244–298 : succès des rapports. |
| `packages/avelune_converter_core/lib/src/identity.dart` | 3–53 : ContractError, ConverterId, Sha256Hash, ContractLimits. |
| `packages/avelune_converter_core/lib/src/jobs.dart` | 3–87 : session/révision, compteurs par unité, transitions/annulation. |
| `packages/avelune_converter_core/lib/src/json_validation.dart` | 3–72 : JSON inerte/quota ; 74–198 : forme ; 200–222 : canonisation/SHA. |
| `packages/avelune_converter_core/lib/src/models.dart` | 3–116 : enums ; 118–732 : sept DTO et projections ; 734–783 : factories/décodage. |
| `packages/avelune_converter_core/lib/src/ports.dart` | 3–26 : interfaces horloge, source/fichier, raster, session et vision. |
| `packages/avelune_converter_core/lib/src/schema_catalog.dart` | 3–6 : sept schémas embarqués, égalité sémantique vérifiée. |
| `packages/avelune_converter_core/pubspec.yaml` | 1–14 : Dart pur ; crypto en production, test/lints en développement. |
| `packages/avelune_converter_core/test/admission_test.dart` | Tout le fichier : helpers et 28 tests IR-02/03, décisions/actions/révisions/vision. |
| `packages/avelune_converter_core/test/contracts_test.dart` | 1–37 : IR-01, sept round trips et refus. |
| `packages/avelune_converter_core/test/domain_test.dart` | 1–281 : 38 tests de domaine/immutabilité/empreintes. |
| `packages/avelune_converter_core/test/edge_cases_test.dart` | 1–178 : 94 tests requis/types/bornes/Unicode/quotas. |
| `packages/avelune_converter_core/test/fixtures/asset_candidate.example.json` | 1–72 : exemple du kit conservé octet pour octet. |
| `packages/avelune_converter_core/test/fixtures/conversion_plan.example.json` | 1–64 : exemple du kit conservé octet pour octet. |
| `packages/avelune_converter_core/test/fixtures/conversion_report.example.json` | 1–58 : exemple du kit conservé octet pour octet. |
| `packages/avelune_converter_core/test/fixtures/public_api_probe.dart` | 1–43 : consommateur du barrel pour compilation AOT/exécution. |
| `packages/avelune_converter_core/test/fixtures/review_decisions.example.json` | 1–19 : exemple du kit conservé octet pour octet. |
| `packages/avelune_converter_core/test/fixtures/source_map_ir.example.json` | 1–55 : exemple du kit conservé octet pour octet. |
| `packages/avelune_converter_core/test/fixtures/target_capabilities.example.json` | 1–28 : exemple du kit conservé octet pour octet. |
| `packages/avelune_converter_core/test/fixtures/vision_response.example.json` | 1–29 : exemple du kit conservé octet pour octet. |
| `packages/avelune_converter_core/test/jobs_test.dart` | 1–109 : 12 tests de transitions/révision/annulation/progression. |
| `packages/avelune_converter_core/test/review_guards_test.dart` | Tout le fichier : 38 régressions des findings, reçus et états/scopes. |

Les trois autres fichiers créés : `documentation/reports/converter/AC-01/01_core_contracts.md` (rapport consolidé), `documentation/reports/converter/AC-01/evidence/commands.json` (receipts) et `documentation/reports/converter/AC-01/evidence/index.json` (provenance, Git initial/final et inventaire SHA). Le pubspec.lock local et .dart_tool issus de pub get restent ignorés selon le repo ; le SHA du lock et Dart 3.13.4 macos_arm64 sont conservés dans l’index. Binaire de probe uniquement sous /private/tmp.

## Vérification et échecs corrigés

Red/green : contrats 21 échecs de départ ; domaine 15 passent/23 échouent ; admission 3 passent/25 échouent ; jobs 12 échouent. Première suite complète : 193 passent. Les régressions de quota texte et portée de locator commencent à 92 passent/2 échouent, puis deviennent vertes.

Critique indépendante : P1 clés hors quota, P1 contenu approuvé substituable à revision identique, P2 rapports de succès sans checks. Suite de revue : 7 passent/29 échouent avant correction des deux points restants (les clés étaient déjà corrigées), puis verte, avec reçu exact/absent/défensif. Build/validation découvre l’opération maps contournant l’approbation ; son test donne 37 passent/1 échoue, puis passe après généralisation de la garde.

Erreurs intermédiaires de mise en œuvre : type de liste d’un helper, échappement de paths Dart, remplacement JavaScript interprétant $', puis regex de lint affectant un for de collection. Elles ont été corrigées dans les seuls fichiers nouveaux, en réécrivant explicitement les zones concernées. Analyse initiale : 1 warning et 43 infos ; une passe de correction échoue en compilation, puis l’analyse est propre. Premier contrôle de format du probe : 1 fichier à formatter, corrigé. Les receipts distinguent ces échecs des résultats finaux.

Commandes depuis packages/avelune_converter_core :

| Commande | Résultat frais final |
|---|---|
| `dart pub get --offline` | `Got dependencies!` ; exit 0 ; crypto 3.0.7, test 1.33.0 ; lock local ignoré. |
| `dart test --reporter expanded` | `00:00 +231: All tests passed!` ; exit 0. |
| `dart analyze` | `No issues found!` ; exit 0. |
| `dart format --output=none --set-exit-if-changed lib test` | `Formatted 16 files (0 changed) in 0.05 seconds.` ; exit 0. |
| `dart compile exe test/fixtures/public_api_probe.dart -o /private/tmp/avelune-ac01-public-api-01a12c88` | `Generated: /private/tmp/avelune-ac01-public-api-01a12c88` ; exit 0. |
| `/private/tmp/avelune-ac01-public-api-01a12c88` | exit 0, stdout vide. |
| Audit Python schémas/fixtures/imports | Sept schémas égaux, sept fixtures identiques, imports autorisés ; exit 0. |

IR-01 : sept enveloppes strictes, champs interdits/requis/version/types/bornes et invariants, immutabilité. IR-02 : IDs indépendants des noms/snapshots et distincts par namespace/domaine/source. IR-03 : démonstration refusée avec zéro appel cible ; aucun writer filesystem dans ce lot.

Les suites natives AC-00 ne sont pas rejouées : aucun package cible, API native ou transport n’est changé ni importé. Les 158 tests AC-00 restent une preuve datée du lot précédent, pas un résultat frais AC-01. Aucun test Flutter, app ou build desktop applicable au core pur.

Chaque run supervisé enregistre runner et descendants avec UID/heure de démarrage/commande. Runs finaux : aucun descendant confirmé restant, aucun signal émis. Aucun kill blanket, nettoyage d’ancien MCP ou action sur PID protégés.

## Verdict des passes

Audit initial : target_contracts et parent confirment core/adapters/app sans couplage Flutter, inconnues conservées. Développement : parent implémente DTO, gardes et protocole inerte. Tests : test_validation en lecture établit la matrice/cas négatifs ; parent exécute.

Critique finale target_contracts : PASS après les trois corrections, frontière pure, reçus cohérents ; aucune preuve de conversion réelle. Build/Validation finale test_validation : garde de consommation maps relue, aucune réserve restante, probe public suffisant pour bibliothèque. Les agents n’ont exécuté aucune suite ni modifié fichier/PID ; les 231 tests/analyse/build sont les exécutions fraîches du parent.

## Git, hygiène et suivi

Git final : main, même HEAD, 289 chemins dirty : 261 préexistants + 28 fichiers AC-01. Les empreintes des 261 chemins initiaux sont identiques ; aucun ajout/suppression/changement étranger entre snapshots. Status complet dans l’index. Aucune opération Git d’écriture, commit ou push.

`git diff --check` passe (exit 0, stdout vide) sur les diffs suivis préexistants, pas les nouveaux fichiers untracked ; le format Dart des nouveaux fichiers est vérifié séparément. Le kit invoqué exige un rapport/Evidence Pack par lot : un seul Markdown AC-01 ajouté. Budget local borné à deux car AC-00 reste untracked : `POKEMAP_MARKDOWN_MAX_NEW=2 bash tools/scripts/check_markdown_hygiene.sh`. Résultat frais : `Markdown hygiene: 2 new Markdown file(s), all in canonical locations.` ; exit 0. Cet override n’autorise aucun document supplémentaire.

Ticket : https://app.notion.com/p/3f6197a7bfa5810ea219f8c28b1cd14a, famille existante 14 Monde, exploration et narration — Post Bêta, Gate bêta non, Hors gate. TO REVIEW ; DONE attend Yoahn. Aucune famille/dépendance bêta ajoutée.

## Auto-critique et limites

DTO validés ne signifie ni décodage RMXP, ni reconnaissance de toutes les versions Essentials, ni projet natif exporté. Source/profil/règles et flags de checks restent déclarés ; le core vérifie la cohérence, les futurs adaptateurs doivent vérifier les bytes et receipts réels. Un SHA fourni dans le contexte est une entrée de confiance, pas une attestation autonome d’un geste humain.

Profils de tests synthétiques, distincts du profil audité AC-00. Aucun port concret, store durable, ordonnanceur, fournisseur IA, corpus réel ou script Ruby exécuté. Le validateur couvre les sept schémas figés ; leur évolution impose des tests, sans fallback legacy. Canonisation du JSON Dart accepté, sans prétention RFC 8785 ou portabilité illimitée des nombres entre langages.

Le writer devra empêcher les mutations hors admission, gérer staging/destination neuve et prouver sauvegarde/rechargement. Studio, rendu visuel, Player et gameplay restent des gates distinctes. Prochain lot proposé : AC-02, inventaire/snapshot sûr en lecture seule selon le kit ; non commencé. Le cap final reste l’application Essentials → Avelune Studio dans apps/avelune_converter.
