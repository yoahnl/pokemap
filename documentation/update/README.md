# Mise à jour automatique de PokeMap Editor

## 1. Statut du chantier

Ce document consolide le chantier d’auto-update du `map_editor` réalisé dans
les lots `UPD-*`. Il décrit le code livré, le modèle de sécurité, le pipeline
GitHub, les preuves disponibles et le travail restant avant une diffusion
stable.

État au 3 août 2026 : **implémenté, mais pas encore certifié pour la
production**.

La détection et l’expérience Flutter, l’intégration native macOS et Windows,
ainsi que la publication atomique GitHub sont présentes dans le code. Une
première vraie boucle d’update entre deux versions installées reste toutefois
à prouver. Windows est volontairement mis de côté pour le moment et Linux reste
un paquet téléchargeable sans mise à jour automatique.

| Plateforme | Implémentation | Certification réelle | Diffusion stable |
|---|---|---|---|
| macOS | Sparkle 2.9.5, signature Developer ID, notarisation et feed signé | PARTIAL : preflight complet vert ; cycle installé `0.3.0 → 0.3.1` encore à certifier | Bloquée tant que la release multi-plateforme n’est pas certifiée |
| Windows | WinSparkle 0.9.4, Inno Setup et appcast EdDSA | BLOCKED : clés/secrets et test sur machine propre manquants | Bloquée |
| Linux | archive `.tar.gz` versionnée et checksums | PARTIAL : build GitHub vert ; installation et lancement sur machine Linux propre à confirmer | Téléchargement manuel seulement |

Important : **ne pas pousser de tag `pokemap-v*` tant que Windows est mis de
côté**. Le pipeline de release est fail-closed et exige les artefacts macOS,
Windows et Linux avant toute publication.

## 2. Résumé exécutif

Le système est divisé en trois couches :

1. Flutter consulte un petit index JSON stable pour annoncer une nouvelle
   version et présenter une interface PokeMap cohérente.
2. Sparkle sur macOS ou WinSparkle sur Windows prend ensuite en charge le
   téléchargement, la signature, l’installation et le redémarrage natifs.
3. GitHub Actions construit les paquets, valide leurs métadonnées et signatures,
   crée une release brouillon, retélécharge les fichiers, les revalide, publie
   la release versionnée, puis promeut les feeds stables.

L’index Flutter n’est pas une autorité de confiance suffisante pour exécuter un
binaire. Les archives natives sont vérifiées avec Ed25519 par les frameworks
natifs et par le validateur de release. Une altération des artefacts couverts
après leur signature ou leur checksum est détectée par la revalidation
correspondante avant publication.

La parité PokeMap MCP est **non applicable** : ce chantier distribue le binaire
de l’éditeur, sans ajouter ni modifier une sémantique d’authoring, un format de
projet, une validation, un import/export, un rendu ou un playtest. Exposer une
installation système via `map_authoring` serait hors contrat et dangereux.

## 3. Historique des quatre phases

Les identifiants ci-dessous sont les commits obtenus après rebase sur `main`.

### Phase 1 — Fondations (`5146218f1`)

Commit : `feat(map_editor): add auto-update foundations`.

- contrat de version `X.Y.Z+BUILD` et cohérence avec le tag
  `pokemap-vX.Y.Z` ;
- lecture de la version réellement installée depuis les métadonnées du
  binaire ;
- catalogue GitHub stable fondé sur `pokemap-update-index.json` ;
- rejet des prereleases, schémas inconnus, réponses trop grandes, redirections
  et URLs non approuvées ;
- contrôleur d’update commun, états typés et vérifications automatiques ou
  manuelles ;
- abstraction du moteur natif, du navigateur de notes de version et des
  capacités de plateforme ;
- premier registre extensible de travail non sauvegardé et garde de
  redémarrage ;
- host Riverpod global et tests de contrat.

Volume du commit : 33 fichiers, 2 996 insertions, 4 suppressions.

### Phase 2 — Expérience utilisateur (`113136289`)

Commit : `feat(map_editor): add UwU desktop update experience`.

- bandeau d’update réutilisable dans le design system ;
- messages et actions localisés en français et en anglais ;
- commande « Vérifier les mises à jour » dans les principaux shells ;
- intégration dans la toolbar classique, World Map, Narrative Studio et le
  menu Help natif macOS ;
- affichage de la version, des notes de release et des erreurs sûres ;
- refus ou report du redémarrage lorsque le travail connu n’est pas prêt à
  être fermé ;
- tests unitaires, widgets et contrats de menus.

Volume du commit : 35 fichiers, 2 065 insertions, 18 suppressions.

### Phase 3 — Intégrations natives signées (`3711ddcf7`)

Commit : `feat(map_editor): integrate signed native desktop updates`.

macOS :

- Sparkle épinglé à la version `2.9.5` via Swift Package Manager ;
- bridge Swift unique entre Flutter et Sparkle ;
- feed HTTPS, clé publique Ed25519 embarquée et feed Sparkle signé ;
- configuration sandbox, services d’installation et ouverture sûre des liens ;
- signature Developer ID, notarisation, stapling, DMG et archive `.app.zip` ;
- preflight de fermeture commun avant installation et redémarrage.

Windows :

- WinSparkle épinglé à `0.9.4` ;
- acquisition NuGet protégée par un SHA-256 fixe ;
- bridge C++ thread-safe et callbacks de fermeture ;
- installateur Inno Setup par utilisateur ;
- appcast Windows et installateur signés avec EdDSA ;
- inclusion contrôlée de `WinSparkle.dll` dans le bundle Release.

Volume du commit : 30 fichiers, 1 400 insertions, 125 suppressions.

### Phase 4 — Publication GitHub atomique (`7931987dd`)

Commit : `feat(map_editor): publish atomic desktop updates`.

- version et build number produits une seule fois par `validate-release` ;
- builds taggés macOS, Windows et Linux utilisant les mêmes valeurs ;
- génération déterministe de `pokemap-update-index.json` ;
- génération de `SHA256SUMS` ;
- parsing XML/JSON robuste et validation fail-closed des assets ;
- vérification cryptographique Ed25519 de l’archive macOS, du feed macOS signé
  et de l’installateur Windows ;
- création d’une release GitHub en brouillon ;
- retéléchargement depuis GitHub et nouvelle validation des tailles, hashes,
  versions, URLs, types MIME et signatures ;
- publication de la release versionnée uniquement après le smoke test ;
- promotion des deux appcasts, puis de l’index commun **en dernier** vers la
  release roulante `pokemap-editor-update-stable` ;
- workflow manuel `macos-preflight` pour tester les secrets Apple sans publier
  de release et sans dépendre de Windows.

Volume du commit : 9 fichiers, 1 298 insertions, 29 suppressions.

### Durcissement final avant push

La critique finale a identifié et fait corriger deux scénarios de concurrence :

- tous les jobs de publication exigent désormais à la fois un événement
  `push` et un tag `pokemap-v*`; un `workflow_dispatch` ciblant un tag ne peut
  donc exécuter que le preflight macOS ;
- toutes les releases taggées partagent un verrou global
  `pokemap-desktop-stable-release`, empêchant deux versions différentes de
  promouvoir simultanément le même feed roulant.

Deux tests de contrat dédiés empêchent la régression de ces garde-fous.

## 4. Expérience dans l’éditeur

Le démarrage programme une vérification silencieuse après un délai. L’utilisateur
peut aussi demander une vérification depuis les emplacements exposés par les
shells de l’éditeur.

Les états visibles sont typés : vérification, aucune mise à jour, mise à jour
disponible, installation en cours, action différée, non supporté et échec
récupérable. Le bandeau PokeMap propose les actions adaptées sans exposer les
détails internes de Sparkle ou WinSparkle.

Quand une version est disponible :

1. Flutter affiche la version et un lien sûr vers les notes de release.
2. L’utilisateur déclenche le flux natif.
3. Le contrôleur vérifie si l’éditeur est prêt à fermer.
4. Sparkle ou WinSparkle télécharge et vérifie le paquet signé.
5. Le framework natif installe la nouvelle version et gère le redémarrage.

Linux expose un état non supporté pour l’installation automatique. Le paquet
Linux reste téléchargeable depuis la release GitHub.

## 5. Contrats de version et de publication

### Version

Le `pubspec.yaml` du `map_editor` utilise actuellement :

```yaml
version: 0.3.0+300
```

- `0.3.0` est la version visible ;
- `300` est le build number numérique ;
- le tag stable correspondant est obligatoirement `pokemap-v0.3.0` ;
- une release stable ne peut pas utiliser de prerelease SemVer ;
- les builds macOS, Windows et Linux reçoivent la même version et le même
  build number.

Le validateur sait comparer le build number à une valeur précédente lorsqu’elle
lui est fournie. Le workflow GitHub ne récupère pas encore automatiquement le
build précédent depuis la dernière release : la monotonie inter-release reste
donc un contrôle opératoire à renforcer.

### Index stable

`pokemap-update-index.json` suit ce schéma exact :

```json
{
  "schemaVersion": 1,
  "channel": "stable",
  "version": "0.3.1",
  "tag": "pokemap-v0.3.1",
  "publishedAt": "2026-08-03T12:00:00.000Z",
  "releaseNotesUrl": "https://github.com/yoahnl/pokemap/releases/tag/pokemap-v0.3.1"
}
```

URL roulante consommée par Flutter :

```text
https://github.com/yoahnl/pokemap/releases/download/pokemap-editor-update-stable/pokemap-update-index.json
```

### Appcasts natifs

```text
https://github.com/yoahnl/pokemap/releases/download/pokemap-editor-update-stable/appcast-macos.xml
https://github.com/yoahnl/pokemap/releases/download/pokemap-editor-update-stable/appcast-windows.xml
```

Chaque appcast pointe vers l’asset immutable de la release versionnée, jamais
vers un binaire roulant.

### Assets exigés pour une release stable

Pour une version `X.Y.Z`, le validateur exige exactement :

```text
PokeMap-Editor-Setup-X.Y.Z.exe
PokeMap-Editor-X.Y.Z-macOS.dmg
PokeMap-Editor-X.Y.Z-macOS.app.zip
PokeMap-Editor-X.Y.Z-linux-x64.tar.gz
appcast-macos.xml
appcast-windows.xml
pokemap-update-index.json
SHA256SUMS
```

## 6. Modèle de sécurité

- toutes les URLs d’update sont HTTPS et limitées au dépôt GitHub attendu ;
- l’index JSON annonce une version, mais n’autorise pas à lui seul l’exécution
  d’un paquet ;
- Sparkle et WinSparkle utilisent des clés Ed25519 publiques embarquées ;
- les clés privées ne sont jamais écrites dans le dépôt ;
- l’archive Sparkle, le feed macOS signé et l’installateur Windows sont
  revérifiés cryptographiquement pendant l’assemblage ;
- `SHA256SUMS` protège l’intégrité publique de tous les assets ;
- le brouillon GitHub est retéléchargé et vérifié avant de devenir public ;
- la release versionnée existante n’est jamais écrasée silencieusement ;
- l’index stable est promu en dernier afin qu’il n’annonce pas une version dont
  les feeds ne sont pas encore disponibles ;
- les workflows de pull request et de preview n’accèdent à aucun secret de
  release ;
- les actions GitHub utilisées sont épinglées par SHA ;
- toutes les publications stables sont sérialisées globalement, indépendamment
  du tag ; les previews ordinaires conservent un groupe propre à leur ref.

## 7. Secrets GitHub

La source autoritative des noms est
`.github/workflows/pokemap_desktop_release.yml`. Les noms historiques de la
roadmap ne doivent pas être copiés aveuglément.

### macOS — configurés dans l’environnement `pokemap-release`

```text
APP_SPECIFIC_PASSWORD
APPLE_ID
APPLE_TEAM_ID
DEVELOPER_ID_APPLICATION
DEVELOPER_ID_P12_BASE64
DEVELOPER_ID_P12_PASSWORD
KEYCHAIN_PASSWORD
POKEMAP_SPARKLE_PUBLIC_ED_KEY
SPARKLE_PRIVATE_ED_KEY_BASE64
```

Le fichier exporté par `generate_keys -x` contient déjà le seed privé Sparkle
encodé en base64. Il ne faut pourtant pas coller directement ce texte dans
`SPARKLE_PRIVATE_ED_KEY_BASE64` : le workflow attend le fichier complet,
lui-même réencodé en base64 pour son transport dans GitHub Actions. La commande
correcte, qui n'affiche pas la clé, est :

```bash
base64 < pokemap-sparkle-private.key | tr -d '\n' | \
  gh secret set SPARKLE_PRIVATE_ED_KEY_BASE64 \
    --env pokemap-release --repo yoahnl/pokemap
```

Après un seul décodage par le workflow, le fichier temporaire doit donc rester
un texte ASCII base64. Pour une clé Sparkle récente, ce texte décodé représente
exactement 32 octets :

```bash
test "$(base64 --decode < pokemap-sparkle-private.key | wc -c | tr -d ' ')" = 32
```

Une clé privée exportée directement dans le secret serait décodée en octets
binaires par le workflow et `generate_appcast` la refuserait comme texte UTF-8.
Le preflight manuel permet de détecter cette erreur sans publier de release.

### Windows — encore manquants

```text
POKEMAP_WINSPARKLE_EDDSA_PUBLIC_KEY
WINSPARKLE_PRIVATE_ED_KEY_BASE64
```

La paire Windows doit être distincte de la paire Sparkle macOS. La clé publique
représente exactement 32 octets encodés en base64. Le secret privé représente
le fichier privé WinSparkle complet, lui-même réencodé en base64 pour son
transport dans GitHub Actions.

Ne jamais afficher une valeur de secret dans un log, une issue, une capture ou
un fichier du dépôt. Conserver une sauvegarde chiffrée des clés privées hors de
GitHub.

Inventaire sans afficher les valeurs :

```bash
gh secret list --env pokemap-release
```

## 8. Runbook GitHub Actions

### Push ordinaire sur `main`

Un push sur `main` lance les previews sans secrets :

- `macos-preview` ;
- `windows` ;
- `linux-preview`.

Ce run prouve les tests, l’analyse et les builds de preview. Il ne prouve ni la
signature Developer ID, ni la notarisation Apple, ni les signatures privées de
release.

### Preflight macOS manuel

Après que le workflow existe sur `main` :

```bash
gh workflow run pokemap_desktop_release.yml --ref main
gh run list --workflow pokemap_desktop_release.yml \
  --event workflow_dispatch --limit 1
gh run watch RUN_ID --exit-status
gh run view RUN_ID --log-failed
```

Le job `macos-preflight` :

1. importe temporairement le certificat Developer ID ;
2. injecte la clé publique Sparkle ;
3. teste, analyse et construit l’application ;
4. signe le bundle ;
5. le soumet à Apple, attend la notarisation et staple le ticket ;
6. génère le DMG, le ZIP Sparkle et l’appcast signé ;
7. conserve ces preuves comme artefact GitHub pendant sept jours ;
8. ne crée et ne publie aucune GitHub Release.

### Release stable complète — à ne pas lancer actuellement

Un tag `pokemap-vX.Y.Z` déclenche :

```text
validate-release
  ├── macos-release
  ├── windows-release
  └── linux-release
        ↓
assemble-release
        ↓
create-draft-release
        ↓
smoke-download-draft
        ↓
publish-release
        ↓
promote-stable-feed
```

La release complète restera bloquée tant que les secrets Windows ne sont pas
présents. C’est volontaire : aucun canal stable partiel n’est publié par erreur.

## 9. Travail restant pour Windows

### 9.1 Générer et sauvegarder la paire EdDSA

Cette opération doit être effectuée sur un environnement Windows de confiance
avec le `winsparkle-tool.exe` fourni par WinSparkle `0.9.4`.

1. Vérifier la syntaxe réelle avec `winsparkle-tool.exe --help`.
2. Générer une nouvelle paire dédiée à PokeMap Windows.
3. Conserver le fichier privé hors Git et dans une sauvegarde chiffrée.
4. Vérifier que la clé publique décodée contient exactement 32 octets.
5. Encoder le fichier privé complet en base64 pour GitHub.
6. Ajouter les deux secrets à l’environnement `pokemap-release`.

Exemple d’injection une fois les deux fichiers préparés :

```bash
gh secret set POKEMAP_WINSPARKLE_EDDSA_PUBLIC_KEY \
  --env pokemap-release < winsparkle-public-key-base64.txt

base64 < winsparkle-private.key | tr -d '\n' | \
  gh secret set WINSPARKLE_PRIVATE_ED_KEY_BASE64 \
    --env pokemap-release
```

Ne pas inventer une commande de génération sans avoir vérifié l’aide de la
version `0.9.4` réellement téléchargée.

### 9.2 Certifier le build et l’installation initiale

- exécuter `windows-release` sur le runner GitHub taggé ;
- vérifier la présence de `PokeMap.exe` et `WinSparkle.dll` ;
- vérifier la compilation Inno Setup ;
- installer le `.exe` sur une machine Windows propre ;
- confirmer une installation par utilisateur sans privilèges administrateur ;
- confirmer le lancement, la désinstallation et la conservation des projets ;
- documenter le comportement SmartScreen.

L’installateur initial n’est pas signé avec Authenticode. La signature EdDSA
protège les updates WinSparkle, mais ne supprime pas l’avertissement possible
« éditeur inconnu » lors du premier téléchargement. Authenticode est une
amélioration future distincte.

### 9.3 Certifier une vraie mise à jour

- installer une version bootstrap, par exemple `0.3.0+300` ;
- publier une version de test `0.3.1+301` dans un environnement contrôlé ;
- déclencher « Vérifier les mises à jour » ;
- vérifier l’affichage de la version et des notes ;
- télécharger et installer avec WinSparkle ;
- confirmer le redémarrage dans la nouvelle version ;
- confirmer qu’une archive altérée est refusée ;
- tester un projet sale et une sauvegarde en cours ;
- tester l’échec réseau et la reprise ;
- tester la désinstallation après update.

## 10. Travail restant pour Linux

Linux est volontairement hors auto-update V1. Le workflow produit actuellement
une archive versionnée :

```text
PokeMap-Editor-X.Y.Z-linux-x64.tar.gz
```

Elle est incluse dans la release et dans `SHA256SUMS`, mais l’utilisateur doit
la télécharger et l’installer manuellement.

Travail de certification minimal :

- construire sur le runner Ubuntu GitHub ;
- extraire l’archive sur une installation propre ;
- confirmer que le binaire `pokemap` est exécutable ;
- lancer l’éditeur et ouvrir un projet réel ;
- vérifier les bibliothèques GTK/GStreamer attendues ;
- vérifier que le message Flutter indique clairement que l’installation
  automatique n’est pas supportée ;
- vérifier le checksum public téléchargé.

Travail futur si un auto-update Linux est décidé :

- choisir un format d’installation stable, probablement AppImage ou paquet
  système ;
- définir une signature et un modèle de confiance spécifiques à Linux ;
- étudier AppImageUpdate/zsync sans réutiliser aveuglément les contrats
  Sparkle ;
- intégrer le desktop file, l’icône, le MIME et la désinstallation ;
- concevoir le rollback et la rotation de clé ;
- ajouter des tests end-to-end sur une distribution supportée.

## 11. Limite critique : travail non sauvegardé

Le redémarrage natif ne doit jamais fermer l’éditeur en perdant silencieusement
un brouillon.

La couverture production actuelle inclut directement :

- la carte ;
- le manifeste du projet ;
- Border Preview ;
- Border Studio ;
- une sauvegarde en cours.

Le registre générique permet à d’autres sessions de déclarer leur état sale,
mais les studios spécialisés suivants ne s’y enregistrent pas encore en
production :

- Narrative Studio ;
- Personalization ;
- Path Studio ;
- Step Studio ;
- Environment Studio ;
- Dialogue Studio ;
- Global Story Studio ;
- Event Builder V2.

Conséquence : une session spécialisée peut potentiellement posséder un brouillon
sale sans bloquer le redémarrage Sparkle ou WinSparkle. Ce point place `UPD-01`
en statut **PARTIAL** et bloque la qualification « production-ready », y compris
sur macOS.

## 12. Matrice des lots

| Lot | Statut proposé | Preuve / manque principal |
|---|---|---|
| UPD-00S | PARTIAL | Harnais natifs propres et cycle deux versions non certifiés |
| UPD-00 | PARTIAL | Contrats en place ; comparaison automatique au build publié précédent absente |
| UPD-01 | PARTIAL | Garde de fermeture présent, couverture des studios spécialisés incomplète |
| UPD-02 | PARTIAL | Détection et tests présents, comportement réseau réel à certifier |
| UPD-03 | PARTIAL | UX implémentée et testée, certification binaire réelle manquante |
| UPD-04 | PARTIAL | Preflight Apple complet vert, archive et feed Sparkle signés ; E2E installé macOS encore à exécuter |
| UPD-05 | BLOCKED | Code présent, secrets et certification Windows manquants |
| UPD-06 | PARTIAL | Pipeline atomique testé par contrat, aucune release taggée complète exécutée |
| UPD-07 | BLOCKED | Bootstrap et boucle réelle `0.3.0 → 0.3.1` non exécutés |
| UPD-08 | DIFFÉRÉ | Linux distribué manuellement, aucun updater Linux |

La roadmap n’est pas modifiée automatiquement par ce document. Ces statuts sont
des propositions fondées sur les preuves fraîches et doivent être promus à
`DONE` seulement après les validations manquantes.

## 13. Validation exécutée

### Tests ciblés après rebase

```bash
cd packages/map_editor
flutter test --no-pub --reporter compact \
  test/features/editor_updates test/release
```

Résultat exact : **86 tests réussis**.

### Analyse statique

```bash
cd packages/map_editor
flutter analyze --no-pub
```

Résultat frais sur `main` : **No issues found (7,4 s)**.

### Workflow et hygiène

Validations exécutées pendant la phase 4 :

```bash
NO_COLOR=1 actionlint .github/workflows/pokemap_desktop_release.yml
python3 -c 'import yaml; yaml.safe_load(open(".github/workflows/pokemap_desktop_release.yml"))'
dart format --output=none --set-exit-if-changed \
  packages/map_editor/tool/release packages/map_editor/test/release
git diff --check
POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh
```

Résultats : actionlint sans diagnostic, YAML parsé, format inchangé, diff sans
erreur et exactement un nouveau Markdown explicitement demandé et accepté par
le garde-fou borné `POKEMAP_MARKDOWN_MAX_NEW=1`.

### Build macOS local

Une preuve fraîche a été obtenue après le rebase :

```bash
cd packages/map_editor
flutter build macos --release --no-pub
```

Résultat exact :

```text
✓ Built build/macos/Build/Products/Release/PokeMap.app (49.9MB)
```

Le build a émis des avertissements tiers Swift/AVFoundation et un avertissement
sur l’AppIcon enfant non assigné. Il est local, non signé et non notarié : il ne
remplace donc pas le preflight GitHub.

### Diagnostic du preflight macOS GitHub

Le run [`30798580518`](https://github.com/yoahnl/pokemap/actions/runs/30798580518)
a été lancé manuellement sans tag ni publication. Ses deux premières tentatives
ont permis de valider l’essentiel du chemin Apple, puis de trouver deux erreurs
de configuration distinctes :

1. la première tentative a signé, notarié, staplé et validé l’application avec
   Gatekeeper, puis a échoué car le secret privé contenait directement le texte
   exporté par Sparkle au lieu de sa couche base64 de transport ;
2. après correction du secret, la seconde tentative a de nouveau validé tout le
   chemin Apple, puis a révélé que l’injection `.xcconfig` conservait des
   guillemets littéraux autour de `SUPublicEDKey` dans le bundle compilé ;
3. le correctif remplace cette injection par une écriture directe dans
   l’`Info.plist` construit, vérifie la valeur et les deux gardes Sparkle, puis
   signe seulement ensuite le bundle.

La reproduction locale du correctif a confirmé une clé publique compilée de
32 octets, une signature `sparkle:edSignature` sur l’archive et un bloc de
signature du feed.

Le run final
[`30800867440`](https://github.com/yoahnl/pokemap/actions/runs/30800867440),
exécuté sur le commit `160ab3256c3defce4a9e67ebfee7a02c3ac16991`,
a ensuite validé en **7 min 33 s** l’intégralité du preflight : import de
l’identité Developer ID, build et signature, notarisation Apple, stapling,
contrôle Gatekeeper, génération de l’archive et du feed Sparkle signés, puis
conservation des preuves. Aucun tag ni aucune release n’a été créé.

### Limites de validation restantes

- aucun build natif Windows ne peut être exécuté sur le Mac local ;
- le build Linux est vert sur le runner Ubuntu, mais son installation et son
  lancement sur une machine propre restent à certifier ;
- une ancienne tentative de suite Flutter complète a rencontré des échecs
  historiques hors chantier (goldens, fixture Selbrume absente et conflits de
  révisions Border). La suite ciblée update/release reste verte ;
- le push `main` a certifié les trois previews et le preflight macOS corrigé est
  vert ; la boucle réelle entre deux versions installées reste une preuve
  distincte.

## 14. Inventaire complet des fichiers du chantier

Chaque groupe ci-dessous partage la même zone et le même impact :

| Groupe | Zones modifiées | Raison | Impact attendu |
|---|---|---|---|
| Workflow et dépendances | CI GitHub, bootstrap Flutter, dépendances Dart | rendre la version unique et orchestrer les plateformes | builds cohérents, previews sûres et releases atomiques |
| Domaine/application/infrastructure | contrats, contrôleur, providers, catalogue et MethodChannels | isoler la politique d’update des frameworks natifs | comportement testable, erreurs typées et URLs contrôlées |
| UI/design system/traductions | shells, commandes, bandeau, FR/EN | exposer une expérience no-code cohérente | vérification manuelle accessible et feedback lisible |
| macOS | projet Xcode, plist, entitlements, bridge Swift | intégrer Sparkle dans le runner sandboxé | téléchargement/install natifs vérifiés sur macOS |
| Windows | CMake, ressources, bridge C++, Inno Setup | intégrer WinSparkle et produire un installateur stable | update Windows possible après certification et secrets |
| Outils de release | générateurs, packagers et validateurs | refuser les métadonnées/assets incohérents | publication fail-closed et preuves reproductibles |
| Tests update/release/UI | tests unitaires, widgets, contrats natifs et workflow | couvrir succès, erreurs, sécurité et non-régression | 86 tests ciblés et contrats de distribution vérifiables |

### Workflow et dépendances

- `.github/workflows/pokemap_desktop_release.yml`
- `packages/map_editor/pubspec.yaml`
- `packages/map_editor/pubspec.lock`
- `packages/map_editor/lib/main.dart`

### Domaine, application et infrastructure Flutter

- `packages/map_editor/lib/src/features/editor/application/editor_unsaved_work_registry.dart`
- `packages/map_editor/lib/src/features/editor_updates/application/editor_exit_readiness_resolver.dart`
- `packages/map_editor/lib/src/features/editor_updates/application/editor_update_controller.dart`
- `packages/map_editor/lib/src/features/editor_updates/application/editor_update_providers.dart`
- `packages/map_editor/lib/src/features/editor_updates/domain/editor_exit_readiness.dart`
- `packages/map_editor/lib/src/features/editor_updates/domain/editor_native_updater.dart`
- `packages/map_editor/lib/src/features/editor_updates/domain/editor_release_version.dart`
- `packages/map_editor/lib/src/features/editor_updates/domain/editor_update_catalog.dart`
- `packages/map_editor/lib/src/features/editor_updates/domain/editor_update_link_opener.dart`
- `packages/map_editor/lib/src/features/editor_updates/domain/editor_update_models.dart`
- `packages/map_editor/lib/src/features/editor_updates/infrastructure/github_release_update_catalog.dart`
- `packages/map_editor/lib/src/features/editor_updates/infrastructure/method_channel_editor_native_updater.dart`
- `packages/map_editor/lib/src/features/editor_updates/infrastructure/method_channel_editor_update_link_opener.dart`
- `packages/map_editor/lib/src/features/editor_updates/infrastructure/package_info_installed_version_reader.dart`
- `packages/map_editor/lib/src/features/editor_updates/presentation/editor_update_banner.dart`
- `packages/map_editor/lib/src/features/editor_updates/presentation/editor_update_host.dart`

### UI, design system et traductions

- `packages/map_editor/lib/l10n/app_en.arb`
- `packages/map_editor/lib/l10n/app_fr.arb`
- `packages/map_editor/lib/l10n/app_localizations.dart`
- `packages/map_editor/lib/l10n/app_localizations_en.dart`
- `packages/map_editor/lib/l10n/app_localizations_fr.dart`
- `packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_toolbelt.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart`
- `packages/map_editor/lib/src/ui/design_system/design_system.dart`
- `packages/map_editor/lib/src/ui/design_system/pokemap_action_banner.dart`
- `packages/map_editor/lib/src/ui/editor_shell_page.dart`
- `packages/map_editor/lib/src/ui/shared/status_bar.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`

### macOS

- `packages/map_editor/macos/.gitignore`
- `packages/map_editor/macos/Flutter/GeneratedPluginRegistrant.swift`
- `packages/map_editor/macos/Runner.xcodeproj/project.pbxproj`
- `packages/map_editor/macos/Runner/AppDelegate.swift`
- `packages/map_editor/macos/Runner/Base.lproj/MainMenu.xib`
- `packages/map_editor/macos/Runner/Configs/AppInfo.xcconfig`
- `packages/map_editor/macos/Runner/DebugProfile.entitlements`
- `packages/map_editor/macos/Runner/EditorUpdaterBridge.swift`
- `packages/map_editor/macos/Runner/Info.plist`
- `packages/map_editor/macos/Runner/MainFlutterWindow.swift`
- `packages/map_editor/macos/Runner/Release.entitlements`

### Windows

- `packages/map_editor/windows/installer/pokemap.iss`
- `packages/map_editor/windows/runner/CMakeLists.txt`
- `packages/map_editor/windows/runner/editor_update_resources.rc.in`
- `packages/map_editor/windows/runner/editor_updater_bridge.cpp`
- `packages/map_editor/windows/runner/editor_updater_bridge.h`
- `packages/map_editor/windows/runner/flutter_window.cpp`
- `packages/map_editor/windows/runner/flutter_window.h`

### Outils de release

- `packages/map_editor/tool/release/generate_update_index.dart`
- `packages/map_editor/tool/release/package_macos_update.sh`
- `packages/map_editor/tool/release/package_windows_update.ps1`
- `packages/map_editor/tool/release/validate_release_version.dart`
- `packages/map_editor/tool/release/validate_update_assets.dart`

### Tests update

- `packages/map_editor/test/features/editor_updates/desktop_update_menu_bridge_contract_test.dart`
- `packages/map_editor/test/features/editor_updates/editor_exit_readiness_provider_test.dart`
- `packages/map_editor/test/features/editor_updates/editor_exit_readiness_test.dart`
- `packages/map_editor/test/features/editor_updates/editor_unsaved_work_registry_test.dart`
- `packages/map_editor/test/features/editor_updates/editor_update_banner_test.dart`
- `packages/map_editor/test/features/editor_updates/editor_update_controller_test.dart`
- `packages/map_editor/test/features/editor_updates/editor_update_host_test.dart`
- `packages/map_editor/test/features/editor_updates/editor_update_manual_commands_test.dart`
- `packages/map_editor/test/features/editor_updates/editor_update_models_test.dart`
- `packages/map_editor/test/features/editor_updates/github_release_update_catalog_test.dart`
- `packages/map_editor/test/features/editor_updates/method_channel_editor_native_updater_test.dart`
- `packages/map_editor/test/features/editor_updates/method_channel_editor_update_link_opener_test.dart`
- `packages/map_editor/test/features/editor_updates/native_update_phase3_contract_test.dart`
- `packages/map_editor/test/features/editor_updates/package_info_installed_version_reader_test.dart`

### Tests release, UI et harnais

- `packages/map_editor/test/release/editor_release_version_cli_test.dart`
- `packages/map_editor/test/release/editor_release_version_contract_test.dart`
- `packages/map_editor/test/release/github_distribution_workflow_test.dart`
- `packages/map_editor/test/release/native_update_packaging_contract_test.dart`
- `packages/map_editor/test/release/update_feed_contract_test.dart`
- `packages/map_editor/test/ui/design_system/pokemap_action_banner_test.dart`
- `packages/map_editor/test/narrative_studio_localization_test.dart`
- `packages/map_editor/test/shell_chrome_test_harness.dart`

## 15. Audit Git et intégration

État initial observé :

- branche feature propre avant rebase ;
- `main` local au commit `11f71230b` ;
- `origin/main` au commit `2f728e1f1` ;
- `main` local possédait déjà 22 commits non poussés par rapport à
  `origin/main` ;
- huit fichiers non suivis préexistants sous `.superpowers/brainstorm/` et
  `skills/.../__pycache__/` appartenaient à d’autres travaux.

Intégration effectuée :

- rebase des quatre commits update sur `main` sans conflit ;
- validation ciblée après rebase ;
- fast-forward de `main` de `11f71230b` vers `7931987dd` ;
- aucun fichier non suivi préexistant ajouté, modifié ou supprimé.

Deux fichiers `Package.resolved` SwiftPM ont été générés par le build macOS dans
le worktree `main`. Ils restent non suivis et sont volontairement exclus du
commit documentaire et du push. Une décision séparée devra déterminer s’ils
doivent être versionnés comme les lockfiles SwiftPM déjà suivis dans
`apps/pokemap_hub`.

État final après les commits de durcissement, de correction et de documentation :

- `main` et `origin/main` sont synchronisés après le push final ;
- aucun changement suivi ne reste dans le worktree ;
- dix fichiers non suivis restent volontairement exclus : huit artefacts
  préexistants `.superpowers`/`__pycache__` et les deux `Package.resolved` ;
- aucun de ces dix fichiers n’est écrasé, supprimé, stagé ou poussé.

## 16. Verdicts des passes indépendantes

- **Audit / Architecture :** architecture saine et mergeable, mais verdict
  « implémenté / à certifier » à cause de la couverture dirty-state incomplète,
  de la monotonie inter-release non automatisée et de l’absence d’E2E réel.
- **Implémentation :** quatre phases isolées en commits, rebasées sans conflit et
  fusionnées en fast-forward sur `main`.
- **Tests :** contrats positifs, négatifs, sécurité, UI et publication couverts ;
  suite ciblée de 86 tests verte après rebase et durcissement final.
- **Build / Validation :** analyse, scripts natifs, build macOS Release local et
  previews GitHub macOS/Windows/Linux verts ; preflight final macOS entièrement
  vert, y compris signature, notarisation, Gatekeeper, archive et feed Sparkle
  signés.
- **Documentation :** un document consolidé dans le dossier explicitement
  demandé, sans multiplier les rapports Markdown.
- **Critique finale :** la qualification production doit rester refusée tant que
  les studios spécialisés ne participent pas tous au garde de redémarrage et
  qu’un cycle signé entre deux versions n’a pas été exécuté.

## 17. Prochain ordre de travail recommandé

1. Raccorder tous les studios spécialisés au registre de travail non sauvegardé.
2. Automatiser la comparaison du build number avec la dernière release stable.
3. Certifier le cycle complet `0.3.0 → 0.3.1` sur un Mac propre.
4. Quand Windows redevient disponible, générer et sauvegarder sa paire EdDSA.
5. Ajouter les deux secrets Windows et certifier l’installation initiale.
6. Certifier le cycle complet `0.3.0 → 0.3.1` sur un PC Windows propre.
7. Pousser un tag stable seulement après ces preuves.
8. Conserver Linux en téléchargement manuel jusqu’à une décision produit
   explicite sur son format d’installation et son mécanisme d’update.
