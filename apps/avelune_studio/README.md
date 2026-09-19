# Avelune Studio — AS-ARC-002

Application desktop indépendante : ouvrir un dossier de projet PokeMap, lire son
nom dans `project.json`, puis fermer sa session. Tous les accès au projet sont
en lecture seule. Aucun canevas, édition, sauvegarde, runtime ou export à ce stade.

## Prérequis et lancement

macOS, Xcode et Flutter avec desktop macOS activé. Le lot a été vérifié avec
Flutter **3.48.0-0.4.pre**, Dart embarqué **3.14.0-95.2.beta**, macOS arm64.
Utiliser le Dart du même SDK Flutter pour les outils Dart ; le Dart autonome
installé sur la machine de validation était différent. Les plugins Apple utilisent
Swift Package Manager, sans CocoaPods.

Depuis la racine du dépôt :

```sh
cd apps/avelune_studio
flutter pub get
flutter run -d macos --no-pub
```

Choisir **Parcourir** et le dossier contenant `project.json`. Le sélecteur macOS
accorde sa lecture dans le sandbox. Un chemin saisi manuellement peut nécessiter
une sélection préalable. Le nom affiché provient du manifeste, jamais du nom du
dossier. **Fermer le projet** libère la session et revient à l’accueil.

Pour créer un exemple isolé avec le codec existant :

```sh
dart run tool/create_example_project.dart
```

Le chemin temporaire est imprimé. Un argument permet de choisir un nouveau dossier ;
le générateur refuse toute cible existante. Cette création explicite d’exemple est
un outil de vérification, distinct de l’application en lecture seule.

## Vérifications

Depuis ce même dossier, chaque label doit être inédit pour conserver les preuves :

```sh
python3 tool/run_check.py analyze-local -- flutter analyze --no-pub
python3 tool/run_check.py --reap-tests tests-local -- flutter test --no-pub
python3 tool/run_check.py build-local -- flutter build macos --debug --no-pub
```

Le runner conserve sortie originale, code retour et processus descendants sous
`documentation/reports/avelune_studio/AS-ARC-002/evidence/`. Il ne termine que les
harnesses de tests dont il a suivi et revérifié l’identité.

Les tests de frontières parcourent les imports/exports/parts locaux et `package:` ;
ils constituent un garde ciblé, pas un analyseur Dart universel.
La fermeture invalide les lectures en cours ; leur résultat tardif est libéré
sans rouvrir l’écran. Aucun timer, watcher ou rechargement sur rebuild.

Le manifeste suffit pour cette identité : les cartes, assets et la jouabilité ne
sont pas validés. Certaines erreurs de permissions sont regroupées en erreur de
lecture par l’API existante. Aucun benchmark ni support multiplateforme certifié.

AS-ARC-002-bis conserve exactement le chemin saisi ou sélectionné. Si ce chemin,
ou sa racine résolue après un lien symbolique, serait altéré par le nettoyage du
lecteur partagé, l’ouverture est refusée avant tout accès au manifeste. Cela inclut
un nom de dossier terminé par un espace, même suivi d’un séparateur. Les espaces
internes, accents et liens vers une racine sûre restent acceptés. C’est un refus
explicite local, pas le support complet de ces noms ni une correction du lecteur
partagé. Le texte saisi reste disponible pour correction.

Voir le [rapport et les preuves natives](../../documentation/reports/avelune_studio/AS-ARC-002/README.md).
