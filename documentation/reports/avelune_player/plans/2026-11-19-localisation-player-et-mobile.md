# Localisation du Player et d’Avelune mobile — plan de mise en œuvre

> Les cases suivent les travaux d’implémentation et leurs preuves. Pour exécuter le plan, utiliser la compétence du dépôt [executing-plans](../../../../skills/executing-plans/SKILL.md) et appliquer les [règles du dépôt](../../../../AGENTS.md).

**Objectif** — Permettre de jouer en français ou en anglais sur iOS et Android avec une préférence propre au Player, une préférence propre à l’application et un héritage jusqu’au téléphone. Les noms Pokémon suivent l’interface en jeu, avec l’anglais comme langue de repli par espèce.

**Architecture** — Les préférences persistées portent les choix explicites et les modes d’héritage. Le Hub calcule les langues d’affichage et transmet au runtime la préférence de contenu. Le Player et les apps natives consomment leurs catalogues de textes. Le jeu fournit ses dialogues et ses fiches d’espèces hors ligne.

**Technologies** — Dart, Flutter, Flame, `flutter gen-l10n` et ARB, SwiftUI et String Catalog, Kotlin et ressources Android, canal Flutter existant.

**État de référence** — HEAD `e97fc3402` (« Checkpoint H10 Story review fixes »). Le relevé initial de `git status --short --untracked-files=all` comptait 131 chemins suivis modifiés et 26 chemins non suivis, dont des travaux Histoire et export. Les lots ci-dessous sont proposés. Leur état reste à établir à partir du checkout qui les exécute.

## 1. Comportement et frontières

### Choix visibles

| Emplacement | Choix proposé par défaut | Choix explicites | Effet |
| --- | --- | --- | --- |
| Player, Options → Langue | Suivre l’application | Français, English | Interface en jeu, y compris le titre, les menus, les messages système et le combat. |
| Avelune iOS et Android, Réglages → Langue | Suivre le téléphone | Français, English | Bibliothèque, détails, installation et réglages natifs. Le choix alimente le Player en mode hérité. |
| Préférences du téléphone | Langues préférées de l’OS | Selon l’OS | Liste ordonnée retenue quand l’application suit le téléphone et que le Player suit l’application. |

Le choix du Player vaut pour les parties de cette installation. Une langue explicite reste sélectionnée même si elle est identique à celle héritée au moment du choix. Les sélecteurs affichent le mode sélectionné et, pour le mode hérité, la langue effective si elle aide à comprendre l’option. Les noms de langue « Français » et « English » sont affichés dans leur langue.

### Règles de résolution

1. Pour l’application, prendre son choix explicite ou la liste ordonnée des langues du système.
2. Pour le Player, prendre son choix explicite ou la liste de préférences de l’application. Conserver la liste d’origine en mode système, y compris les langues disponibles dans le contenu du jeu.
3. Pour chaque interface, prendre le premier candidat pris en charge par son catalogue. Pour chaque candidat, essayer le tag complet puis la langue de base. Normaliser la casse et le séparateur à la frontière. Retomber sur `en` après épuisement des candidats. Une liste système vide mène aussi à `en`.
4. Pour les dialogues, résoudre la préférence du Player contre les langues du manifeste avec les règles de correspondance existantes. En mode système, essayer les candidats système dans l’ordre avant le repli déclaré du jeu. Un choix Player explicite produit un seul candidat. Le repli d’un dialogue incomplet reste celui prévu par les règles H9.
5. Pour chaque espèce affichée, utiliser la locale effective du Player. Essayer le tag exact, la langue de base puis l’entrée `en`. Les blancs sont traités comme absents. Pour une fiche ancienne ou personnalisée sans traduction utilisable ni anglais, conserver son libellé antérieur quand il est disponible, puis un ID humanisé. Le surnom fourni par le joueur garde sa priorité dans les surfaces qui l’utilisent. Le Pokédex masque toujours les espèces inconnues.

| Choix Player | Choix app | Téléphone | App | Player et noms d’espèces | Dialogues |
| --- | --- | --- | --- | --- | --- |
| English | Français | `en-GB` | Français | Anglais | Anglais si disponible, sinon repli du jeu. |
| Suivre l’app | Français | `en-GB` | Français | Français, puis anglais pour une espèce sans nom français | Français si disponible, sinon repli du jeu. |
| Suivre l’app | Suivre le téléphone | `fr-CA`, `en` | Français | Français, avec repli par espèce | Le projet choisit sa correspondance selon son manifeste. |
| Suivre l’app | Suivre le téléphone | `es-MX`, `en` | Anglais | Anglais | Espagnol si le jeu le fournit. |
| Suivre l’app | Suivre le téléphone | `it-IT` et aucune traduction d’interface italienne | Anglais | Anglais | Italien si disponible, sinon repli du jeu. |

Les changements confirmés actualisent les surfaces ouvertes qui héritent du réglage. Un changement de langue en pause actualise les données de présentation mises en cache et conserve la partie courante. Une interaction narrative déjà ouverte garde sa langue jusqu’à sa fin. La suivante emploie le nouveau réglage. Pour les animations de combat, appliquer la nouvelle langue aux prochaines présentations accessibles.

### Données et compatibilité

- **Préférences locales.** Le champ existant `language` continue à stocker `system`, `fr` ou `en` et devient le choix de l’application. Le nouveau champ facultatif `playerLanguage` contient un tag explicite. Son absence signifie « Suivre l’application ». Le lecteur des nouvelles versions accepte les fichiers existants et récupère le mode hérité au chargement. Les valeurs persistées sont les choix, et les locales calculées vivent en mémoire.
- **Projection Player.** `PlayerPreferencesSnapshot.locale` désigne la locale d’interface effective. Le snapshot de lecture porte `playerLanguage` et `preferredContentLocales`. L’écriture porte un delta facultatif `languageChange` séparé du choix affiché. Son absence préserve le choix enregistré dans le chemin Hub migré. Une demande explicite d’héritage retire la surcharge. Le coordinateur publie le snapshot confirmé après résolution.
- **Contenu.** Conserver les formats de projet, de package et de sauvegarde de progression. Le Player lit les `names` des fiches exportées et les traductions de dialogue H9. Les noms de jeux, textes auteurs, dialogues, titres de quêtes, surnoms, IDs, PV, effets de combat et progression suivent leurs contrats existants. Les libellés d’objets et d’attaques déjà localisables utilisent leurs catalogues actuels dans les surfaces touchées.
- **Compatibilité.** Les exports valides depuis Studio `0.3.31+331` restent installables et jouables. Le lecteur de préférences actuel refuse les clés inconnues. Le scénario de migration testé est l’ouverture des préférences existantes par la nouvelle version. Vérifier les lecteurs de packages et des sauvegardes courantes sur des copies de QA. [Politique de compatibilité](../../../architecture/product_and_architecture_policies.md#avelune-project-and-exported-game-compatibility-policy)
- **Périmètre.** La livraison vise le Player embarqué, les écrans natifs iOS et Android, et le compagnon quand il rend une surface Player. Le Hub et le harness Flutter servent aussi de consommateurs de non-régression. Les chaînes du Studio, l’import de traductions en masse, les médias, la diffusion store et de nouvelles langues de catalogue relèvent de travaux distincts.
- **MCP parity: N/A.** Aucune action canonique d’authoring ni format de contenu exporté ne change.

### Sources existantes vérifiées dans le checkout de référence

| Point d’intégration | État de départ |
| --- | --- |
| Préférences | Le mode `system` est aplati en locale concrète par `toRuntimeSnapshot`. `copyWithRuntimeSnapshot` peut enregistrer cette locale comme un choix français ou anglais quand une autre option change. [Modèle](../../../../packages/map_player_ui/lib/src/preferences/player_preferences.dart) · [Gateway](../../../../apps/pokemap_hub/lib/features/session/application/gateways/hub_player_preferences_gateway.dart) |
| Démarrage et session | Le lancement utilise le manifeste pour résoudre `descriptor.locale`. La construction des données de pause reçoit à la fois `locale` et `uiLocale`, mais plusieurs noms d’espèces utilisent encore la première. [Source du jeu](../../../../apps/pokemap_hub/lib/features/session/application/services/hub_runtime_game_source.dart) · [Session spatiale](../../../../packages/map_runtime/lib/src/session/spatial_exploration_game_session_runtime.dart) · [Builder de pause](../../../../packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart) |
| Rendu Flutter | Le catalogue Player existe en français et en anglais. Le `MaterialApp` embarqué doit déclarer le délégué à sa racine. Les overrides déjà présents dans la session et le compagnon doivent recevoir la même locale effective. [Catalogue](../../../../packages/map_player_ui/lib/src/localization/player_localizations.dart) · [App embarquée](../../../../apps/pokemap_hub/lib/embedding/avelune_runtime_app.dart) · [Compagnon](../../../../apps/pokemap_hub/lib/embedding/avelune_gameplay_companion_app.dart) |
| Espèces | `PokemonSpeciesFile.names` est lu par `RuntimePokemonSpeciesLoader`. Le runtime et les données de pause ont des replis différents. [Modèle](../../../../packages/map_core/lib/src/models/pokemon_project_data.dart) · [Résolveur générique](../../../../packages/map_core/lib/src/localization/localized_names.dart) · [Loader](../../../../packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart) |
| Combat | Le planificateur reçoit des résolveurs de noms mais construit des phrases en français. L’overlay du chemin spatial force encore le français pour les attaques. [Planificateur](../../../../packages/map_runtime/lib/src/presentation/flame/battle_turn_animation_planner.dart) · [Montage spatial](../../../../packages/map_runtime/lib/src/spatial/spatial_battle_runtime.dart) |
| Réglages natifs | Les deux lignes « Langue » affichent « Français » en dur. Les deux hôtes utilisent déjà le canal `com.avelune.runtime/library`. [iOS](<../../../../apps/Avelune iOS/AveluneiOS/Presentation/Views/SettingsView.swift>) · [Android](../../../../apps/avelune_android/app/src/main/kotlin/com/yoahnl/avelune/player/presentation/SettingsScreen.kt) · [Canal](../../../../apps/pokemap_hub/lib/embedding/avelune_library_bridge.dart) |

## 2. Ordre de travail et propriété des lots

| Lot | Dépendances | Périmètre principal | Résultat vérifiable |
| --- | --- | --- | --- |
| L10N-00 | Aucune | Référence, jeux de QA et inventaire | Cas reproductibles et versions repérées. |
| L10N-01 | 00 | Choix persistés et résolution | Anciennes préférences lues, hiérarchie testée en Dart. |
| L10N-02 | 01 | Préférences du Player, titre, session, compagnon | Changement de langue à chaud avec transport du choix. |
| L10N-03 | 02 | Catalogue et chaînes des widgets Flutter | Écrans Player en français et en anglais. |
| L10N-04 | 02 | Noms d’espèces et projections hors combat | Même nom dans toutes les surfaces qui lisent l’espèce. |
| L10N-05 | 03, 04 | Textes produits par le runtime hors combat | Confirmations, services et retours système localisés. |
| L10N-06 | 03, 04 | HUD et noms affichés en combat | Choix, cibles et bandeaux cohérents dans les deux chemins. |
| L10N-07 | 06 | Phrases de combat et retours de progression | Messages complets localisés avec les bons noms. |
| L10N-08 | 02 | Contrat de langue entre Flutter et les hôtes natifs | Lecture au démarrage, sélection app et notifications fiables. |
| L10N-09 | 08 | App iOS | Sélecteur SwiftUI et bibliothèque localisés. |
| L10N-10 | 08 | App Android | Sélecteur Compose et bibliothèque localisés. |
| L10N-11 | 05, 07, 09, 10 | Vérification intégrée et compatibilité | Parcours sur les deux apps, avec preuves distinctes. |

Après L10N-02, les travaux sur les noms, le catalogue Flutter et le pont natif ont des points d’intégration distincts. Les lots iOS et Android partagent le contrat de L10N-08. L10N-04 possède les résolveurs de noms et la sélection de locale pour l’espèce. L10N-05 possède le texte des confirmations et les libellés voisins, y compris dans les fichiers de projection partagés. Préserver la séparation au niveau des méthodes et intégrer ensemble les ajouts au catalogue ARB avant analyse.

Avant tout lot de code, relever le statut Git et les `AGENTS.md` proches, puis exécuter les tests ciblés de la frontière concernée. Ajouter les assertions de comportement avant le changement lorsque c’est faisable. Un lot termine sur les tests qui couvrent ses entrées et sorties, l’analyse des packages modifiés et l’examen du diff. Pour les écritures Git, appliquer les autorisations de la tâche d’implémentation. Les validations mobiles longues restent locales. [Règles de vérification et de coût](../../../architecture/product_and_architecture_policies.md)

### L10N-00 — Figer les parcours et la référence

- [ ] Identifier le lancement par jeu installé sur iOS et Android et les chemins spatial et `PlayableMapGame`. Relever les versions exactes des runtimes testés et les surfaces compagnon disponibles.
- [ ] Utiliser la fixture d’export des dialogues pour les tests de données. Préparer pour le parcours natif une copie jetable d’un jeu exporté avec un dialogue français–anglais, un dialogue dont l’anglais manque et une carte avec accès au menu, au Pokédex et au combat. Pour le cas A5, ajouter dans le projet de QA une variante espagnole distinctive et valider sa présence dans l’export. Relever les tags et le repli du manifeste. [Fixture d’export](../../../../packages/map_authoring/test/support/create_dialogue_localization_fixture.dart)
- [ ] Prévoir deux espèces visibles dans l’équipe et le Pokédex. La première possède des noms français et anglais distincts. La seconde possède uniquement un nom anglais utilisable. Prévoir un membre avec un surnom. Pour les tests unitaires, ajouter les variantes `fr-CA` et la traduction blanche dans les données de test.
- [ ] Identifier un export protégé proche du premier Studio compatible et un export récent avec H9. Relever les versions productrices, les chemins de QA, les SHA-256 et les profils d’exécution. Une couverture de compatibilité se mesure sur les exports effectivement présents.
- [ ] Consigner dans le suivi du lot les surfaces observées et celles qui restent à exercer. Reproduire les symptômes menus, noms, combat, ouverture de dialogue et mode système qui se fige. Les copies et captures de travail appartiennent à `/Users/karim/Library/Caches/AveluneQA/localisation-player`.

**Fin du lot** — Le jeu de QA couvre les trois niveaux de choix, les deux replis et un combat accessible. Ce lot produit une référence et laisse le code produit intact. [Politiques de harnais et de QA](../../../architecture/product_and_architecture_policies.md#test-harnesses-and-processes)

### L10N-01 — Persister les choix et résoudre la priorité

Ce lot possède le modèle de préférences et la résolution déterministe. Le transport et le branchement de la session relèvent de L10N-02.

- [ ] Étendre `PlayerPreferences.fromJson`, `toJson`, `copyWith` et l’égalité pour `playerLanguage`. Ajouter `RuntimePlayerLanguageChoice` sous `packages/map_runtime/lib/src/player/runtime_player_language_choice.dart`, exporté par `map_runtime.dart`. Ses constructions `followApplication()` et `explicit(languageTag)` représentent l’héritage et le tag explicite validé. Une signature d’égalité sur le choix et le tag permet de différencier les changements de mode. L’héritage est la valeur par défaut du modèle de préférences.
- [ ] Faire échouer puis passer des assertions sur la lecture du JSON v1 existant, la persistance d’un choix explicite et l’effacement de la surcharge lors du retour au mode hérité. Couvrir un ancien choix app explicite `fr` et une préférence `system`. Une surcharge en anglais doit survivre à une modification de l’app ou du volume.
- [ ] Ajouter `resolvePlayerLocales` dans `packages/map_player_ui/lib/src/preferences/player_locale_resolution.dart`. Il prend les préférences, les tags système ordonnés et les listes de langues d’interface prises en charge. Sa projection expose `appLocale`, `playerLocale` et `preferredContentLocales`. Dans `map_core`, ajouter `ProjectLocalePolicy.resolvePreferred(Iterable<String>)`. Réutiliser la recherche de correspondance de `ProjectLocaleResolver` avant d’appliquer le repli. Conserver les résultats du résolveur historique à candidat unique. Les interfaces privilégient leur tag de base après l’échec du tag exact. Les dialogues conservent la correspondance de langue du projet. [Résolveur partagé](../../../../packages/map_core/lib/src/localization/project_locale_resolver.dart) · [Modèle des préférences](../../../../packages/map_player_ui/lib/src/preferences/player_preferences.dart)
- [ ] Tester la matrice de la section 1 et la priorité entre deux langues système prises en charge. Tester `fr_CA`, un premier tag hors catalogue suivi de `fr`, une liste vide, et un tag inexploitable. Vérifier que la sortie de contenu conserve `es-MX` lorsque son interface tombe sur l’anglais.

Le calcul à vérifier au niveau des préférences est le suivant.

```text
candidatsApp = [choix app] si explicite, sinon liste système
candidatsPlayer = [choix Player] si explicite, sinon candidatsApp
interfaceApp = premier candidat app pris en charge, sinon en
interfacePlayer = premier candidat Player pris en charge, sinon en
préférenceContenu = candidatsPlayer
```

**Fin du lot** — Les sorties de résolution sont déterministes, les préférences existantes se relisent, l’héritage survit aux mutations voisines et les API historiques restent utilisables jusqu’au branchement du lot suivant.

```bash
(cd packages/map_core && dart test test/project_locale_resolver_test.dart test/runtime_dialogue_localization_test.dart && dart analyze)
(cd packages/map_player_ui && flutter test test/player_localizations_test.dart test/player_locale_resolution_test.dart && flutter analyze)
(cd packages/map_runtime && flutter analyze)
(cd apps/pokemap_hub && flutter test test/features/preferences/hub_preferences_store_test.dart)
```

`test/player_locale_resolution_test.dart` est le test à créer dans ce lot.

### L10N-02 — Porter le choix jusqu’au titre, à la session et au compagnon

Ce lot livre une chaîne de préférence active. Il possède le transport et les points de composition. L10N-03 à L10N-07 traitent le contenu de présentation.

- [ ] Dans `PlayerPreferencesSnapshot` et son codec compagnon, porter séparément la locale UI, le choix Player et les candidats de contenu. Dans `updatePreferences`, ajouter `languageChange` seulement à la commande qui modifie la langue. En transport, le choix peut être `{"mode":"followApplication"}` ou `{"mode":"explicit","tag":"en"}`. Garder les nouveaux champs optionnels en lecture du codec. Tester l’absence de delta, les deux deltas et le vieux payload. Couvrir un changement de préférence de contenu qui donne encore la même locale UI. [Snapshot](../../../../packages/map_runtime/lib/src/player/runtime_player_host.dart) · [Codec](../../../../packages/map_runtime/lib/src/player/runtime_companion_presentation_codec.dart)
- [ ] Raccorder `HubPlayerPreferencesGateway` à la résolution de L10N-01. Appliquer le delta de langue du Player si présent et conserver `language` lors des changements en jeu. Fusionner avec les préférences courantes, puis relire et publier la projection confirmée lors d’un changement de langue. Pour une autre option, garder la projection linguistique la plus récente. Comparer la projection confirmée pour décider des invalidations de session. Un échec de sauvegarde conserve l’affichage confirmé. [Coordination](../../../../packages/map_runtime/lib/src/player/runtime_player_coordinator.dart) · [Gateway](../../../../apps/pokemap_hub/lib/features/session/application/gateways/hub_player_preferences_gateway.dart)
- [ ] Dans `runtime_player_options.dart`, envoyer « Suivre l’application » ou le choix explicite et sélectionner en fonction du mode persisté. Pour un ancien hôte à préférence simple, garder le chemin existant jusqu’à sa migration. Tester le réglage du volume en mode hérité, le passage à un choix explicite identique à la langue affichée, et la réactivation de l’héritage. Tester aussi une commande de volume construite avant un choix de langue sur l’autre écran. Elle doit conserver le choix confirmé depuis. [Options Player](../../../../packages/map_player_ui/lib/src/player/runtime_player_options.dart)
- [ ] Alimenter `HubRuntimeStartupBootstrap`, `HubRuntimeGameSource` et `HubInstalledGamePlayer` avec la même projection. Monter les délégués Player dans `AveluneRuntimeApp` et appliquer la locale UI au titre, aux routes et aux overlays. Enregistrer un observateur des locales système au point de composition et reprojeter les préférences héritées au démarrage, à la notification et à la reprise. Les notifications de projection sont des mises à jour en mémoire.
- [ ] Réserver `GameSessionDescriptor.locale` et les appels de `ProjectLocalePolicy` au contenu. Appliquer les candidats de contenu au démarrage, à la nouvelle partie et à la prochaine interaction, y compris dans les chemins spatial et `PlayableMapGame`. Actualiser les détails de pause déjà prévus par le coordinateur quand l’UI change. Tester le dialogue d’intro, un dialogue en partie, et un changement à chaud sans rejouer l’intro ni relancer la session. [Bootstrap](../../../../apps/pokemap_hub/lib/features/session/application/services/hub_runtime_startup_bootstrap.dart) · [Nouvelle partie](../../../../packages/map_runtime/lib/src/player/runtime_new_game_flow.dart)

**Fin du lot** — Titre et options suivent la bonne langue. Les changements confirmés par l’écran principal ou le compagnon produisent une même projection. Une interaction suivante utilise la bonne langue de dialogue, avec repli contrôlé par le jeu. Les tests prouvent la conservation du mode hérité après un changement du volume.

```bash
(cd apps/pokemap_hub && flutter test test/features/session/hub_player_preferences_gateway_test.dart test/features/session/hub_runtime_game_source_test.dart test/embedding/avelune_gameplay_companion_test.dart && flutter analyze)
(cd packages/map_runtime && flutter test test/player/runtime_startup_coordinator_test.dart test/player/runtime_companion_presentation_codec_test.dart test/player/localized_pre_session_dialogue_test.dart test/session/localized_spatial_dialogue_test.dart && flutter analyze)
(cd packages/map_player_ui && flutter test test/player_localizations_test.dart && flutter analyze)
```

### L10N-03 — Catalogue Flutter et chaînes des écrans Player

Le lot possède les textes écrits dans les widgets et les façades de chaînes existantes. Les phrases composées dans le runtime suivent dans L10N-05 et L10N-07.

- [ ] Inventorier les chaînes de titre, nouvelle partie, pause, options, sauvegarde, équipe, sac, Pokédex, fiche, PC, carte, commandes, overlays et accessibilité. Repérer les libellés inclus dans `player_*_strings.dart` et les branches locales `fr/en` dans les widgets. Exercer un état vide, une confirmation et un écran secondaire pour chaque parcours visible.
- [ ] Créer `packages/map_player_ui/l10n.yaml` et les fichiers `packages/map_player_ui/lib/l10n/player_en.arb` et `packages/map_player_ui/lib/l10n/player_fr.arb`. Activer `flutter.generate` dans le `pubspec.yaml` de ce package avec les dépendances de génération nécessaires. Suivre la convention de sortie du Studio. Regrouper les traductions FR et EN de `PokeMapPlayerLocalizations` et garder ses points d’accès, dont `context.playerL10n`. Utiliser des paramètres nommés et les pluriels ICU pour les textes variables. [Génération au Studio](../../../../apps/avelune_studio/l10n.yaml) · [Façade Player](../../../../packages/map_player_ui/lib/src/localization/player_localizations.dart)
- [ ] Migrer les widgets et les façades d’écran vers les clés générées. Couvrir les tooltips, la sémantique et les libellés d’actions, dont « Suivre l’application ». Conserver les thèmes et les widgets déjà employés. Les titres, labels et choix injectés par le jeu restent du contenu auteur.
- [ ] Dans les tests de widgets, vérifier les libellés français et anglais d’une même surface, le retour au mode hérité, une langue non prise en charge, les pluriels 0, 1 et 2 et la présence des paramètres. Exercer un écran étroit avec le texte agrandi. Les générateurs ne produisent qu’un diff dans le package concerné.

**Fin du lot** — Les écrans Flutter vérifiés lisent le même catalogue. Le repli de l’interface est l’anglais. Les chaînes ajoutées ont des entrées dans les deux ARB et s’affichent sur les surfaces réelles utilisées par les tests.

```bash
(cd packages/map_player_ui && flutter gen-l10n && flutter test test/player_localizations_test.dart test/player/runtime_prompt_localization_test.dart test/player/player_pokemon_summary_parity_test.dart test/player/player_save_dialog_layout_test.dart && flutter analyze)
```

### L10N-04 — Résoudre les noms d’espèces hors combat

Ce lot possède la fonction de nommage, les sources des noms et les projections de l’équipe, du Pokédex, du sac, du PC, des cadeaux, des échanges et des services. Les appels du combat sont branchés dans L10N-06.

- [ ] Ajouter `resolvePokemonSpeciesName` près de `resolveLocalizedName` dans `map_core`, en réutilisant le résolveur générique. Normaliser les clés de locale à la lecture des fiches et conserver leurs chaînes éditées. Le repli transmis par l’appelant sert aux fiches anciennes et aux espèces personnalisées.
- [ ] Unifier `RuntimePokemonSpecies.displayName`, `_RuntimeSpeciesPresentation.nameFor` et `_localizedSpeciesName` du contrôleur de services. Réutiliser les caches existants de fiches et de données de présentation. Indexer les données brutes par ID et résoudre la locale quand un libellé est projeté. Garder la résolution mécanique des formes, des médias et des identifiants sur leurs chemins actuels. [Noms runtime](../../../../packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart) · [Projections de pause](../../../../packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart) · [Services](../../../../packages/map_runtime/lib/src/application/player_service_runtime_controller.dart) · [Échanges](../../../../packages/map_runtime/lib/src/application/runtime_party_trade_service.dart)
- [ ] Utiliser la locale UI de L10N-02 pour tous les noms générés. Adapter les constructeurs de summaries, de sélection de cible et de retours de services qui reçoivent encore la locale du manifeste. Conserver l’ordre surnom, nom d’espèce et repli selon les surfaces existantes. Au Pokédex, le format `???` reste réservé aux espèces inconnues.
- [ ] Tester `fr-CA` avec une entrée exacte, le retour à `fr`, un nom français blanc qui tombe sur `en`, `en` absent pour une fiche locale et une ancienne fiche sans `names`. Dans le test de pause, utiliser `locale: 'fr'` pour le contenu et `uiLocale: 'en'`. La même espèce doit prendre son nom anglais dans l’équipe et le Pokédex. Passer ensuite à `fr` dans la même session et vérifier les nouveaux libellés et le surnom. Vérifier avec les métriques existantes du chargeur qu’un changement de locale seul réutilise le catalogue chargé.

```dart
String resolvePokemonSpeciesName({
  required Map<String, String> names,
  required String locale,
  required String fallback,
}) {
  final english = resolveLocalizedName(
    names: names,
    locale: 'en',
    fallback: fallback,
  );
  return resolveLocalizedName(names: names, locale: locale, fallback: english);
}
```

**Fin du lot** — Sans réexport ni nouveau chargement global du catalogue, un changement de langue actualise les noms de toutes les surfaces hors combat. Les versions antérieures des fiches conservent un nom lisible.

```bash
(cd packages/map_core && dart test test/localized_names_test.dart && dart analyze)
(cd packages/map_runtime && flutter test test/player/runtime_player_pause_data_builder_test.dart test/runtime_pokemon_summary_test.dart test/player_service_runtime_controller_test.dart test/player/runtime_party_trade_service_test.dart && flutter analyze)
(cd packages/map_player_ui && flutter test test/player/player_pokemon_summary_parity_test.dart)
```

### L10N-05 — Retours système du runtime hors combat

Le lot possède les libellés composés dans les projections et le feedback de l’exploration. Les fiches d’espèce et les messages de combat ont leurs propres lots.

- [ ] Relever dans le coordinateur, les données de pause et les services les messages affichés au joueur. Prioriser titre, échec de reprise, sauvegarde, sac, navigation, cadeaux, soin, échange, achat, évolution hors combat et indications d’interaction. Distinguer les textes d’origine auteur et les retours système à partir de leur provenance.
- [ ] Réutiliser les codes et clés produit de `runtime_prompt_localization.dart` et les projections déjà typées. Transmettre aux présentations les arguments stables, comme un compteur, un nom résolu, une raison de refus ou un identifiant. Pour les surfaces qui requièrent du texte déjà formaté, injecter la traduction à la composition via le contrat de présentation du runtime. Les libellés de secours des anciens hôtes restent lisibles. [Registre des invites](../../../../packages/map_player_ui/lib/src/player/runtime_prompt_localization.dart) · [Projections et messages](../../../../packages/map_runtime/lib/src/player/runtime_player_coordinator.dart)
- [ ] Ajouter les clés et paramètres aux ARB de L10N-03. Garder les phrases entières pour la grammaire des langues et les formats de quantité. Les projections du compagnon conservent le code et les arguments ou le texte confirmé selon leur contrat existant.
- [ ] Exercer l’échec de sauvegarde avec raison, un retour de soin ou de cadeau, une action indisponible et un dialogue auteur. Vérifier rendu FR et EN, paramètres présents et dialogue auteur inchangé. Pour un code de secours inconnu, vérifier le texte de secours prévu par le contrat.

**Fin du lot** — L’utilisateur retrouve sa langue sur les actions système hors combat, y compris en cas d’échec. Les textes d’un jeu restent interprétés par leur contrat de contenu.

```bash
(cd packages/map_player_ui && flutter gen-l10n && flutter test test/player/runtime_prompt_localization_test.dart test/player/player_save_recovery_surface_test.dart && flutter analyze)
(cd packages/map_runtime && flutter test test/player_service_runtime_controller_test.dart test/player/runtime_startup_coordinator_test.dart test/player/runtime_companion_presentation_codec_test.dart && flutter analyze)
```

### L10N-06 — HUD, commandes et noms en combat

Le lot possède la préparation des libellés du HUD. Le rythme des animations et les messages narratifs du combat sont traités dans L10N-07.

- [ ] Recenser les deux routes de construction du HUD et leurs surfaces Flutter, Flame et compagnon. Brancher les menus de commandes, sélecteurs d’attaque, cibles, indicateurs, bandeaux et choix de Pokémon sur le contexte de langue UI.
- [ ] Alimenter `resolveSpeciesDisplayName` et `resolveMoveDisplayName` avec la locale UI dans le runtime spatial et dans `PlayableMapGame`. Réutiliser les chargeurs de graines, d’espèces et d’attaques déjà injectés dans le combat. Préserver le surnom sur les combattants qui l’utilisent. Les commandes et la sélection conservent les IDs stables.
- [ ] Supprimer l’appel de présentation `displayName('fr')` dans le chemin spatial au profit de la locale UI. Acheminer les nouvelles valeurs à l’overlay mobile et au compagnon par les snapshots de présentation déjà employés. Éviter de recharger le catalogue pour chaque rafraîchissement du HUD. [Runtime spatial](../../../../packages/map_runtime/lib/src/spatial/spatial_battle_runtime.dart) · [Runtime Flame](../../../../packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart) · [Menu de combat](../../../../packages/map_runtime/lib/src/presentation/flame/battle_command_menu_model.dart) · [Surface Player](../../../../packages/map_player_ui/lib/src/player/player_battle_surface.dart)
- [ ] Tester entrée FR et EN, nom anglais de secours sur une cible avec UI française, surnom côté joueur, commandes autorisées et sélection des cibles en double. Exercer une ouverture de combat après le changement de langue et vérifier qu’une même commande vise le même slot dans les deux langues.

**Fin du lot** — Le HUD, les choix et le compagnon présentent les mêmes noms et la bonne langue. La trace de sélection et les IDs de combat sont identiques pour les deux langues à données constantes.

```bash
(cd packages/map_runtime && flutter test test/battle_command_menu_model_localization_test.dart test/runtime_doubles_overlay_test.dart test/phase_a_golden_battle_slice_smoke_test.dart && flutter analyze)
(cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart)
```

### L10N-07 — Phrases de combat et progression affichée

Le lot possède les phrases produites par la présentation du combat, leur formatage et les retours génériques de fin de combat.

- [ ] Inventorier dans les surfaces de présentation l’entrée en combat, l’utilisation et l’échec d’une attaque, les dégâts et soins, changements de statut et de statistiques, les remplacements, la fuite, la capture et les récompenses. Inclure les panneaux d’expérience, de niveau, d’apprentissage et d’évolution pris en charge. [Planificateur](../../../../packages/map_runtime/lib/src/presentation/flame/battle_turn_animation_planner.dart) · [Overlay](../../../../packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart) · [Progression](../../../../packages/map_runtime/lib/src/presentation/flame/post_battle_progression_overlay_component.dart)
- [ ] Conserver les événements de `map_battle` comme entrées. Au moment de construire une présentation, produire un identifiant de message avec ses paramètres. Le formateur de présentation injecté rend la phrase complète via les ARB, avec les noms de L10N-06. Prévoir la branche de compatibilité pour un hôte qui utilise encore le formateur par défaut. `map_runtime` expose un contrat limité à la présentation, et l’adaptateur qui utilise les ARB appartient à `map_player_ui`.
- [ ] Pour un événement d’utilisation d’attaque, tester un message `battleMoveUsed(actor, move)` qui rend « Pousse utilise Charge ! » en français et « Sproutle used Tackle! » en anglais. Pour une capture, tester l’espèce et les quantités dans la phrase. Les projecteurs d’animations partagent des arguments stables et le flot d’événements reste la référence pour le timing.
- [ ] Comparer la séquence d’événements, les cibles, les durées sémantiques, les changements de caméra et les résultats pour le même tour déterministe dans les deux langues. Inclure un tour échoué, un soin et un remplacement. Vérifier la lisibilité sur un format mobile étroit et le message qui suit le changement de langue.

**Fin du lot** — Le français et l’anglais couvrent les familles inventoriées et les phrases injectent les noms localisés. Les tests de présentation prouvent que le passage d’une langue à l’autre conserve la séquence du combat.

```bash
(cd packages/map_player_ui && flutter gen-l10n && flutter analyze)
(cd packages/map_runtime && flutter test test/battle_turn_animation_planner_test.dart test/battle_switch_presentation_test.dart test/battle_stat_stage_presentation_test.dart test/full_restore_presentation_test.dart test/phase_a_golden_battle_slice_smoke_test.dart && flutter analyze)
(cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart)
```

### L10N-08 — Contrat de langue avec les hôtes natifs

Le lot possède la lecture et la modification de la préférence app sur le pont existant, ainsi que sa propagation au point de composition. Les vues iOS et Android appartiennent aux lots suivants.

- [ ] Dans `AveluneLibraryBridge`, prévoir une lecture `getLanguagePreferences`, une écriture `setAppLanguage` et un événement `languagePreferencesChanged`. Réutiliser l’initialisation du bridge et le dépôt de préférences du Player. Partager une instance pour ce chemin embarqué afin de sérialiser les écritures partielles entre le bridge et les options en jeu.
- [ ] Exposer à l’hôte seulement l’état dont il a besoin. `appLanguage` vaut `system`, `fr` ou `en`. `appLocale` est la locale effective native. `supportedAppLanguages` contient les tags proposés. `setAppLanguage` accepte un objet avec le champ `appLanguage`, valide la valeur et retourne l’état confirmé. `getLanguagePreferences` et l’événement utilisent la même réponse. [Pont d’embedding](../../../../apps/pokemap_hub/lib/embedding/avelune_library_bridge.dart) · [Dépôt d’écriture](../../../../apps/pokemap_hub/lib/features/preferences/data/repositories/hub_preferences_repository_impl.dart)
- [ ] À la modification app ou système, recalculer les langues au point de composition et publier seulement l’état confirmé. La session en cours reçoit la projection existante de L10N-02, avec le Player explicite ou en héritage. À la reprise, le natif peut relire l’état. Une modification des options en jeu préserve la valeur app. Un échec de persistance laisse l’ancien état visible et renvoie l’erreur à la surface initiatrice.
- [ ] Tester lecture après `runtimeReady`, valeur invalide, aller-retour `system → en → system`, reprise, et concurrence entre un choix app et une sauvegarde des options Player. Couvrir la mise à jour d’une app héritée lorsque le système change et le fait qu’un Player explicite garde son résultat. Chaque écriture valide se confirme après sauvegarde.

```json
{
  "appLanguage": "system",
  "appLocale": "fr",
  "supportedAppLanguages": ["fr", "en"]
}
```

**Fin du lot** — Les deux hôtes peuvent coder leurs écrans à partir du même contrat. Les tests du canal et du dépôt démontrent le passage en mémoire jusqu’au Player ainsi que la persistance des choix distincts.

```bash
(cd apps/pokemap_hub && flutter test test/embedding/avelune_library_bridge_test.dart test/embedding/avelune_gameplay_companion_bootstrap_test.dart test/features/preferences/hub_preferences_store_test.dart test/features/session/hub_player_preferences_gateway_test.dart && flutter analyze)
```

### L10N-09 — Réglages et interface native iOS

Fichiers propriétaires sous `apps/Avelune iOS/AveluneiOS`. Le lot utilise exactement le contrat L10N-08.

- [ ] Adapter `Data/DataSources/FlutterGameDataSource.swift` et `Infrastructure/AppComposition.swift` pour lire l’état de langue quand le bridge est prêt, traiter les événements et rafraîchir l’état à la reprise. Appliquer `appLocale` au niveau racine dans `AveluneApp.swift` à travers l’environnement SwiftUI. Couvrir les chaînes calculées avec des ressources localisées explicites.
- [ ] Rendre la ligne de `Presentation/Views/SettingsView.swift` interactive. Proposer le mode téléphone et les choix de langue retournés par le bridge. Afficher le choix confirmé, garder le focus accessible et signaler l’échec d’enregistrement sur la surface d’origine.
- [ ] Ajouter `Resources/Localizable.xcstrings` et le raccorder au target natif à partir de `project.yml` selon sa déclaration de ressources. Localiser bibliothèque, détails, installation, réglages, états vides et erreurs natives. Formater langues, dates et nombres avec `appLocale`. Garder l’identification du jeu et les informations tirées du manifeste.
- [ ] Couvrir le décodage du payload, le changement confirmé et les deux modes dans `apps/Avelune iOS/AveluneiOSTests/LanguagePreferencesTests.swift`, nouveau test prévu. Sur un simulateur isolé, faire passer la bibliothèque et les réglages de FR à EN puis en mode téléphone, et revenir d’une partie en vérifiant la langue native.

**Fin du lot** — L’app iOS s’ouvre dans sa locale confirmée, met à jour les écrans visibles et transmet son choix à un Player qui hérite. Le parcours du lot est vérifié dans un build qui embarque le runtime de la révision testée.

```bash
bash "apps/Avelune iOS/tool/build_simulator.sh"
```

Le script installe sur `booted`. L’utiliser quand le seul simulateur démarré est celui de la QA. Relever l’UDID avec `xcrun simctl list devices booted` et renseigner `AVELUNE_L10N_IOS_UDID` dans le shell de test. Après préparation du moteur, exécuter les tests natifs sur cet UDID.

```bash
xcodebuild -project "apps/Avelune iOS/AveluneiOS.xcodeproj" -scheme AveluneiOS -configuration Debug -destination "platform=iOS Simulator,id=$AVELUNE_L10N_IOS_UDID" -only-testing:AveluneiOSTests/LanguagePreferencesTests test
```

### L10N-10 — Réglages et interface native Android

Fichiers propriétaires sous `apps/avelune_android/app`. La résolution Dart et le contrat de transport restent ceux de L10N-08.

- [ ] Dans `RuntimeSession.kt`, exposer la lecture, l’écriture et les notifications du bridge. Raccorder l’état de langue à `MainActivity.kt` et à son état Compose. Consommer `appLocale` via les ressources du contexte de présentation. La mise à jour recomposera les écrans de l’app en conservant la session Flutter et l’état de navigation.
- [ ] Transformer la ligne de `SettingsScreen.kt` en sélecteur de la préférence app, avec sélection et état confirmé. Préserver la commande tactile, manette et clavier et le focus au retour dans la page.
- [ ] Utiliser `app/src/main/res/values/strings.xml` pour les textes de secours anglais et `app/src/main/res/values-fr/strings.xml` pour le français. Migrer bibliothèque, détails, installation, réglages, états vides et erreurs natives, ainsi que les dates et noms de langues formatés en français en dur.
- [ ] Couvrir le décodage, le passage de FR à EN et le retour au mode téléphone dans `app/src/test/kotlin/com/yoahnl/avelune/player/runtime/LanguagePreferencesTest.kt`, nouveau test prévu. Dans un émulateur ou appareil de QA, vérifier reprise, navigation et langue sur l’écran compagnon si le profil le rend actif.

**Fin du lot** — Tests natifs et build avec l’AAR de la révision exécutés. L’écran natif utilise la locale app et la partie utilise la locale Player sur la configuration testée.

```bash
bash apps/avelune_android/tool/build_runtime.sh debug
bash apps/avelune_android/tool/build_android.sh :host_core:test :app:testDebugUnitTest :app:assembleDebug
adb devices -l
```

Relever le numéro de série du dispositif de QA et l’APK produit par Gradle. Installer la version testée avec `adb -s "$AVELUNE_L10N_ANDROID_SERIAL" install -r "$AVELUNE_L10N_ANDROID_APK"`. Les scripts du dépôt sélectionnent le SDK et le mode du runtime.

### L10N-11 — Vérification intégrée, compatibilité et clôture

- [ ] Sur les deux builds natifs, installer la copie de QA par le chemin d’import de l’application. Vérifier la provenance du package, la version de l’app, celle du runtime embarqué et les locales du manifeste. Exercer le parcours ci-dessous dans les profils concernés.
- [ ] Rejouer avec un export protégé repéré en L10N-00. Vérifier import, ouverture, sauvegarde au format courant et reprise. Comparer le contenu de progression attendu après des changements de langue. Sur une copie volontairement invalide, vérifier le refus et l’intégrité des octets originaux.
- [ ] Vérifier les commandes de navigation, les libellés d’accessibilité, les états d’erreur et les débordements en français et en anglais avec la taille normale et agrandie. Exercer portrait et paysage selon les profils de l’app, et l’écran compagnon disponible sur le matériel de test.
- [ ] Reporter séparément tests Dart/Flutter, analyse, build natif, parcours en simulateur ou émulateur et parcours sur appareil physique. Noter les commandes réellement exécutées, le résultat, la révision et les fixtures. Arrêter les processus possédés et retirer les artefacts jetables du lot après conservation des preuves utiles.

**Fin du lot** — Les tests ciblés, les deux builds et les parcours applicatifs convenus sont prouvés. Une plateforme ou un profil indisponible reste identifié avec le blocage et la preuve manquante. Les résultats sur les appareils physiques ont leur propre état.

## 3. Parcours d’acceptation

| Cas | Manipulation | Résultat attendu |
| --- | --- | --- |
| A1 | Téléphone en anglais, app en français, Player sur English. Lancer le jeu depuis la bibliothèque. | Bibliothèque française. Titre, équipe, Pokédex et combat en anglais. Les Pokémon prennent leurs noms anglais, avec le surnom à la place prévue. |
| A2 | En pause, sélectionner « Suivre l’application ». Rouvrir l’équipe et le Pokédex puis lancer un combat. | Player français. L’espèce bilingue prend son nom français et l’espèce sans traduction française garde le nom anglais. Même partie et mêmes identifiants. |
| A3 | App et Player héritent. Revenir du réglage système après un changement de langue du téléphone. | Bibliothèque et Player adoptent le nouveau résultat de l’OS. En mode explicite, la locale choisie continue de s’appliquer au niveau concerné. |
| A4 | Avec UI anglaise, ouvrir un dialogue qui possède une traduction anglaise, puis un dialogue uniquement français. | La traduction anglaise apparaît pour le premier. Le second utilise le repli déclaré, qui est le français dans la fixture. |
| A5 | Tester une langue système prise en charge par le jeu et absente du catalogue UI. | L’interface utilise son candidat supporté ou l’anglais. Le jeu retrouve son dialogue dans la langue disponible. |
| A6 | Avec le Player en héritage, changer le volume, fermer puis rouvrir l’app. Vérifier ensuite un choix Player explicite et le retour à l’héritage. | Les deux modes enregistrés se relisent correctement. Le volume est conservé et les changements app ou système continuent à se propager quand le Player hérite. |
| A7 | Sur un compagnon pris en charge, changer la langue depuis les options, puis rouvrir une même surface sur les deux écrans. | Le même choix est confirmé et le texte de la surface Player y est cohérent. |
| A8 | Charger un export de la période de compatibilité, sauvegarder et reprendre après changement de langue. | Installation et reprise réussissent. Le changement de texte ne modifie ni l’état de jeu ni les IDs. |

Pour le passage A5, une fixture Dart avec manifeste espagnol est suffisante pour la logique de résolution. Pour la recette native, utiliser un export espagnol de QA ou relever cette variante comme vérifiée au niveau Dart et laisser son état natif explicite.

En cas d’échec, isoler d’abord le niveau en cause. Un mode perdu renvoie à L10N-01 ou L10N-02. Une bibliothèque divergente renvoie à L10N-08 ou à son hôte. Une phrase dans la mauvaise langue renvoie à la projection correspondante. Pour un nom d’espèce, relever le tag UI et les clés `names` effectivement disponibles dans la fiche. Pour un dialogue, relever les candidats de contenu et les locales du manifeste.

## 4. Vérification de ce document

Les commandes Flutter, Dart et natives ci-dessus décrivent les validations à exécuter pendant l’implémentation. Pour ce livrable documentaire, le contrôle des références a vérifié les chemins des sources et des tests existants, les douze entrées de la table des lots et leurs dépendances. Le fichier de test du résolveur Player est indiqué comme création de L10N-01.

- `git diff --check -- .gitignore` a renvoyé le code 0. L’allowlist vise ce seul fichier dans le nouveau dossier de plans.
- `POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh` a renvoyé le code 1 sur deux README générés présents depuis septembre dans `apps/avelune_android/flutter_runtime/.ios/`. Le même contrôle, limité en excluant précisément ces deux fichiers ignorés du relevé, a renvoyé le code 0 avec « Markdown hygiene: 1 new Markdown file(s), all in canonical locations. ».
- Le relevé Git du livrable indique `.gitignore` modifié et ce plan non suivi, sur HEAD `e97fc3402`. Le pointage global est passé de 131 à 132 chemins suivis modifiés et de 26 à 27 non suivis. L’index ne contient aucun ajout du livrable.

Le premier lot d’implémentation est L10N-00, suivi de L10N-01.
