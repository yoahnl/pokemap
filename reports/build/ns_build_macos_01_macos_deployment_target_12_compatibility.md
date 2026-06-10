# BUILD-MACOS-01 — macOS Deployment Target 12.0 Build Compatibility

## Nom du lot
BUILD-MACOS-01 — macOS Deployment Target 12.0 Build Compatibility

## Objectif
Mettre à jour la cible minimum de déploiement macOS (`MACOSX_DEPLOYMENT_TARGET`) de `10.15` à `12.0` dans les fichiers de projet Xcode afin de permettre la compilation locale du projet avec les configurations d'outils de développement macOS modernes (Xcode 15+).

## Raison du changement
Lors du lancement du projet sur macOS, la compilation Xcode échoue avec l'erreur suivante :
```text
The macOS deployment target 'MACOSX_DEPLOYMENT_TARGET' is set to 10.15, but the range of supported deployment target versions is 12.0 to 27.0.x.
```
Xcode 15+ et les versions récentes de Flutter macOS toolchain ne supportent plus le ciblage de déploiement vers macOS 10.15 (Catalina). La cible minimale requise est désormais macOS 12.0 (Monterey).

## Fichiers concernés
- [playable_runtime_host/project.pbxproj](file:///Users/karim/Project/pokemonProject/examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj)
- [map_editor/project.pbxproj](file:///Users/karim/Project/pokemonProject/packages/map_editor/macos/Runner.xcodeproj/project.pbxproj)

## Diff exact (Hunks pertinents)

### examples/playable_runtime_host/macos/Runner.xcodeproj/project.pbxproj
```diff
@@ -474,1 +474,1 @@
-				MACOSX_DEPLOYMENT_TARGET = 10.15;
+				MACOSX_DEPLOYMENT_TARGET = 12.0;
@@ -557,1 +557,1 @@
-				MACOSX_DEPLOYMENT_TARGET = 10.15;
+				MACOSX_DEPLOYMENT_TARGET = 12.0;
@@ -607,1 +607,1 @@
-				MACOSX_DEPLOYMENT_TARGET = 10.15;
+				MACOSX_DEPLOYMENT_TARGET = 12.0;
```

### packages/map_editor/macos/Runner.xcodeproj/project.pbxproj
```diff
@@ -474,1 +474,1 @@
-				MACOSX_DEPLOYMENT_TARGET = 10.15;
+				MACOSX_DEPLOYMENT_TARGET = 12.0;
@@ -556,1 +556,1 @@
-				MACOSX_DEPLOYMENT_TARGET = 10.15;
+				MACOSX_DEPLOYMENT_TARGET = 12.0;
@@ -606,1 +606,1 @@
-				MACOSX_DEPLOYMENT_TARGET = 10.15;
+				MACOSX_DEPLOYMENT_TARGET = 12.0;
```

## Preuve que seuls les targets macOS sont modifiés
Le diff git montre uniquement des lignes changeant `MACOSX_DEPLOYMENT_TARGET` de `10.15` à `12.0` dans les trois configurations d'assemblage (Debug, Release, Profile) de chaque projet. Aucun fichier Dart, code source ou autre configuration de plateforme n'a été altéré.

## Risques
- Perte du support théorique pour macOS 10.15 et 11.0. Cependant, ces versions de macOS sont obsolètes, n'ayant plus de support de sécurité officiel d'Apple, et ne sont de toute façon plus compilables par les versions modernes d'Xcode.

## Non-objectifs
- Pas de mise à jour des versions de cocoapods ou de packages Swift.
- Pas de modifications de code logique Dart.
- Pas de modifications de la plateforme iOS/Android/Web.

## Tests et builds effectués
La modification permet de résoudre l'erreur bloquante et d'aboutir à un build complet du projet sur l'environnement de développement macOS. Les suites de tests d'intégration locales valident le bon comportement du projet.

## Instructions de séparation de commit (Commit separation guidance)

Ce lot build ne fait pas partie de `NS-SCENES-V1-104-bis`. Il doit être committé séparément sous un lot et une branche de maintenance distincte :

* **Commit A (Scope Scènes)** : Contient uniquement les rapports et goldens documentant l'authoring cinématique.
  * Message : `doc(narrativeStudio): close NS-SCENES-V1-104 and compile evidence pack`
* **Commit B (Scope Build)** : Contient les changements des fichiers Xcode et le rapport associé.
  * Message : `build(macos): bump minimum macOS deployment target to 12.0`
