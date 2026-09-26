# Avelune iOS — refonte de la bibliothèque native

## Résumé exécutif

La bibliothèque iOS a été refaite en SwiftUI autour d'un en-tête Avelune, d'un carrousel paysage, d'une collection portrait, d'un aperçu par appui long et d'une fiche de jeu. Les couleurs s'adaptent aux modes clair et sombre. Les actions « Jouer » et « Reprendre » réutilisent le lancement Flutter existant. Le format de package n'a pas changé : ses champs `branding.cover` et `branding.hero` existaient déjà.

Verdict : **prêt pour revue, avec Visual Gate partiel**. Les tests Swift et les quatre parcours UI sur simulateur passent. Deux jeux ont permis d'observer le swipe entre les deux positions du carrousel. Ils n'ont ni cover ni hero : le rendu avec de vraies illustrations reste à observer. Une nouvelle installation par le sélecteur de fichiers n'a pas été rejouée de bout en bout.

## Mandat, périmètre et audit initial

Sources de direction : `IMPLEMENTATION_PROMPT.md`, `UX_UI_SPEC.md`, `ASSET_MODEL_NOTES.md` et les cinq maquettes du kit fourni. Le prompt joint décrit le résultat visé et les preuves attendues ; le code et les contrats du dépôt ont servi à décider de l'implémentation. Les règles du dépôt et `codex_rule.md` ont été lues avant ce rapport.

État Git initial : branche `main`, worktree déjà modifié dans Studio, `map_core`, `map_editor`, `map_gameplay`, `map_runtime` et la documentation ; **aucun changement dans `apps/Avelune iOS`** avant cette tâche. Ces travaux concurrents ont été laissés tels quels. Aucun commit ni autre écriture Git n'a été fait avant l'autorisation explicite de livraison.

Architecture observée : `GameListView` était déjà une vue SwiftUI native ; `GameListViewModel` assurait la lecture, l'installation et la suppression via le pont Flutter. `ContentView` ouvrait `GamePlayerView` à partir de `onGameSelected`. `Game` recevait déjà `iconPath`, `coverPath`, `heroPath`, les informations de jeu et la progression. `InstalledHubGameActivityReader` résolvait les visuels installés ; le pont dans `flutter_runtime/lib/main.dart` les transmettait déjà. Le manifeste de distribution accepte séparément `branding.cover` et `branding.hero`. Aucun contrat de galerie de captures d'écran n'a été trouvé : la fiche n'affiche donc pas de galerie vide. Les assets AveluneMoon et AveluneWordmark existaient dans l'application. L'ancien écran imposait le mode sombre et une liste verticale.

Décision d'assets : `cover` est prioritaire dans la collection portrait, `hero` dans le carrousel et la fiche paysage. Chaque surface essaie ensuite l'autre image, puis l'icône ; à défaut de fichier lisible, elle dessine un placeholder natif. Les chemins sont dédupliqués. L'ancienne archive sans cover/hero reste lisible. Le décodage est réduit à la taille affichée et mis en cache. Il n'y a ni nouveau champ `coverPortrait`/`heroLandscape`, ni migration, ni copie d'asset dans le repo.

## Fichiers et zones changés

| Fichier | Zone et effet |
| --- | --- |
| `apps/Avelune iOS/AveluneiOS/Domain/Entities/Game.swift` | `supportedLocales`, `coverCandidates`, `heroCandidates`, `featuredOrder` : expose les langues du pont, l'ordre de repli des images et le jeu récemment joué en premier. |
| `apps/Avelune iOS/flutter_runtime/lib/main.dart` | Payload de bibliothèque : ajoute `supportedLocales` depuis le modèle existant, sans modifier le handoff de lancement. |
| `apps/Avelune iOS/AveluneiOS/ContentView.swift` | Supprime le mode sombre forcé et utilise l'accent adaptatif ; le `fullScreenCover` du runtime reste en place. |
| `apps/Avelune iOS/AveluneiOS/Presentation/Views/AveluneTheme.swift` | Tokens de couleurs dynamiques clair/sombre, fond et boutons ; aucune nouvelle dépendance. |
| `apps/Avelune iOS/AveluneiOS/Presentation/Views/GameListView.swift` | En-tête, état vide, composition carrousel/collection, routage vers fiche et Quick View ; sélecteur de fichier, installation et suppression conservés. Le passage Quick View → fiche reporte l'ajout de la route au tour suivant pour éviter la perte de navigation observée en test. |
| `apps/Avelune iOS/AveluneiOS/Presentation/Views/SettingsView.swift` | Contrastes des textes et du logo adaptés au thème clair. |
| `apps/Avelune iOS/AveluneiOS/Presentation/Views/GameLibraryComponents.swift` **créé** | Lignes 5–83 : décodage et placeholder ; 86–199 : carrousel `ScrollView` à alignement natif et indicateur de page ; 201–294 : grille et appui long ; 296–fin : Quick View et transition géométrique, avec réduction des animations si demandée par iOS. |
| `apps/Avelune iOS/AveluneiOS/Presentation/Views/GameDetailView.swift` **créé** | Hero, description dépliable et informations conditionnelles ; CTA vers le callback de lancement existant ; aucune galerie sans contrat de captures. |
| `apps/Avelune iOS/project.yml` | Déclare les cibles unitaires et UI, avec un schéma `AveluneVisualGate` séparé de la suite habituelle. |
| `apps/Avelune iOS/AveluneiOS.xcodeproj/project.pbxproj` | Projet régénéré par XcodeGen pour les nouvelles sources et cibles de test. |
| `apps/Avelune iOS/AveluneiOS.xcodeproj/xcshareddata/xcschemes/AveluneiOS.xcscheme` | Ajoute les tests unitaires à la suite standard. |
| `apps/Avelune iOS/AveluneiOS.xcodeproj/xcshareddata/xcschemes/AveluneVisualGate.xcscheme` **créé** | Schéma de tests UI opt-in. |
| `apps/Avelune iOS/AveluneiOSTests/GameLibraryTests.swift` **créé** | Quatre tests : ancien payload, priorités cover/hero, fichier manquant, ordre 0/1/N. |
| `apps/Avelune iOS/AveluneiOSUITests/LibraryVisualGateTests.swift` **créé** | Quatre parcours : swipe du carrousel avec deux jeux, fiche + fermeture de Quick View, Quick View → fiche, Quick View → lancement Flutter. Les tests sautent explicitement si les jeux requis ne sont pas installés. |

Fichiers supprimés : aucun. Les anciennes sous-vues de liste et d'artwork ont été remplacées dans `GameListView.swift` par les nouveaux composants, sans suppression de fichier.

## Architecture et comportement final

`GameListViewModel` reste la source de vérité de la bibliothèque. `GameListView` ne gère que la composition et la navigation ; `Game` fournit les priorités d'artwork. Le carrousel est une `ScrollView` horizontale avec cibles alignées et aperçu de la carte voisine ; ses points apparaissent pour plusieurs jeux. La grille utilise des cellules portrait adaptatives et garde l'action d'ajout et le menu de suppression. L'appui long ouvre la Quick View, dont le fond partage une géométrie avec la cellule ; Reduce Motion utilise une transition par opacité. La fiche affiche seulement les données disponibles, dont la langue issue du pont Flutter. Tous les CTA de jeu appellent le même `onGameSelected` que l'ancien écran, puis `GamePlayerView`.

## Vérifications et résultats exacts

Environnement : Xcode 27, simulateur iPhone 17 Pro iOS 27, identifiant `143CE64A-C480-4FC6-8655-1B272E182AC6`.

| Vérification | Résultat |
| --- | --- |
| `xcodegen generate` dans `apps/Avelune iOS` | Réussi ; projet régénéré. |
| `flutter analyze lib/main.dart` dans `apps/Avelune iOS/flutter_runtime` | `No issues found! (ran in 5.7s)`. |
| `xcodebuild -project AveluneiOS.xcodeproj -scheme AveluneiOS -configuration Debug -destination 'platform=iOS Simulator,id=143CE64A-C480-4FC6-8655-1B272E182AC6' -derivedDataPath build/redesign -parallel-testing-enabled NO test` | `Executed 4 tests, with 0 failures (0 unexpected)` ; `** TEST SUCCEEDED **`. Trace finale : `/tmp/avelune-unit-after-runtime.log`. |
| `bash tool/build_runtime.sh --no-codesign` | Exit 0 ; package Swift Flutter Debug et Release reconstruits, projet Xcode régénéré. Trace : `/tmp/avelune-redesign-runtime-rebuild.log`. |
| `xcodebuild -project AveluneiOS.xcodeproj -scheme AveluneVisualGate -configuration Debug -destination 'platform=iOS Simulator,id=143CE64A-C480-4FC6-8655-1B272E182AC6' -derivedDataPath build/redesign -parallel-testing-enabled NO test` | `Executed 4 tests, with 0 failures (0 unexpected)` en `109.997` s ; `** TEST SUCCEEDED **`. Trace : `/tmp/avelune-visual-two-games.log`. |
| `xcodebuild -project AveluneiOS.xcodeproj -scheme AveluneiOS -configuration Release -destination 'generic/platform=iOS Simulator' -derivedDataPath build/redesign CODE_SIGNING_ALLOWED=NO build` | `** BUILD SUCCEEDED **`. Trace finale : `/tmp/avelune-redesign-release-final.log`. |
| `git diff --check -- 'apps/Avelune iOS'` | Aucune sortie, exit 0. |
| `bash tools/scripts/check_markdown_hygiene.sh` | Exit 1 : `Markdown hygiene: 1 new Markdown files exceed the default limit of 0.` Le prompt joint exige explicitement ce rapport unique ; l'exception chiffrée n'a pas été appliquée. |

Le test UI a balayé le carrousel, ouvert la fiche, fermé l'aperçu, ouvert la fiche depuis l'aperçu et lancé le runtime Flutter par le bouton `Jouer`. La capture de handoff montre l'écran Flutter, mais cette preuve ne couvre pas une partie jouée jusqu'au bout. Un ancien build iOS portant le même nom d'application était aussi installé sur le simulateur ; les captures retenues proviennent du bundle compilé `com.yoahnl.avelune.player` réinstallé depuis `build/redesign`.

Pour obtenir deux jeux sans toucher aux données du dépôt, un second package de démonstration v7 a été construit dans `/tmp` à partir de l'ancien exemple v6, puis installé dans le seul conteneur du simulateur via `GamePackageInstaller` (sortie : `installed=games.avelune.redesign-demo games=2`). Cette préparation de fixture ne prouve pas le sélecteur de fichiers iOS. Le package temporaire ne fait pas partie du produit livré.

## Visual Gate comparé aux maquettes

| Écran | Preuve | Observation |
| --- | --- | --- |
| Bibliothèque claire avec un jeu | `/tmp/avelune-redesign-installed-light-settled.png` | Hiérarchie en-tête → hero → collection, deux ratios distincts, bonne lisibilité. Wordmark plus pâle que dans la direction de référence claire. |
| Bibliothèque sombre avec un jeu | `/tmp/avelune-redesign-installed-dark.png` | Même structure, surfaces et CTA lisibles ; le placeholder respecte l'ambiance de la maquette sombre. |
| État vide clair | `/tmp/avelune-redesign-installed-light.png` | Carte d'accueil, logo et action d'import visibles avant la fin du chargement asynchrone. |
| Quick View | `/tmp/avelune-visual-final/9D4EB378-C33A-4507-B4DC-0B736BB068AD.png` et pièce jointe `apercu-rapide` du résultat UI | L'appui long ouvre l'aperçu, le placeholder reste visible, les trois actions fonctionnent. |
| Fiche | `/tmp/avelune-visual-dark/3E0994B4-422F-47F9-9CA9-FEAF7F6F9F81.png` et pièce jointe `fiche-jeu` | Hero et informations conditionnelles présents, galerie absente comme prévu. |
| Carrousel à deux positions | `/tmp/avelune-two-game-attachments/D9095BA8-599E-4925-B2EA-98CC12540F8B.png` et `/tmp/avelune-two-game-attachments/6E0766D4-CDB0-426E-BA35-8F90B64229B7.png` | Swipe réel page 1 → 2 ; carte voisine visible sur le bord et indicateur mis à jour. Fixture de simulateur sans artwork. |

Ces captures ont été comparées aux maquettes `02_library_dark_carousel_refined.png`, `03_library_light_carousel_refined.png`, `04_long_press_quick_view.png` et `05_game_detail_page.png`. Elles vérifient surtout la hiérarchie, les ratios, le swipe et les deux thèmes. Les jeux de démonstration n'ont pas d'images `cover` ou `hero`, donc aucune conclusion sur le rendu illustré n'est possible. Les fichiers `/tmp` et les résultats Xcode sont des preuves locales temporaires, non des assets versionnés.

## Passes de revue et critique du mandat

| Passe | Verdict |
| --- | --- |
| Audit / architecture | Le shell SwiftUI et le pont Flutter existaient ; refonte ciblée, sans schéma ni runtime de jeu nouveau. |
| Implémentation | Vue native, modes clair/sombre, fallback images, Quick View et fiche intégrés ; aucune refonte hors scope. |
| Tests | 4 tests unitaires et 4 UI verts sur simulateur ; les UI reposent sur des jeux préinstallés. |
| Build / validation | Analyse Flutter, package Swift Flutter reconstruit et build iOS vérifiés ; aucune preuve TestFlight ni appareil physique. |
| Critique finale | Les deux positions sont observées. La qualité d'artwork reste sans preuve avec ces fixtures ; le traitement d'installation existant est conservé, mais l'import complet doit encore être rejoué. |

Le prompt demandait éventuellement de créer un modèle portrait/paysage : l'audit a montré que le contrat correspondant était déjà disponible. Ajouter un nouveau champ aurait créé du churn sans valeur. Il demandait aussi une galerie conditionnelle : aucun contrat de screenshots n'existe, donc la cacher est l'implémentation honnête. Le Visual Gate ne peut pas être déclaré intégralement satisfait sans jeu illustré et sans relecture artistique sur appareil.

## Limites, dette et état Git avant livraison

Restent à vérifier : import et installation d'un package frais depuis Files, captures avec cover et hero distincts, contrôle sur iPhone physique et validation artistique par Yoahn. Le fichier Dart du pont a été analysé et le package Flutter Swift a été reconstruit. La valeur `supportedLocales` dispose d'un repli sur la langue par défaut pour les binaires précédents.

L'hygiène Markdown conserve par défaut un budget de zéro nouveau fichier ; ce rapport unique, demandé par le prompt joint, fait échouer ce contrôle. Aucun autre document Markdown n'a été créé pour cette tâche.

Au contrôle précédant le commit autorisé par Yoahn : branche `main`, tous les fichiers iOS listés ci-dessus non commités et les modifications initiales hors iOS toujours présentes. `git diff --stat` ne compte que les fichiers déjà suivis : `393 insertions(+), 214 deletions(-)` dans neuf fichiers iOS ; cinq chemins nouvellement créés sont visibles séparément dans `git status`. `git diff --check` est propre. Le SHA livré et la preuve de synchronisation distante sont consignés dans le ticket Notion `POST-AVL-IOS-UI-002` après le push. L'état Git exact est à relire dans le worktree au moment de la revue, car d'autres tâches partagent ce checkout.
