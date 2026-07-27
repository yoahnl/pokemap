# PH-007 — Packaging & Golden Personalization E2E — Phase 7B

## Résumé exécutif

La Phase 7B a désormais une gate exécutable, sérialisable et liée à un candidat Git propre. Le candidat certifié est `28f78b38b48bb4207f0689e0e4283cf65db5d94e`.

Les quatre critères comportementaux sont **PASS** :

1. export → inspection → installation → intro → titre personnalisé → montage du jeu ;
2. fallbacks sûrs pour vidéo, fonte, audio de titre, branding et thème sémantique ;
3. parité entre preview éditeur et présentation packagée consommée au runtime ;
4. hashes, licence de fonte, codecs et preflight du package.

La gate release reste néanmoins **NO_GO** et le statut proposé de `PH-007` reste **PARTIAL**. Le build macOS Release réussit, mais sa copie installée termine avec le code `134` : le hardened runtime refuse `FlutterMacOS.framework` parce que les signatures ad hoc n'ont pas de Team ID cohérent. Gatekeeper rejette aussi l'application. Windows, Linux, iOS et Android sont explicitement non évalués.

Ce verdict est indépendant de `FG-185`, conformément à la roadmap.

## Nom et périmètre exacts

- Phase : **7B — Gate release personnalisation**
- Lot : **`PH-007` — Packaging & Golden Personalization E2E**
- Candidat de preuves : `28f78b38b48bb4207f0689e0e4283cf65db5d94e`
- État proposé : **`PH-007 = PARTIAL / NO_GO`**
- `FG-185` : non modifié, gate indépendante
- Roadmap canonique : non modifiée, car la demande n'autorisait pas une mise à jour de statut canonique

Le lot ajoute une preuve et un contrat de décision ; il ne modifie ni les règles gameplay, ni le rendu Flame, ni le format auteur de `map_core`.

## Audit initial

### Sources lues

- `pokemap_roadmap_mecaniques_fangame.md`
- `reports/gameplay/fg_000_remediation_and_personalization_roadmap.md`
- `AGENTS.md`
- `codex_rule.md`
- implémentations et tests existants de `PH-000` à `PH-006`
- preuves de distribution macOS de la Phase 7A, notamment `RM-071` et `RM-073`

### Constat avant implémentation

- Le paquet personnalisé savait déjà transporter branding, intro, typographie et thème.
- Le preflight existant certifiait hashes, H.264/AAC, licence de redistribution et références d'assets.
- Le Hub savait installer le paquet, résoudre sa présentation et démarrer une session en processus.
- Les fallbacks vidéo, fonte et audio existaient déjà dans des tests séparés.
- La preview éditeur utilisait le contrat canonique, mais aucun test ne la comparait directement à la projection packagée.
- Aucun reçu `PH-007` typé ne pouvait empêcher un faux GO construit à partir d'une preuve incomplète.
- La précédente preuve macOS annonçait déjà un risque de signature ad hoc ; il devait être revalidé pour le nouveau candidat.
- La critique finale a détecté que le fallback du thème invalide existait mais n'était pas couvert explicitement. Un test négatif a été ajouté avant la capture finale.

### Risques identifiés

- faux GO si une preuve de lancement plateforme manque ;
- reçu altérable si les champs dérivés `decision` et `platformMatrixStatus` sont acceptés sans recalcul ;
- mélange de preuves provenant de commits différents ;
- confusion entre preflight codec et décodage vidéo natif réel ;
- confusion entre build réussi et application distribuable ;
- transformation accidentelle de `PH-007` en dépendance de `FG-185`.

### Frontières conservées

- `map_distribution` possède le contrat de reçu et les décisions de packaging ;
- `map_editor` ne dépend pas des internes du runtime ;
- le Hub orchestre l'installation et la session sans déplacer de règle gameplay ;
- aucune désactivation de library validation ;
- aucune re-signature permissive ;
- aucune revendication de QA humaine ou de plateforme non exécutée.

## État Git initial

Commande :

```text
git status --short --untracked-files=all
git rev-parse HEAD
```

Résultat initial :

```text
<aucune sortie status : arbre propre>
6055d34e8780e2e726125bacaef960b39e8e8b96
```

Commits de code du lot :

```text
bb74c0652 test(personalization): add phase 7b release gate
28f78b38b test(personalization): cover invalid theme fallback
```

Le reçu et ce rapport sont commités séparément après le candidat afin que les preuves puissent référencer un SHA propre.

## Fichiers modifiés et créés

| Statut | Fichier | Zone | Raison et impact |
|---|---|---|---|
| Modifié | `packages/map_distribution/lib/map_distribution.dart:22` | barrel public | Exporte le reçu PH-007 sans coupler les autres packages à un chemin interne. |
| Créé | `packages/map_distribution/lib/src/personalization_release_gate_receipt.dart` | enums, preuves critère/plateforme, validation, JSON, décision | Reçu candidat-bound ; cardinalité exacte des quatre critères ; plateformes uniques ; décision dérivée et anti-tampering. |
| Créé | `packages/map_distribution/test/personalization_release_gate_receipt_test.dart` | 6 tests de contrat + validation externe conditionnelle | Couvre GO, critères manquants/dupliqués, plateformes dupliquées, lancement manquant/échoué, critère échoué, hashes/dates/schéma invalides et reçu final. |
| Modifié | `packages/map_editor/test/personalization/phase_5_personalization_golden_gate_test.dart:42-174` | projection du profil et assertions de parité | Compare layout, cinq surfaces sémantiques et trois rôles typographiques entre preview et manifest packagé. |
| Modifié | `apps/pokemap_hub/test/ui/player/phase_6_personalization_packaging_e2e_test.dart:22-271` | mode preuves, flow intro/session, JSON persistant | Lie le paquet au SHA propre, persiste package/installation/hashes, prouve intro→titre→jeu et rejet d'une vidéo installée corrompue. |
| Modifié | `apps/pokemap_hub/test/ui/player/phase_6_personalization_packaging_e2e_test.dart:277-330` | helpers de fixture, racine repo et candidat propre | Empêche une capture depuis un arbre dirty et calcule le hash de la fixture source. |
| Modifié | `apps/pokemap_hub/test/ui/player/hub_title_presentation_loader_test.dart:166-178,228-246` | cas négatif thème | Prouve qu'une couleur invalide désactive le thème projet sans bloquer le titre. |
| Créé | `reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json` | reçu final | Enregistre quatre PASS comportementaux, matrice cinq plateformes et décision calculée `NO_GO`. |
| Créé, ignoré | `docs/superpowers/plans/2026-07-27-phase-7b-personalization-release-gate.md` | plan d'exécution | Plan de travail local imposé par le workflow ; non tracké car `/docs/*` est ignoré. |
| Créé | `reports/gameplay/ph_007_personalization_release_gate.md` | présent rapport | Evidence Pack et verdict. Son contenu ne peut pas être inclus récursivement dans lui-même. |

## Détails précis des changements

### Contrat de reçu

`PersonalizationReleaseGateReceipt.validated` impose :

- SHA Git de 40 caractères hexadécimaux ;
- trois SHA-256 de 64 caractères ;
- horodatage UTC ;
- exactement une preuve pour chacun des quatre critères ;
- identifiants de plateformes uniques, insensibles à la casse ;
- codes de sortie non négatifs ;
- textes de synthèse et sources non vides.

`fromJson` recalcule `platformMatrixStatus` et `decision`. Un JSON dont les champs dérivés contredisent les preuves est rejeté.

### Parité éditeur/runtime

Le test éditeur compare directement `PersonalizationPreviewProjection` avec `built.manifest.presentation` pour :

- le layout du titre ;
- les surfaces titre, dialogue, menu, HUD overworld et HUD combat ;
- les fontes display, dialogue et nombres.

### Parcours installé

Le test Hub :

- exige un arbre Git propre en mode Evidence ;
- exporte et écrit un vrai `.pokemapgame` ;
- inspecte et preflighte le package ;
- installe dans une racine de support neuve ;
- résout les assets installés ;
- termine la machine d'état d'intro ;
- crée, prépare, démarre, arrête et dispose une session ;
- corrompt ensuite la vidéo installée et vérifie que le resolver rejette l'installation malsaine ;
- persiste le SHA du candidat, les reçus, les hashes et les assertions.

Le composant Flutter `HubIntroVideoPlayer` reste testé séparément avec son driver de lecture. Cette séparation évite de placer des E/S disque réelles sous l'horloge simulée de `testWidgets`.

### Fallback thème

Le test négatif injecte `primary: "not-a-color"`. Le resolver sémantique retourne `null`, le titre reste disponible et aucun asset n'est déclaré indisponible.

## Développement piloté par les tests et diagnostic

### RED initial attendu

```text
cd packages/map_distribution
dart test test/personalization_release_gate_receipt_test.dart
```

Résultat : échec de compilation attendu, les types `PersonalizationReleaseGateReceipt`, `PersonalizationReleaseCriterionEvidence` et `PersonalizationPlatformCodecEvidence` n'existaient pas encore.

### Diagnostic du test Hub

Une première tentative avait enveloppé tout le test E2E dans `testWidgets`. Le test n'atteignait aucun marqueur après le démarrage et ne terminait pas. Cause : les premières E/S disque réelles attendaient sous l'horloge asynchrone simulée du binding widget.

Un essai interrompu a donc produit honnêtement :

```text
Phase 6 golden package exports, installs, presents, and starts gameplay - did not complete
Some tests failed.
```

Correction : conserver le parcours d'E/S/session dans un `test` asynchrone réel, utiliser la machine d'état de production pour la transition intro, et exécuter le composant vidéo dans son test widget dédié. Après correction : `+1: All tests passed!`.

## Matrice finale de tests — candidat 28f78b38b

| Package | Commande exacte | Résultat |
|---|---|---|
| Hub, capture propre | `cd apps/pokemap_hub && POKEMAP_PHASE7B_EVIDENCE_OUTPUT=/Users/karim/Project/pokemonProject/build/phase-7b/28f78b38b/golden-flow.json POKEMAP_PHASE7B_PACKAGE_OUTPUT=/Users/karim/Project/pokemonProject/build/phase-7b/28f78b38b/golden-personalization.pokemapgame POKEMAP_PHASE7B_SUPPORT_ROOT=/Users/karim/Project/pokemonProject/build/phase-7b/28f78b38b/support-root flutter test test/ui/player/phase_6_personalization_packaging_e2e_test.dart --reporter expanded` | exit 0, 19 s, `+1: All tests passed!` |
| map_core | `cd packages/map_core && dart test test/project_presentation_profile_test.dart --reporter expanded` | exit 0, 1 s, `+10: All tests passed!` |
| map_editor | `cd packages/map_editor && flutter test test/personalization/phase_5_personalization_golden_gate_test.dart test/personalization/project_presentation_presets_test.dart --reporter expanded` | exit 0, 14 s, `+5: All tests passed!` |
| map_distribution | `cd packages/map_distribution && dart test test/game_package_personalization_preflight_test.dart test/personalization_release_gate_receipt_test.dart --reporter expanded` | exit 0, 6 s, `+12: All tests passed!` |
| map_runtime | `cd packages/map_runtime && flutter test test/runtime_project_typography_loader_test.dart test/player/runtime_title_music_controller_test.dart test/runtime_intro_sequence_controller_test.dart --reporter expanded` | exit 0, 11 s, `+8: All tests passed!` |
| map_player_ui | `cd packages/map_player_ui && flutter test test/player/player_intro_video_surface_test.dart test/pokemap_player_theme_test.dart --reporter expanded` | exit 0, 15 s, `+11: All tests passed!` |
| pokemap_hub | `cd apps/pokemap_hub && flutter test test/ui/player/hub_title_presentation_loader_test.dart test/ui/player/hub_intro_video_player_test.dart test/ui/player/phase_5_personalization_golden_gate_test.dart test/ui/player/phase_6_personalization_packaging_e2e_test.dart --reporter expanded` | exit 0, 20 s, `+13: All tests passed!` |
| Reçu final | `cd packages/map_distribution && POKEMAP_PHASE7B_RELEASE_RECEIPT=/Users/karim/Project/pokemonProject/reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json dart test test/personalization_release_gate_receipt_test.dart --reporter expanded` | exit 0, `+7: All tests passed!` |

La matrice comportementale compte 69 tests ciblés. La capture candidat-bound ajoute une exécution dédiée du parcours golden ; celui-ci est aussi inclus dans les 13 tests Hub et n'est donc pas présenté comme un test unique supplémentaire dans un total dédupliqué.

Les suites complètes de tous les packages n'ont pas été relancées : la Phase 7B cible la chaîne de personnalisation et sa précédente gate 7A ne peut pas être recyclée comme preuve de ce nouveau candidat. Les tests ciblés traversants et les analyses de tous les packages concernés constituent la validation proportionnée de ce lot.

## Analyses statiques

| Package | Commande | Résultat |
|---|---|---|
| map_core | `cd packages/map_core && dart analyze` | exit 0, 6 s, `No issues found!` |
| map_distribution | `cd packages/map_distribution && dart analyze` | exit 0, 3 s, `No issues found!` |
| map_editor | `cd packages/map_editor && flutter analyze` | exit 0, 22 s, `No issues found!` |
| map_runtime | `cd packages/map_runtime && flutter analyze` | exit 0, 18 s, `No issues found!` |
| map_player_ui | `cd packages/map_player_ui && flutter analyze` | exit 0, 17 s, `No issues found!` |
| pokemap_hub | `cd apps/pokemap_hub && flutter analyze` | exit 0, 16 s, `No issues found!` |

## Build et lancement macOS

### Build

```text
cd apps/pokemap_hub
flutter build macos --release
```

Résultat exact :

```text
Building macOS application...
✓ Built build/macos/Build/Products/Release/PokeMap Hub.app (87.1MB)
exit_code=0 duration_seconds=73
```

Inventaire :

- bundle ID : `app.pokemap.hub`
- architectures : `x86_64 arm64`
- exécutable SHA-256 : `8bb8fbf4a4ad6f5bbb522f18ffa3f810f01169c529121dea493dfda7f299dcb4`
- `codesign --verify --deep --strict` : exit `0`
- signature : ad hoc
- hardened runtime : présent
- TeamIdentifier : absent
- `spctl --assess` : exit `3`, rejeté

### Lancement d'une copie installée isolée

Le bundle a été copié avec `ditto` dans `build/phase-7b/28f78b38b/installed-copy/PokeMap Hub.app`, puis l'exécutable du bundle a été lancé directement et surveillé jusqu'à huit secondes.

Résultat exact :

```text
codesign_exit_code=0 gatekeeper_exit_code=3 launch_exit_code=134 alive_after_8_seconds=false
```

Cause exacte de `dyld` :

```text
FlutterMacOS.framework ... not valid for use in process:
mapping process and mapped file (non-platform) have different Team IDs
```

Aucun entitlement de sécurité n'a été affaibli et aucune re-signature n'a été utilisée pour contourner le défaut.

## Identité du paquet capturé

- fixture source SHA-256 : `6210d2858f3ee23993b848cfb701aa3e011c748706e0fd33cb57931431ab3ca2`
- package : 16 786 octets, 9 fichiers
- package SHA-256 : `8be0b8e834d3f4ff06f76b73bc0a66a513f3bc7eff4ca7f9096a67b717761a04`
- tree SHA-256 : `cfe59da5b859802930c7b49899ee9b5cb9867e9a6d850a45413dcd52ba60ebea`
- presentation SHA-256 : `48788a804864359e585b3a8e0ff03322ba5486de43ccb89107bb2f97f3d04da8`
- codecs déclarés : H.264 / AAC
- catégories : branding, intro, typography, theme
- assets hashés : 7
- licence de fonte : présente et certifiée
- signature du package : `notPresent`
- load smoke installé : PASS
- corruption post-install : rejetée

## Verdicts des cinq passes nommées

Les directives d'exécution interdisaient de créer des sub-agents sans demande explicite. Conformément au fallback de `codex_rule.md`, cinq passes locales séparées ont été conduites.

| Passe | Verdict |
|---|---|
| Audit / Architecture | **GO** pour l'architecture : contrat dans distribution, preview dans editor, session dans Hub, aucune règle gameplay déplacée. |
| Implémentation | **GO** : reçu typé, capture liée au candidat, parité et fallback thème explicite ; aucun comportement produit hors scope. |
| Tests | **GO** pour les quatre critères comportementaux : 69 tests ciblés, capture golden et validation du reçu passent. |
| Build / Validation | **NO_GO release** : build macOS vert, mais lancement `134`, Gatekeeper `3`, quatre plateformes non évaluées. |
| Critique finale | **NO_GO maintenu** : les preuves automatisées ne remplacent ni une signature Developer ID cohérente, ni un décodage natif observé, ni une matrice appareils. |

## Décision PH-007

| Condition de la roadmap | État | Preuve |
|---|---|---|
| export→install→intro→titre personnalisé→jeu | PASS automatisé | `golden-flow.json`, intro terminée, titre cinematic, jeu monté/démonté |
| fallbacks vidéo/fonte/audio/thème | PASS automatisé | tests runtime, player UI et Hub, y compris thème invalide explicite |
| preview et runtime résolvent le même profil | PASS automatisé | 5 surfaces + layout + 3 rôles de fonte |
| matrice plateformes/codecs build/lancement | FAIL / NON ÉVALUÉE | macOS build 0 mais launch 134 ; Windows/Linux/iOS/Android non exécutés |
| hashes, licences et preflight | PASS | hashes package/tree/presentation/assets et licence de fonte |

**Décision calculée : `NO_GO`.**

**Statut proposé : `PH-007 = PARTIAL`.**

## Limites conservées

- Le fichier MP4 de fixture certifie le contrat et le packaging ; il ne constitue pas une observation d'un décodage H.264 natif réel.
- Le driver vidéo Flutter est simulé dans les tests widgets.
- Le Hub Release macOS ne peut pas démarrer dans son état de signature local actuel.
- Developer ID, notarisation, ticket staplé et acceptation Gatekeeper sont absents.
- Windows, Linux, iOS et Android n'ont ni build ni lancement frais.
- Aucun walkthrough humain visuel/audio/controller n'a été fourni.
- Le package sideload reste non signé.
- Les artefacts sous `build/phase-7b/` sont ignorés et locaux ; les hashes du reçu en préservent l'identité, pas la disponibilité.
- Tout changement après le SHA candidat invalide le reçu et impose une recapture.
- La roadmap canonique n'est pas mise à jour automatiquement.

## Auto-critique finale

Le reçu empêche les faux GO par critère manquant, preuve plateforme manquante, code de lancement non nul et champs dérivés falsifiés. La séparation entre test d'E/S réel et test widget corrige un problème de méthode, pas un comportement produit.

La principale faiblesse restante est que la preuve intro automatise les couches contrat, résolution, machine d'état et composant Flutter, mais pas le décodage AVFoundation d'un média réel dans une application lancée. Le défaut de signature empêche précisément cette dernière observation. Il serait trompeur de promouvoir `PH-007` tant que ce point n'est pas fermé.

La passe de critique a aussi empêché une surdéclaration : le thème invalide est désormais couvert explicitement. Aucun fichier produit non pertinent, aucune couleur UI ad hoc et aucune dépendance de package nouvelle n'ont été ajoutés.

## Prochaines étapes proposées, non implémentées

1. Configurer une identité Developer ID et signer récursivement l'app et ses frameworks avec le même Team ID.
2. Notariser, stapler, faire accepter le bundle par Gatekeeper, puis refaire cold install et relaunch.
3. Exécuter le même reçu sur les plateformes effectivement revendiquées, ou réduire officiellement la matrice de support.
4. Tester une vraie vidéo H.264/AAC sur appareil avec observation image, audio, skip, captions et reduced motion.
5. Recapturer le package et le reçu sur un nouveau candidat propre.
6. Mettre à jour la roadmap canonique uniquement sur demande explicite.

## État Git final attendu et vérifié après commit documentaire

```text
git status --short --untracked-files=all
<aucune sortie>
```

Les répertoires ignorés `build/phase-7b/` et `docs/superpowers/plans/` ne sont pas affichés par cette commande. Le commit documentaire est le contenant du présent rapport ; le candidat attesté reste volontairement `28f78b38b48bb4207f0689e0e4283cf65db5d94e`.

# Annexes — contenu complet des fichiers créés

Le présent rapport n'inclut pas son propre contenu dans lui-même afin d'éviter une récursion infinie.

## A. `packages/map_distribution/lib/src/personalization_release_gate_receipt.dart`

```dart
enum PersonalizationReleaseCriterion {
  installedGoldenFlow,
  safeFallbacks,
  previewRuntimeParity,
  packagePreflight,
}

enum PersonalizationReleaseEvidenceStatus {
  passed,
  failed,
  notEvaluated,
}

final class PersonalizationReleaseCriterionEvidence {
  const PersonalizationReleaseCriterionEvidence({
    required this.criterion,
    required this.status,
    required this.summary,
    required this.source,
  });

  factory PersonalizationReleaseCriterionEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final criterion = _enumByName(
      PersonalizationReleaseCriterion.values,
      json['criterion'],
      'criterion',
    );
    final status = _enumByName(
      PersonalizationReleaseEvidenceStatus.values,
      json['status'],
      'status',
    );
    final summary = json['summary'];
    final source = json['source'];
    if (summary is! String || source is! String) {
      throw const FormatException(
        'Malformed personalization criterion evidence.',
      );
    }
    return PersonalizationReleaseCriterionEvidence(
      criterion: criterion,
      status: status,
      summary: summary,
      source: source,
    );
  }

  final PersonalizationReleaseCriterion criterion;
  final PersonalizationReleaseEvidenceStatus status;
  final String summary;
  final String source;

  Map<String, Object?> toJson() => <String, Object?>{
        'criterion': criterion.name,
        'status': status.name,
        'summary': summary,
        'source': source,
      };
}

final class PersonalizationPlatformCodecEvidence {
  const PersonalizationPlatformCodecEvidence({
    required this.platform,
    required this.videoCodec,
    required this.audioCodec,
    this.buildExitCode,
    this.launchExitCode,
    required this.source,
  });

  factory PersonalizationPlatformCodecEvidence.fromJson(
    Map<String, dynamic> json,
  ) {
    final platform = json['platform'];
    final videoCodec = json['videoCodec'];
    final audioCodec = json['audioCodec'];
    final buildExitCode = json['buildExitCode'];
    final launchExitCode = json['launchExitCode'];
    final source = json['source'];
    if (platform is! String ||
        videoCodec is! String ||
        audioCodec is! String ||
        (buildExitCode != null && buildExitCode is! int) ||
        (launchExitCode != null && launchExitCode is! int) ||
        source is! String) {
      throw const FormatException(
        'Malformed personalization platform evidence.',
      );
    }
    return PersonalizationPlatformCodecEvidence(
      platform: platform,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
      buildExitCode: buildExitCode as int?,
      launchExitCode: launchExitCode as int?,
      source: source,
    );
  }

  final String platform;
  final String videoCodec;
  final String audioCodec;
  final int? buildExitCode;
  final int? launchExitCode;
  final String source;

  bool get hasCompleteEvidence =>
      buildExitCode != null && launchExitCode != null;

  bool get isSuccessful =>
      buildExitCode == 0 && launchExitCode == 0 && hasCompleteEvidence;

  Map<String, Object?> toJson() => <String, Object?>{
        'platform': platform,
        'videoCodec': videoCodec,
        'audioCodec': audioCodec,
        if (buildExitCode != null) 'buildExitCode': buildExitCode,
        if (launchExitCode != null) 'launchExitCode': launchExitCode,
        'source': source,
      };
}

/// Candidate-bound decision receipt for the PH-007 personalization gate.
///
/// The four behavioral criteria are supplied as linked observations. Platform
/// readiness is derived from build and launch exit codes so a build-only row
/// can never be promoted to GO.
final class PersonalizationReleaseGateReceipt {
  PersonalizationReleaseGateReceipt._({
    required this.releaseCandidateCommit,
    required this.capturedAtUtc,
    required this.contentTreeHashSha256,
    required this.packageSha256,
    required this.presentationSha256,
    required this.criteria,
    required this.platforms,
  });

  static const int currentSchemaVersion = 1;

  factory PersonalizationReleaseGateReceipt.validated({
    required String releaseCandidateCommit,
    required DateTime capturedAtUtc,
    required String contentTreeHashSha256,
    required String packageSha256,
    required String presentationSha256,
    required Iterable<PersonalizationReleaseCriterionEvidence> criteria,
    required Iterable<PersonalizationPlatformCodecEvidence> platforms,
  }) {
    _requireHex('releaseCandidateCommit', releaseCandidateCommit, 40);
    _requireHex('contentTreeHashSha256', contentTreeHashSha256, 64);
    _requireHex('packageSha256', packageSha256, 64);
    _requireHex('presentationSha256', presentationSha256, 64);
    if (!capturedAtUtc.isUtc) {
      throw ArgumentError.value(
        capturedAtUtc,
        'capturedAtUtc',
        'must use UTC',
      );
    }

    final criterionList = criteria.toList(growable: false);
    final counts = <PersonalizationReleaseCriterion, int>{};
    for (final evidence in criterionList) {
      counts[evidence.criterion] = (counts[evidence.criterion] ?? 0) + 1;
      _requireText('criterion.summary', evidence.summary);
      _requireText('criterion.source', evidence.source);
    }
    final cardinalityIssues = <String>[];
    for (final criterion in PersonalizationReleaseCriterion.values) {
      final count = counts[criterion] ?? 0;
      if (count == 0) {
        cardinalityIssues.add('Missing criterion ${criterion.name}.');
      } else if (count > 1) {
        cardinalityIssues.add('Duplicate criterion ${criterion.name}.');
      }
    }
    if (cardinalityIssues.isNotEmpty) {
      throw StateError(cardinalityIssues.join(' '));
    }

    final platformList = platforms.toList(growable: false);
    final normalizedPlatforms = <String>{};
    for (final evidence in platformList) {
      _requireText('platform.platform', evidence.platform);
      _requireText('platform.videoCodec', evidence.videoCodec);
      _requireText('platform.audioCodec', evidence.audioCodec);
      _requireText('platform.source', evidence.source);
      if ((evidence.buildExitCode ?? 0) < 0 ||
          (evidence.launchExitCode ?? 0) < 0) {
        throw ArgumentError.value(
          evidence.toJson(),
          'platforms',
          'exit codes must not be negative',
        );
      }
      final normalized = evidence.platform.trim().toLowerCase();
      if (!normalizedPlatforms.add(normalized)) {
        throw ArgumentError.value(
          evidence.platform,
          'platforms',
          'platform rows must be unique',
        );
      }
    }

    return PersonalizationReleaseGateReceipt._(
      releaseCandidateCommit: releaseCandidateCommit.toLowerCase(),
      capturedAtUtc: capturedAtUtc,
      contentTreeHashSha256: contentTreeHashSha256.toLowerCase(),
      packageSha256: packageSha256.toLowerCase(),
      presentationSha256: presentationSha256.toLowerCase(),
      criteria: List.unmodifiable(criterionList),
      platforms: List.unmodifiable(platformList),
    );
  }

  factory PersonalizationReleaseGateReceipt.fromJson(
    Map<String, dynamic> json,
  ) {
    if (json['schemaVersion'] != currentSchemaVersion) {
      throw FormatException(
        'Unsupported personalization release receipt schema: '
        '${json['schemaVersion']}',
      );
    }
    final releaseCandidateCommit = json['releaseCandidateCommit'];
    final capturedAtUtc = json['capturedAtUtc'];
    final contentTreeHashSha256 = json['contentTreeHashSha256'];
    final packageSha256 = json['packageSha256'];
    final presentationSha256 = json['presentationSha256'];
    final criteria = json['criteria'];
    final platforms = json['platforms'];
    if (releaseCandidateCommit is! String ||
        capturedAtUtc is! String ||
        contentTreeHashSha256 is! String ||
        packageSha256 is! String ||
        presentationSha256 is! String ||
        criteria is! List ||
        platforms is! List) {
      throw const FormatException(
        'Malformed personalization release receipt.',
      );
    }
    final capturedAt = DateTime.tryParse(capturedAtUtc);
    if (capturedAt == null || !capturedAt.isUtc) {
      throw const FormatException(
        'capturedAtUtc must be a UTC ISO-8601 date.',
      );
    }
    try {
      final receipt = PersonalizationReleaseGateReceipt.validated(
        releaseCandidateCommit: releaseCandidateCommit,
        capturedAtUtc: capturedAt,
        contentTreeHashSha256: contentTreeHashSha256,
        packageSha256: packageSha256,
        presentationSha256: presentationSha256,
        criteria: criteria.map((raw) {
          if (raw is! Map) {
            throw const FormatException(
              'Every personalization criterion must be an object.',
            );
          }
          return PersonalizationReleaseCriterionEvidence.fromJson(
            raw.cast<String, dynamic>(),
          );
        }),
        platforms: platforms.map((raw) {
          if (raw is! Map) {
            throw const FormatException(
              'Every personalization platform must be an object.',
            );
          }
          return PersonalizationPlatformCodecEvidence.fromJson(
            raw.cast<String, dynamic>(),
          );
        }),
      );
      final encodedStatus = json['platformMatrixStatus'];
      final encodedDecision = json['decision'];
      if (encodedStatus != receipt.platformMatrixStatus.name ||
          encodedDecision != (receipt.isGo ? 'GO' : 'NO_GO')) {
        throw const FormatException(
          'Derived personalization release fields do not match the evidence.',
        );
      }
      return receipt;
    } on ArgumentError catch (error) {
      throw FormatException(
        'Invalid personalization release receipt: $error',
      );
    } on StateError catch (error) {
      throw FormatException(
        'Invalid personalization release receipt: $error',
      );
    }
  }

  final String releaseCandidateCommit;
  final DateTime capturedAtUtc;
  final String contentTreeHashSha256;
  final String packageSha256;
  final String presentationSha256;
  final List<PersonalizationReleaseCriterionEvidence> criteria;
  final List<PersonalizationPlatformCodecEvidence> platforms;

  int get schemaVersion => currentSchemaVersion;

  PersonalizationReleaseEvidenceStatus get platformMatrixStatus {
    if (platforms.isEmpty ||
        platforms.any((evidence) => !evidence.hasCompleteEvidence)) {
      return PersonalizationReleaseEvidenceStatus.notEvaluated;
    }
    if (platforms.any((evidence) => !evidence.isSuccessful)) {
      return PersonalizationReleaseEvidenceStatus.failed;
    }
    return PersonalizationReleaseEvidenceStatus.passed;
  }

  bool get isGo =>
      criteria.every(
        (evidence) =>
            evidence.status == PersonalizationReleaseEvidenceStatus.passed,
      ) &&
      platformMatrixStatus == PersonalizationReleaseEvidenceStatus.passed;

  List<String> get blockers {
    final result = <String>[
      for (final evidence in criteria)
        if (evidence.status != PersonalizationReleaseEvidenceStatus.passed)
          '${evidence.criterion.name}: ${evidence.status.name} — '
              '${evidence.summary}',
    ];
    if (platforms.isEmpty) {
      result.add('Platform build and launch evidence is missing.');
    }
    for (final evidence in platforms) {
      final platform = evidence.platform.trim();
      if (evidence.buildExitCode == null) {
        result.add('$platform build evidence is missing.');
      } else if (evidence.buildExitCode != 0) {
        result.add(
          '$platform build exit code ${evidence.buildExitCode}.',
        );
      }
      if (evidence.launchExitCode == null) {
        result.add('$platform launch evidence is missing.');
      } else if (evidence.launchExitCode != 0) {
        result.add(
          '$platform launch exit code ${evidence.launchExitCode}.',
        );
      }
    }
    return List.unmodifiable(result);
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': currentSchemaVersion,
        'releaseCandidateCommit': releaseCandidateCommit,
        'capturedAtUtc': capturedAtUtc.toIso8601String(),
        'contentTreeHashSha256': contentTreeHashSha256,
        'packageSha256': packageSha256,
        'presentationSha256': presentationSha256,
        'criteria': criteria.map((evidence) => evidence.toJson()).toList(),
        'platforms': platforms.map((evidence) => evidence.toJson()).toList(),
        'platformMatrixStatus': platformMatrixStatus.name,
        'decision': isGo ? 'GO' : 'NO_GO',
      };
}

T _enumByName<T extends Enum>(
  Iterable<T> values,
  Object? raw,
  String field,
) {
  if (raw is! String) {
    throw FormatException('$field must be a string.');
  }
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('Unsupported $field: $raw.');
}

void _requireHex(String field, String value, int length) {
  if (!RegExp('^[0-9a-fA-F]{$length}' r'$').hasMatch(value)) {
    throw ArgumentError.value(
      value,
      field,
      'must contain exactly $length hexadecimal characters',
    );
  }
}

void _requireText(String field, String value) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
}
```

## B. `packages/map_distribution/test/personalization_release_gate_receipt_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  group('PersonalizationReleaseGateReceipt', () {
    test('round-trips one complete GO receipt', () {
      final receipt = _receipt();

      final decoded = PersonalizationReleaseGateReceipt.fromJson(
        jsonDecode(jsonEncode(receipt.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.toJson(), receipt.toJson());
      expect(decoded.isGo, isTrue);
      expect(decoded.blockers, isEmpty);
      expect(decoded.platformMatrixStatus,
          PersonalizationReleaseEvidenceStatus.passed);
    });

    test('rejects missing and duplicate behavioral criteria', () {
      expect(
        () => _receipt(
          criteria: _passedCriteria().where(
            (item) =>
                item.criterion != PersonalizationReleaseCriterion.safeFallbacks,
          ),
        ),
        throwsStateError,
      );
      expect(
        () => _receipt(
          criteria: <PersonalizationReleaseCriterionEvidence>[
            ..._passedCriteria(),
            _passedCriteria().first,
          ],
        ),
        throwsStateError,
      );
    });

    test('rejects duplicate platform rows', () {
      const macos = PersonalizationPlatformCodecEvidence(
        platform: 'macos',
        videoCodec: 'h264',
        audioCodec: 'aac',
        buildExitCode: 0,
        launchExitCode: 0,
        source: 'build/phase-7b/macos.json',
      );

      expect(
        () => _receipt(platforms: const [macos, macos]),
        throwsArgumentError,
      );
    });

    test('failed or missing platform launch evidence forces NO-GO', () {
      final failed = _receipt(
        platforms: const <PersonalizationPlatformCodecEvidence>[
          PersonalizationPlatformCodecEvidence(
            platform: 'macos',
            videoCodec: 'h264',
            audioCodec: 'aac',
            buildExitCode: 0,
            launchExitCode: 134,
            source: 'build/phase-7b/macos.json',
          ),
        ],
      );
      final missing = _receipt(
        platforms: const <PersonalizationPlatformCodecEvidence>[
          PersonalizationPlatformCodecEvidence(
            platform: 'macos',
            videoCodec: 'h264',
            audioCodec: 'aac',
            buildExitCode: 0,
            source: 'build/phase-7b/macos.json',
          ),
        ],
      );

      expect(failed.isGo, isFalse);
      expect(
        failed.platformMatrixStatus,
        PersonalizationReleaseEvidenceStatus.failed,
      );
      expect(failed.blockers.single, contains('launch exit code 134'));
      expect(missing.isGo, isFalse);
      expect(
        missing.platformMatrixStatus,
        PersonalizationReleaseEvidenceStatus.notEvaluated,
      );
      expect(missing.blockers.single, contains('launch evidence is missing'));
    });

    test('failed behavioral evidence forces NO-GO', () {
      final criteria = _passedCriteria();
      final index = criteria.indexWhere(
        (item) =>
            item.criterion ==
            PersonalizationReleaseCriterion.previewRuntimeParity,
      );
      criteria[index] = const PersonalizationReleaseCriterionEvidence(
        criterion: PersonalizationReleaseCriterion.previewRuntimeParity,
        status: PersonalizationReleaseEvidenceStatus.failed,
        summary: 'Preview differs from the installed title.',
        source: 'build/phase-7b/preview-runtime.log',
      );

      final receipt = _receipt(criteria: criteria);

      expect(receipt.isGo, isFalse);
      expect(receipt.blockers.single, contains('previewRuntimeParity'));
    });

    test('rejects malformed hashes, local dates, and future schemas', () {
      expect(
        () => PersonalizationReleaseGateReceipt.validated(
          releaseCandidateCommit: 'short',
          capturedAtUtc: DateTime.utc(2026, 7, 27),
          contentTreeHashSha256: 'b' * 64,
          packageSha256: 'c' * 64,
          presentationSha256: 'd' * 64,
          criteria: _passedCriteria(),
          platforms: _passingPlatforms,
        ),
        throwsArgumentError,
      );
      expect(
        () => PersonalizationReleaseGateReceipt.validated(
          releaseCandidateCommit: 'a' * 40,
          capturedAtUtc: DateTime(2026, 7, 27),
          contentTreeHashSha256: 'b' * 64,
          packageSha256: 'c' * 64,
          presentationSha256: 'd' * 64,
          criteria: _passedCriteria(),
          platforms: _passingPlatforms,
        ),
        throwsArgumentError,
      );
      expect(
        () => PersonalizationReleaseGateReceipt.fromJson(
          <String, dynamic>{..._receipt().toJson(), 'schemaVersion': 2},
        ),
        throwsFormatException,
      );
    });

    final externalReceipt =
        Platform.environment['POKEMAP_PHASE7B_RELEASE_RECEIPT'];
    if (externalReceipt != null) {
      test('validates the external Phase 7B receipt', () async {
        final decoded = jsonDecode(
          await File(externalReceipt).readAsString(),
        );
        expect(decoded, isA<Map<String, dynamic>>());

        final receipt = PersonalizationReleaseGateReceipt.fromJson(
          decoded as Map<String, dynamic>,
        );

        expect(receipt.releaseCandidateCommit, hasLength(40));
        expect(receipt.packageSha256, hasLength(64));
        expect(receipt.presentationSha256, hasLength(64));
      });
    }
  });
}

PersonalizationReleaseGateReceipt _receipt({
  Iterable<PersonalizationReleaseCriterionEvidence>? criteria,
  Iterable<PersonalizationPlatformCodecEvidence>? platforms,
}) =>
    PersonalizationReleaseGateReceipt.validated(
      releaseCandidateCommit: 'a' * 40,
      capturedAtUtc: DateTime.utc(2026, 7, 27, 12),
      contentTreeHashSha256: 'b' * 64,
      packageSha256: 'c' * 64,
      presentationSha256: 'd' * 64,
      criteria: criteria ?? _passedCriteria(),
      platforms: platforms ?? _passingPlatforms,
    );

List<PersonalizationReleaseCriterionEvidence> _passedCriteria() => [
      for (final criterion in PersonalizationReleaseCriterion.values)
        PersonalizationReleaseCriterionEvidence(
          criterion: criterion,
          status: PersonalizationReleaseEvidenceStatus.passed,
          summary: '${criterion.name} passed.',
          source: 'build/phase-7b/${criterion.name}.log',
        ),
    ];

const _passingPlatforms = <PersonalizationPlatformCodecEvidence>[
  PersonalizationPlatformCodecEvidence(
    platform: 'macos',
    videoCodec: 'h264',
    audioCodec: 'aac',
    buildExitCode: 0,
    launchExitCode: 0,
    source: 'build/phase-7b/macos.json',
  ),
];
```

## C. `reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json`

```json
{
  "schemaVersion": 1,
  "releaseCandidateCommit": "28f78b38b48bb4207f0689e0e4283cf65db5d94e",
  "capturedAtUtc": "2026-07-27T09:37:42Z",
  "contentTreeHashSha256": "cfe59da5b859802930c7b49899ee9b5cb9867e9a6d850a45413dcd52ba60ebea",
  "packageSha256": "8be0b8e834d3f4ff06f76b73bc0a66a513f3bc7eff4ca7f9096a67b717761a04",
  "presentationSha256": "48788a804864359e585b3a8e0ff03322ba5486de43ccb89107bb2f97f3d04da8",
  "criteria": [
    {
      "criterion": "installedGoldenFlow",
      "status": "passed",
      "summary": "The clean candidate exported, inspected, installed, resolved intro and custom title presentation, completed the intro sequence, mounted gameplay, and rejected corrupted installed media.",
      "source": "build/phase-7b/28f78b38b/golden-flow.json"
    },
    {
      "criterion": "safeFallbacks",
      "status": "passed",
      "summary": "Missing or corrupt video, font, title audio, branding, and semantic theme paths retained a non-blocking route to the title or safe defaults.",
      "source": "build/phase-7b/28f78b38b/map-runtime-behavioral.log; build/phase-7b/28f78b38b/map-player-ui-behavioral.log; build/phase-7b/28f78b38b/pokemap-hub-behavioral.log"
    },
    {
      "criterion": "previewRuntimeParity",
      "status": "passed",
      "summary": "The editor preview and exported runtime presentation matched for title layout, all five semantic surfaces, and display, dialogue, and battle-number font roles.",
      "source": "build/phase-7b/28f78b38b/map-editor-behavioral.log"
    },
    {
      "criterion": "packagePreflight",
      "status": "passed",
      "summary": "Package, tree, presentation, and seven asset hashes agreed; H.264/AAC, embedded font redistribution license, and all four configured presentation categories passed preflight.",
      "source": "build/phase-7b/28f78b38b/golden-flow.json; build/phase-7b/28f78b38b/map-distribution-behavioral.log"
    }
  ],
  "platforms": [
    {
      "platform": "macos",
      "videoCodec": "h264",
      "audioCodec": "aac",
      "buildExitCode": 0,
      "launchExitCode": 134,
      "source": "build/phase-7b/28f78b38b/macos-build.log; build/phase-7b/28f78b38b/macos-launch.log"
    },
    {
      "platform": "windows",
      "videoCodec": "h264",
      "audioCodec": "aac",
      "source": "Not evaluated: no Windows build host or approved device was available."
    },
    {
      "platform": "linux",
      "videoCodec": "h264",
      "audioCodec": "aac",
      "source": "Not evaluated: no Linux build host or approved device was available."
    },
    {
      "platform": "ios",
      "videoCodec": "h264",
      "audioCodec": "aac",
      "source": "Not evaluated: no iOS target or approved device was supplied."
    },
    {
      "platform": "android",
      "videoCodec": "h264",
      "audioCodec": "aac",
      "source": "Not evaluated: no Android target or approved device was supplied."
    }
  ],
  "platformMatrixStatus": "notEvaluated",
  "decision": "NO_GO"
}
```

## D. `docs/superpowers/plans/2026-07-27-phase-7b-personalization-release-gate.md`

````markdown
# Phase 7B Personalization Release Gate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a fail-closed `PH-007` receipt that certifies the installed personalization flow and records an honest GO/NO-GO decision from fresh package, fallback, preview/runtime, platform/codec, and preflight evidence.

**Architecture:** `map_distribution` owns the immutable release receipt because it already owns the inspected package and personalization preflight contracts. Existing editor, runtime, player UI, Hub, and host tests remain the behavioral authorities; Phase 7B adds parity assertions and aggregates their fresh command evidence without moving presentation behavior between packages. The candidate is committed before evidence capture, then a second attestation commit records the receipt and Evidence Pack.

**Tech Stack:** Dart 3, Flutter, `package:test`, `flutter_test`, PokeMap package inspection/install APIs, SHA-256 evidence, macOS Flutter release build.

---

### Task 1: Add the fail-closed PH-007 receipt contract

**Files:**
- Create: `packages/map_distribution/lib/src/personalization_release_gate_receipt.dart`
- Modify: `packages/map_distribution/lib/map_distribution.dart`
- Create: `packages/map_distribution/test/personalization_release_gate_receipt_test.dart`

- [ ] **Step 1: Write the failing receipt tests**

Cover these concrete cases:

```dart
test('round-trips a complete GO receipt', () {
  final receipt = PersonalizationReleaseGateReceipt.validated(
    releaseCandidateCommit: 'a' * 40,
    capturedAtUtc: DateTime.utc(2026, 7, 27, 12),
    contentTreeHashSha256: 'b' * 64,
    packageSha256: 'c' * 64,
    presentationSha256: 'd' * 64,
    criteria: _passedCriteria(),
    platforms: const <PersonalizationPlatformCodecEvidence>[
      PersonalizationPlatformCodecEvidence(
        platform: 'macos',
        videoCodec: 'h264',
        audioCodec: 'aac',
        buildExitCode: 0,
        launchExitCode: 0,
        source: 'build/phase-7b/macos.json',
      ),
    ],
  );

  expect(
    PersonalizationReleaseGateReceipt.fromJson(receipt.toJson()).isGo,
    isTrue,
  );
});
```

Also prove that a missing/duplicate criterion is rejected, a duplicate platform
is rejected, and a non-zero or missing launch result forces `NO_GO`.

- [ ] **Step 2: Run the receipt test and verify RED**

Run:

```bash
cd packages/map_distribution
dart test test/personalization_release_gate_receipt_test.dart
```

Expected: compilation failure because
`PersonalizationReleaseGateReceipt` does not exist.

- [ ] **Step 3: Implement the minimal receipt**

The public contract must contain:

```dart
enum PersonalizationReleaseCriterion {
  installedGoldenFlow,
  safeFallbacks,
  previewRuntimeParity,
  packagePreflight,
}

enum PersonalizationReleaseEvidenceStatus {
  passed,
  failed,
  notEvaluated,
}
```

`PersonalizationReleaseGateReceipt.validated` must validate 40/64-character
hashes, UTC time, exactly one observation per criterion, unique non-empty
platform rows, and round-trip JSON. `isGo` must be derived only when every
criterion is `passed` and every selected platform has build and launch exit
code `0`. `blockers` must expose incomplete/failed criteria and platforms.

- [ ] **Step 4: Run focused and package verification**

```bash
cd packages/map_distribution
dart format lib/src/personalization_release_gate_receipt.dart \
  test/personalization_release_gate_receipt_test.dart
dart test test/personalization_release_gate_receipt_test.dart
dart analyze
```

Expected: focused test passes and analysis reports no issues.

### Task 2: Close preview/runtime and installed-flow evidence gaps

**Files:**
- Modify: `packages/map_editor/test/personalization/phase_5_personalization_golden_gate_test.dart`
- Modify: `apps/pokemap_hub/test/ui/player/phase_6_personalization_packaging_e2e_test.dart`

- [ ] **Step 1: Add direct preview/package parity assertions**

From the shared `golden_personalization_slice/presentation.json`, construct
`PersonalizationPreviewProjection` and compare all five surfaces to the
exported manifest:

```dart
final preview = PersonalizationPreviewProjection(presentation);
final packaged = built.manifest.presentation!;

expect(
  preview.surface(PersonalizationPreviewSurface.title).backgroundHex,
  packaged.theme!.titleSurface,
);
expect(
  preview.surface(PersonalizationPreviewSurface.dialogue).backgroundHex,
  packaged.theme!.dialogueSurface,
);
expect(
  preview.surface(PersonalizationPreviewSurface.menu).backgroundHex,
  packaged.theme!.menuSurface,
);
expect(
  preview.surface(PersonalizationPreviewSurface.overworldHud).backgroundHex,
  packaged.theme!.overworldHudSurface,
);
expect(
  preview.surface(PersonalizationPreviewSurface.battleHud).backgroundHex,
  packaged.theme!.battleHudSurface,
);
expect(
  preview.surface(PersonalizationPreviewSurface.title).fontFamily,
  packaged.typography!.display.family,
);
```

- [ ] **Step 2: Exercise the installed intro before gameplay**

Convert the Phase 6 golden flow to `testWidgets`, mount
`HubIntroVideoPlayer` with a deterministic fake playback driver, emit
completion, assert the callback once, then start and stop the installed
in-process game session already exercised by the test.

- [ ] **Step 3: Add optional clean-candidate evidence output**

When all three variables are set:

```text
POKEMAP_PHASE7B_EVIDENCE_OUTPUT
POKEMAP_PHASE7B_PACKAGE_OUTPUT
POKEMAP_PHASE7B_SUPPORT_ROOT
```

require a clean worktree and persist commit, package/preflight/install hashes,
configured categories, resolved profile, intro completion, title
personalization, game mount/unmount, and corruption rejection. Normal test
behavior must remain unchanged when the variables are absent.

- [ ] **Step 4: Run the focused gates**

```bash
cd packages/map_editor
flutter test test/personalization/phase_5_personalization_golden_gate_test.dart

cd ../../apps/pokemap_hub
flutter test test/ui/player/phase_6_personalization_packaging_e2e_test.dart
flutter analyze
```

Expected: both focused gates pass and Hub analysis reports no issues.

### Task 3: Commit the evidence-capable candidate

**Files:**
- All Task 1 and Task 2 files
- `docs/superpowers/plans/2026-07-27-phase-7b-personalization-release-gate.md`

- [ ] **Step 1: Verify scope**

```bash
git diff --check
git status --short --untracked-files=all
```

Expected: only the plan, receipt contract/tests, barrel, and two gate tests.

- [ ] **Step 2: Commit the candidate**

```bash
git add -- <exact Task 1/2 files and this plan>
git commit -m "test(personalization): add phase 7b release gate"
```

Expected: one candidate commit and a clean worktree.

### Task 4: Capture the fresh PH-007 evidence matrix

**Files:**
- Local ignored artifacts only under `build/phase-7b/<candidate>/`

- [ ] **Step 1: Capture the installed package flow**

Run the Hub E2E with the three evidence variables pointing under the candidate
artifact directory. Expected: package/preflight/install/intro/title/game
checks all true and worktree clean.

- [ ] **Step 2: Run the fallback and parity matrix**

```bash
cd packages/map_core
dart test test/project_presentation_profile_test.dart

cd ../map_editor
flutter test test/personalization/phase_5_personalization_golden_gate_test.dart \
  test/personalization/project_presentation_presets_test.dart

cd ../map_distribution
dart test test/game_package_personalization_preflight_test.dart \
  test/personalization_release_gate_receipt_test.dart

cd ../map_runtime
flutter test test/runtime_project_typography_loader_test.dart \
  test/player/runtime_title_music_controller_test.dart

cd ../map_player_ui
flutter test test/player/player_intro_video_surface_test.dart \
  test/pokemap_player_theme_test.dart

cd ../../apps/pokemap_hub
flutter test test/ui/player/hub_title_presentation_loader_test.dart \
  test/ui/player/hub_intro_video_player_test.dart \
  test/ui/player/phase_6_personalization_packaging_e2e_test.dart
```

Expected: all selected tests pass. Preserve exit code, duration, log SHA-256,
and exact result for each command.

- [ ] **Step 3: Run package analyses**

Run `dart analyze` or `flutter analyze` in `map_core`, `map_editor`,
`map_distribution`, `map_runtime`, `map_player_ui`, and `pokemap_hub`.
Expected: every selected package reports no issues.

- [ ] **Step 4: Build and launch the approved platform**

```bash
cd apps/pokemap_hub
flutter build macos --release
```

Inspect bundle identifier, architectures, signature/notarization state and
binary SHA-256. Attempt a temporary installed-copy launch without weakening
library validation. Record success or failure exactly. Non-approved platforms
remain `notEvaluated`.

### Task 5: Produce and commit the PH-007 verdict

**Files:**
- Create: `reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json`
- Create: `reports/gameplay/ph_007_personalization_release_gate.md`

- [ ] **Step 1: Build the structured receipt**

Use `PersonalizationReleaseGateReceipt` schema version 1 and the exact
candidate/package/presentation hashes. Mark each of the four behavioral
criteria from fresh evidence. Derive platform success only from actual build
and launch exit codes; never convert a build-only result into GO.

- [ ] **Step 2: Validate the receipt and report**

Run the receipt contract test, decode the committed JSON through
`PersonalizationReleaseGateReceipt.fromJson`, run `git diff --check`, and
re-run the minimal Phase 7B gate commands affected by documentation.

- [ ] **Step 3: Write the Evidence Pack**

Follow `codex_rule.md`: initial/final Git state, audit, decisions/non-goals,
all modified files and full created-file content, exact commands/results,
named passes, critique, risks, and proposed `PH-007` status.

- [ ] **Step 4: Commit the lot attestation**

```bash
git add -- reports/gameplay/evidence/ph_007_personalization_release_gate_receipt.json \
  reports/gameplay/ph_007_personalization_release_gate.md
git commit -m "docs(personalization): record phase 7b release verdict"
```

Expected: final worktree clean. Report `PH-007 DONE/GO` only if every gate is
green; otherwise report `PH-007 PARTIAL/NO-GO` with exact blockers.
````
