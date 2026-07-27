# PST-063 — Certification desktop du Personalization Studio

- Date : 2026-07-27
- Plateforme : macOS, build Flutter debug
- Lot : `PST-063`
- Verdict : **PASS avec limites de harnais documentées**
- Gate concernée : Studio fonctionnel, persistant, accessible et couvert E2E

## 1. Audit initial

Le Studio disposait déjà de tests widgets et de parcours automatisés, mais le lot
ne possédait pas de preuve desktop reproductible couvrant l'ouverture réelle du
workspace, les formats d'introduction paysage et portrait et le contrôle visuel
du thème.

État Git au début du lot :

```text
HEAD 00b94727d test(personalization): certify negative publish gates
git status --short --untracked-files=all
<aucune sortie>
```

Le projet QA utilisé est une copie jetable de
`examples/playable_runtime_host/golden_fangame_slice` enrichie avec la
présentation de `examples/playable_runtime_host/golden_personalization_slice`.
Il est placé dans le conteneur macOS de l'application afin que le sandbox du
runner puisse le lire.

Empreintes des deux variantes de `project.json` :

```text
paysage : 82c864bbdd08034b8518f122f68e102dd75a0e3d7219b29917699b2e6163ac45
portrait: 08750981e8a54db5dcce89178ddd64f77eec3285ace70f37282d8b46b8f95425
```

## 2. Changement de testabilité

Le point d'entrée strictement debug `dev/marionette_main.dart` expose maintenant
`pokemap.openPersonalizationStudio`. L'extension appelle le véritable
`EditorNotifier.selectPersonalizationStudioWorkspace()` et renvoie le workspace,
le chemin et le nom du projet observés. Le point d'entrée de production n'est
pas modifié.

Un test unitaire construit un vrai `ProviderContainer`, initialise un projet,
appelle le helper de l'extension et vérifie :

```text
opened = true
workspaceMode = personalizationStudio
projectRootPath = /qa/personalization
projectName = Personalization QA
```

Zones modifiées :

- `packages/map_editor/dev/marionette_main.dart` : helper déterministe et
  enregistrement de l'extension Marionette ;
- `packages/map_editor/test/dev/marionette_main_test.dart` : test de
  caractérisation de l'ouverture du Studio.

Diff fonctionnel : 55 insertions, aucune suppression.

## 3. Parcours desktop observé

Le build macOS a été lancé avec :

```text
flutter run -t dev/marionette_main.dart -d macos --debug \
  --dart-define=MARIONETTE_PROJECT_PATH=/Users/karim/Library/Containers/com.example.mapEditor/Data/Documents/pokemap-pst063-20260727
```

Contrôles réalisés avec Marionette :

| Contrôle | Résultat |
|---|---|
| Connexion au VM Service | PASS |
| `pokemap.activeProjectPath` | `matches: true` |
| Ouverture réelle du Studio | `opened: true`, workspace `personalizationStudio` |
| Branding | catégorie accessible, état `Configuré` |
| Intro paysage | `1280 × 720`, badge `Paysage 16:9` |
| Intro portrait | `720 × 1280`, badge `Portrait 9:16` |
| Typographie | police `Aube Display` visible |
| Thème et HUD | `Contrastes validés`, palette sûre et cinq surfaces visibles |
| Sortie terminal du lancement final | aucune exception applicative |

## 4. Captures et intégrité

Les quatre captures ont été faites directement depuis la fenêtre de
l'application, sur une région de 1920 × 950 pixels. Aucune retouche d'image n'a
été appliquée.

| Preuve | SHA-256 | Contenu |
|---|---|---|
| `evidence/pst_063/01_personalization_studio_branding.png` | `58ccb1a212e21d5bfe1ad66ec1be4b6df51f06349cf66f68ddbd8b25cbe73863` | Studio ouvert sur Branding |
| `evidence/pst_063/02_intro_landscape.png` | `524ed1f3c0333a988d1395ab389a5d20b17d1e73592c3cbaa077322ca3aec99b` | intro 1280 × 720, paysage 16:9 |
| `evidence/pst_063/03_intro_portrait.png` | `2381c6f605f83fd6be29852bc7f6997d121dd431f67cd063b9b1dfcaf18138b5` | intro 720 × 1280, portrait 9:16 |
| `evidence/pst_063/04_theme_contrast.png` | `e2878c65d353e3bbf42a1fe0d195c90871cfc0728cc48fb43bc06b525cf90c12` | thème, HUD et contrastes validés |

Les PNG sont des fichiers binaires : leur contenu brut ne peut pas être inclus
utilement dans ce Markdown. Les dimensions, empreintes cryptographiques et
descriptions ci-dessus en constituent l'inventaire vérifiable. Le présent
rapport, également créé dans ce lot, n'est pas reproduit récursivement en son
sein.

## 5. Commandes et résultats exacts

```text
flutter test test/dev/marionette_main_test.dart --reporter expanded
00:00 +5: All tests passed!

flutter analyze dev/marionette_main.dart test/dev/marionette_main_test.dart
No issues found! (ran in 3.7s)

flutter build macos --debug --target dev/marionette_main.dart
✓ Built build/macos/Build/Products/Debug/map_editor.app

git diff --check
<aucune sortie>
```

La première passe d'analyse a signalé un unique
`unnecessary_const` dans le nouveau test. Le `const` redondant a été supprimé,
puis test et analyse ont été relancés avec succès.

## 6. Passes de revue

La consigne de session interdit de déléguer à des sub-agents sans demande
explicite de l'utilisateur. Aucune revue sub-agent n'a donc été lancée. Quatre
passes indépendantes ont été effectuées par l'agent principal :

| Passe | Verdict |
|---|---|
| Architecture | PASS — extension limitée au point d'entrée debug |
| Validation | PASS — test, analyse, build et `git diff --check` verts |
| Revue visuelle | PASS — quatre états lisibles et cohérents |
| Critique finale | PASS avec limites de harnais ci-dessous |

## 7. Limites, incidents et risques

- Le premier emplacement `/tmp` s'est résolu vers `/private/tmp`, puis a été
  refusé par le sandbox macOS. Le projet a été déplacé dans le conteneur
  applicatif ; `pokemap.activeProjectPath` a confirmé deux fois le chemin exact.
- `marionette.get_logs` a renvoyé `Server error`. La sortie de `flutter run` a
  donc servi de source d'erreurs ; le lancement final n'a produit aucune
  exception applicative.
- `marionette.scroll_to` a déclenché une exception interne au callback du
  package de test. Les catégories nécessaires étaient déjà interactives et ont
  été parcourues par clés stables, sans dépendre de ce geste.
- La certification visuelle porte sur macOS. Les autres plateformes restent du
  ressort de la recertification `PH-007`.
- Le projet QA jetable a été déplacé vers la Corbeille après capture et reste
  récupérable.

## 8. Inventaire final du lot

Fichiers modifiés :

- `packages/map_editor/dev/marionette_main.dart`
- `packages/map_editor/test/dev/marionette_main_test.dart`

Fichiers créés :

- `reports/gameplay/pst_063_personalization_studio_desktop_qa.md`
- `reports/gameplay/evidence/pst_063/01_personalization_studio_branding.png`
- `reports/gameplay/evidence/pst_063/02_intro_landscape.png`
- `reports/gameplay/evidence/pst_063/03_intro_portrait.png`
- `reports/gameplay/evidence/pst_063/04_theme_contrast.png`

## 9. Conclusion

`PST-063` peut être proposé **DONE** : le Studio a été ouvert dans une vraie
application desktop, le projet actif a été observé, les quatre zones critiques
ont été parcourues, les deux orientations vidéo sont certifiées et les preuves
visuelles sont versionnées. Les limites observées relèvent du harnais Marionette,
pas du comportement produit couvert par ce lot.
