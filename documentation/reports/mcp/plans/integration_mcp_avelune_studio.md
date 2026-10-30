# Intégration du MCP à Avelune Studio et lancement headless — plan distinct

> **Pour l’agent exécutant :** appliquer `skills/executing-plans/SKILL.md`, ou `skills/subagent-driven-development/SKILL.md` si une exécution déléguée est retenue. Ce plan est différé après le chantier prioritaire de fiabilisation ; ses cases décrivent du travail non réalisé.

**Objectif :** fournir le MCP avec Avelune Studio, le démarrer automatiquement à l’ouverture de l’application et conserver son lancement autonome headless, avec les mêmes capacités métier.

**Architecture :** conserver `tools/pokemap_mcp`, les API canoniques Dart, les nouveautés de Claude et les améliorations du [premier plan](fiabilite_creation_cartes_mcp_v2.md). Studio fournit et supervise un compagnon ; les deux modes de lancement utilisent le même serveur et les mêmes gateways. Aucune réécriture du MCP en Dart ni refonte générale des contrôleurs, brouillons ou historiques de Studio.

**Technologies :** Flutter/Dart Studio, MCP TypeScript/Node, workers Dart/Flutter, SDK MCP existant, distribution desktop signée.

**Date et référence :** 30 octobre 2026, `main` au SHA `67b5fd0d6853e7c253d176f3c5f9d524bb3164fe` et worktree partagé modifié. Vérifier l’état réel à l’ouverture du chantier. Aucun lot I0–I5 n’est implémenté par la rédaction de ce document.

---

## 1. Décisions utilisateur et périmètre

Deux chantiers distincts : améliorer d’abord le MCP, puis l’intégrer à Studio. L’intégration ne doit pas déplacer les corrections de fiabilité dans le packaging ni devenir un prérequis de leur exécution.

| Mode | Comportement cible |
| --- | --- |
| Studio ouvert | Service automatiquement démarré, composants fournis, connexion client accessible depuis Studio |
| Studio fermé | Lancement MCP headless toujours disponible, avec comportement `stdio` existant conservé |
| Studio et headless simultanés | Instances et enfants possédés séparément, préconditions/conflits canoniques conservés, aucun arrêt de l’autre instance |

« Intégré » signifie distribué, démarré et supervisé par l’application. Un processus compagnon embarqué convient. L’intégration ne justifie pas de supprimer les commandes avancées, les diagnostics, rendus/scans, profils, capacités headless ou contrôles de racines.

Le mode installé doit fonctionner sans checkout du dépôt et sans Node, Dart ou Flutter préinstallés par l’utilisateur. Aucune génération de projet, compilation à la volée ou installation silencieuse de dépendances pendant son démarrage normal.

Hors périmètre : nouvelle API métier concurrente, moteur transactionnel alternatif, assistant IA hébergé dans Studio, modèle LLM fourni, abonnement cloud, réécriture de l’éditeur, nouveau format de jeu/sauvegarde, promesse de toutes les capacités natives sur des plateformes qui ne les supportent pas aujourd’hui.

## 2. Audit initial et contraintes concrètes

| Source actuelle | Observation | Travail nécessaire |
| --- | --- | --- |
| `tools/pokemap_mcp/src/index.ts` | Point d’entrée `stdio` | Le lancer en enfant de Studio ne crée pas une adresse de connexion pour un client externe |
| `tools/pokemap_mcp/src/server.ts` | Fabrique commune de serveur/outils | Réutiliser pour les deux transports ; aucun catalogue bis |
| `tools/pokemap_mcp/src/authoring_client.ts` | Worker lancé depuis les sources via Dart | Ajouter résolution d’un worker embarqué précompilé |
| `tools/pokemap_mcp/src/runtime_gateway.ts` | Certains rendus utilisent `flutter test` | Fournir un hôte de production équivalent, conserver l’adaptateur de développement |
| `tools/pokemap_mcp/src/native_render_host.ts` | Hôte Flutter potentiellement construit à la demande | Embarquer le binaire/les ressources préconstruits sur plateformes supportées |
| `tools/pokemap_mcp/src/config.ts` | Racines explicites nécessaires | Service prêt sans projet à l’accueil, aucune autorisation large implicite |
| `apps/avelune_studio/lib/app/studio_app.dart` | `initState`, gestion de fermeture, `_prepareForUpdate`, `dispose` | Propriétaire du cycle de vie, via un service dédié injecté |
| `apps/avelune_studio/lib/app/studio_bootstrap.dart` | Initialisation Studio | Résolution des composants distribués et injection du superviseur |
| `apps/avelune_studio/lib/features/map_workspace/data/local_map_workspace_working_catalog.dart` | Studio utilise les API locales canoniques | Préserver ces chemins ; coordination ciblée des ressources modifiées |
| `apps/avelune_studio/macos/Runner/Release.entitlements` | Sandbox, accès client réseau ; écoute serveur à vérifier | Recette sur bundle signé, pas seulement `flutter run` |
| `tools/avelune_mcp` | Contrôle Hub/Player distinct | Ne pas le confondre avec le MCP d’authoring Studio |

Une copie du JavaScript Node ne suffit donc pas à livrer le produit intégré. Les dépendances d’exécution et de rendu doivent être inventoriées puis fournies ou remplacées par leur équivalent de production au niveau du lanceur, sans changer les règles métier.

## 3. Règles d’exécution

- Lire les règles du dépôt et celles des dossiers touchés ; aucune opération Git en écriture sans autorisation explicite. Préserver les hunks concurrentes, y compris dans les mêmes chemins.
- Réutiliser le contexte Notion existant de la revue, domaine « Systèmes transverses », jusqu’à ce qu’un ticket de livraison existant plus précis soit identifié. Ne pas créer de nouveau grand domaine. Synchroniser les preuves ; fin en `TO REVIEW`.
- Préserver formats et données protégés. Travailler uniquement sur fixtures, sans écriture dans HeartGold ou des sauvegardes utilisateur.
- Racine QA unique : `/Users/karim/Library/Caches/AveluneQA/mcp-studio-integration/`. Déclarer chemins, PID, but et condition de suppression avant les runs ; supprimer les environnements possédés, conserver les seules preuves compactes.
- Identifier les processus par ownership et descendants suivis ; jamais tuer par nom, par numéro de port seul ou par simple ancienneté.
- Les tests Flutter appliquent le suivi du runner et de ses descendants. Les certifications d’installation et les parcours lourds restent locaux et opt-in ; aucun nouveau runner macOS coûteux en CI sans demande.
- Aucun nouveau Markdown pendant l’exécution par défaut. Mettre à jour les deux plans existants si nécessaire, résultats en chat et suivi existant.

## 4. I0 — Contrat de distribution et service disponible sans projet

**Modifier :** `tools/pokemap_mcp/src/config.ts`, `authoring_client.ts`, `runtime_gateway.ts`, `native_render_host.ts`, `index.ts`, et les tests de configuration/lancement existants.

**Créer :** `tools/pokemap_mcp/src/packaged_runtime.ts`, `tools/pokemap_mcp/test/packaged_runtime.test.ts`, `tools/pokemap_mcp/test/service_bootstrap.test.ts`.

- [ ] Inventorier chaque capacité du serveur livré après le chantier 1 : exécutable, ressources, architecture CPU et plateformes. Placer cette table dans le manifeste de distribution lisible par le code, pas dans un troisième document.
- [ ] Définir un mode développement qui conserve les lancements actuels et un mode installé qui utilise exclusivement les exécutables/ressources embarqués.
- [ ] Précompiler le worker d’authoring Dart ; fournir le runtime Node et les dépendances du serveur selon les contraintes de signature/distribution ; remplacer les lancements `flutter test` de production par un worker/hôte distribué conservant le même contrat.
- [ ] Résoudre les chemins depuis le bundle installé, indépendamment du répertoire courant, du checkout et du `PATH` système. Tester espaces et caractères Unicode.
- [ ] Permettre le démarrage de la couche de service avant tout projet ouvert. Sans racine autorisée, découverte et état sont disponibles ; accès aux projets/mutations refusé explicitement. Ne pas contourner les exigences actuelles en autorisant le home ou tout `~/Project`.
- [ ] Tester les composants absents/incompatibles : état exploitable, aucune installation ou compilation silencieuse, aucune disparition silencieuse de capacités précédemment disponibles.

**Acceptation :** depuis un assemblage minimal hors checkout avec un `PATH` contrôlé sans SDK utilisateur : initialisation, liste d’outils, découverte, ouverture autorisée d’une fixture, requête, plan/apply et vérification fonctionnent. Les rendus/scans supportés disposent d’un chemin de production prouvé ; une capacité encore dépendante du checkout laisse le lot partiel.

## 5. I1 — Connexion attachable, même serveur et headless inchangé

**Créer :** `tools/pokemap_mcp/src/http_transport.ts`, `server_runtime.ts` dans le même dossier, `tools/pokemap_mcp/test/http_transport.test.ts`, `server_runtime.test.ts`.

**Modifier :** `index.ts`, `config.ts`, `server.ts`, `test/config.test.ts`, `test/protocol_compatibility.test.ts`.

Choix proposé : transport MCP Streamable HTTP sur loopback pour le compagnon Studio, en utilisant les primitives du SDK installé. Valider leur disponibilité en premier ; si une mise à jour de dépendance est nécessaire, isoler sa compatibilité avant le transport. Conserver `stdio` comme défaut CLI autonome. Aucun protocole MCP maison.

- [ ] Factoriser la construction du serveur et des gateways ; `stdio` et HTTP instancient exactement cette fabrique et les profils du chantier 1.
- [ ] Ajouter le choix explicite de transport ; le lancement actuel sans cette option garde son comportement.
- [ ] Limiter l’écoute au loopback, avec authentification locale et contrôles de requêtes adaptés au transport. Ne pas exposer les projets au réseau local par défaut ; ne pas écrire de secrets dans les logs ou reçus.
- [ ] Définir la propriété des sessions, handles et workers, l’isolation de deux clients et leur fermeture. Un catalogue identique ne suffit pas à prouver l’isolation des sessions.
- [ ] Publier l’état prêt seulement après une vraie initialisation et l’écoute effective. Utiliser un canal parent/enfant structuré pour transmettre endpoint et état au Studio.
- [ ] Prévoir port occupé, arrêt pendant initialisation, client déconnecté et fin de session sans fuite de worker. La disponibilité de connexion ne vaut pas succès d’une mutation.
- [ ] Vérifier avec le SDK client réel `initialize`, `listTools`, `describe`, query, edit/check et récupération de résultat ; mêmes contrats qu’en headless.

**Acceptation :** client externe réellement connecté au compagnon, outils du chantier 1 utilisables, `stdio` non régressé, fermeture de session libérant ses ressources sans toucher à l’autre client.

**Validation prévue :** depuis `tools/pokemap_mcp`, `npm run check`, `node --import tsx --test test/http_transport.test.ts test/server_runtime.test.ts test/config.test.ts test/protocol_compatibility.test.ts`, puis `npm run build`.

## 6. I2 — Démarrage et arrêt automatiques dans Studio

**Créer :**

- `apps/avelune_studio/lib/platform/mcp/studio_mcp_service.dart` : état et orchestration du service.
- `apps/avelune_studio/lib/platform/mcp/studio_mcp_process.dart` : lancement/arrêt et ownership des enfants.
- `apps/avelune_studio/lib/app/di/studio_mcp_providers.dart` : injection/test doubles.
- `apps/avelune_studio/test/platform/mcp/studio_mcp_service_test.dart` : cycle de vie avec faux processus.

**Modifier :** `lib/app/studio_app.dart`, `studio_bootstrap.dart` et points de composition DI ; étendre les tests `test/presentation/studio_app_test.dart`, `test/app/provider_lifecycle_test.dart`, `test/app/studio_bootstrap_test.dart` quand concernés.

États : `starting`, `ready`, `failed`, `stopping`, `stopped`. Le superviseur garde l’identité de ses enfants, pas un nom d’exécutable à tuer.

- [ ] Démarrer automatiquement une fois lors de l’ouverture de Studio, sans bloquer le premier affichage. Un rebuild ou changement de carte ne relance rien.
- [ ] Signaler l’état prêt seulement après le handshake du vrai service ; un PID vivant ne suffit pas.
- [ ] Arrêter normalement les enfants possédés lors d’une fermeture acceptée ou de la préparation de mise à jour ; terminer de force uniquement un descendant confirmé bloqué après délai.
- [ ] Préserver le service lorsqu’une fermeture est annulée par la protection des modifications.
- [ ] Gérer démarrage échoué et crash avec état visible et nouvelle tentative bornée ; ne pas bloquer l’usage normal de Studio ni entrer dans une boucle de respawn.
- [ ] Séparer instances Studio et headless. Ne pas adopter ou tuer un service existant sur le seul fait qu’il occupe un port attendu.

**Acceptation :** ouverture à l’accueil sans projet → service prêt ; fermeture annulée → même service ; fermeture acceptée → aucun descendant possédé restant ; instance headless parallèle intacte. Tester également relance de Studio et arrêt pour mise à jour.

## 7. I3 — Racines autorisées et cohérence avec le projet ouvert

**Modifier de façon ciblée :** propriétaires d’ouverture/fermeture dans `apps/avelune_studio/lib/features/project_session/`, `lib/features/map_workspace/data/local_map_workspace_adapter.dart`, `local_map_workspace_working_catalog.dart`, et contrats de notification du compagnon.

**Créer :** `apps/avelune_studio/test/platform/mcp/studio_mcp_project_coordination_test.dart`, `tools/pokemap_mcp/test/studio_companion_session.test.ts`.

Le projet ouvert peut fournir une racine étroite autorisée au service. Cela ne signifie pas partager arbitrairement les contrôleurs Flutter ou refondre les brouillons ; garder les API canoniques et les conflits de révision.

- [ ] Accorder/révoquer une autorisation de projet via le canal Studio/service, en respectant les accès natifs et le choix utilisateur d’ouverture. Pas de racine filesystem globale.
- [ ] Définir le comportement au changement/fermeture du projet : nouvelles requêtes refusées ou dirigées explicitement vers la bonne session. Les opérations déjà durables restent retrouvables par leur identité après réouverture autorisée ; leur consultation exige toujours une autorisation et un handle valides. La révocation n’accorde aucun accès résiduel aux fichiers.
- [ ] Après une mutation externe, notifier seulement IDs de ressources touchées et révision durable. Invalider/recharger localement les données concernées, sans recharger le projet entier.
- [ ] Préserver les brouillons humains non enregistrés. En cas de conflit sur le même document, conserver les données et produire un conflit explicite ; aucune écriture forcée ni perte silencieuse.
- [ ] Examiner l’historique existant et documenter le comportement d’undo avant de promettre un historique unique UI/MCP. Ajouter une coordination minimale uniquement si nécessaire pour empêcher une action trompeuse.
- [ ] Instrumenter la notification jusqu’à l’aperçu sur un projet représentatif : retour visible ≤ 100 ms et persistance ≤ 500 ms pour une édition simple, première et répétées séparées. Si non prouvé, statut partiel, pas de certification implicite.

**Acceptation :** deux cartes, mutation de l’une visible dans Studio sans invalidation de l’autre ; donnée correcte après réouverture ; brouillon concurrent préservé ; projet changé pendant requête et écriture headless concurrente sans écrasement.

## 8. I4 — Packaging desktop, signature et connexion utilisateur

**Modifier selon les plateformes réellement distribuées :**

- `.github/workflows/pokemap_desktop_release.yml` uniquement pour assembler les composants requis et tests rapides.
- `tools/release/sign_macos_app.sh`.
- `apps/avelune_studio/tool/release/package_linux_release.sh`.
- `apps/avelune_studio/tool/release/package_windows_manual_release.ps1`.
- `packages/map_editor/tool/release/package_macos_preview.sh`, `package_macos_update.sh` si ces chemins participent réellement à la distribution Studio courante.
- `apps/avelune_studio/macos/Runner/Release.entitlements`, `DebugProfile.entitlements` pour les capacités strictement nécessaires et validées.

**Créer :** `apps/avelune_studio/lib/presentation/features/settings/studio_mcp_connection_panel.dart`, `apps/avelune_studio/test/presentation/studio_mcp_connection_panel_test.dart` ; intégrer au propriétaire réel des réglages après lecture de ses conventions.

- [ ] Produire un manifeste vérifiable des exécutables/ressources embarqués, architectures et licences ; aucun chemin absolu du poste de développement.
- [ ] Signer les helpers avant le bundle final macOS et vérifier les entitlements de l’écoute locale et de l’accès aux projets depuis le compagnon. Le succès en debug ne remplace pas un essai du bundle signé sandboxé.
- [ ] Contrôler les packages Windows/Linux, chemins avec espaces, lancement sans shell utilisateur et remontée d’erreur d’un composant manquant.
- [ ] Afficher dans Studio état, action de reprise et configuration de connexion copiable. Utiliser le design system et ses tokens, sans détails techniques inutiles dans le parcours normal.
- [ ] Préserver le démarrage automatique ; aucune configuration de serveur supplémentaire à construire à la main pour obtenir le service fourni. Les clients externes conservent leur propre étape de connexion.
- [ ] Ne pas modifier automatiquement les fichiers de configuration de Codex/Claude ni y injecter des accès sans demande.
- [ ] Fournir également une entrée headless utilisant les mêmes composants distribués ; conserver la commande de développement actuelle comme chemin compatible.

**Acceptation :** installation réelle sans checkout/SDK, connexion depuis un client MCP et capacités du chantier 1 fonctionnelles sur les plateformes supportées. Mise à jour du bundle conservant projets, jeux, sauvegardes et configuration utilisateur valide. Les signatures et l’accès aux racines autorisées sont vérifiés sur le produit installé.

## 9. I5 — Qualification de sortie et nettoyage

- [ ] Installer le bundle de test dans l’environnement QA possédé, hors dépôt, avec `PATH` sans SDK système.
- [ ] Ouvrir Studio : MCP automatiquement prêt à l’accueil, sans projet ni autorisation large.
- [ ] Connecter un vrai client ; comparer capacités/profils aux résultats headless du chantier 1.
- [ ] Ouvrir une fixture autorisée ; créer/éditer une carte et utiliser batch, reprise du reçu, contrôle et rendu supporté.
- [ ] Observer le changement localement dans Studio et vérifier les octets/valeurs après réouverture.
- [ ] Tester brouillon humain concurrent, projet changé, réponse perdue, crash du compagnon et reprise récupérable.
- [ ] Annuler une fermeture de Studio puis fermer réellement ; vérifier respectivement conservation puis arrêt de ses seuls enfants.
- [ ] Lancer headless Studio fermé : mêmes capacités ; tester coexistence et isolation des arrêts.
- [ ] Vérifier le chemin de mise à jour, le bundle signé et les limites natives spécifiques aux plateformes.
- [ ] Relever ouverture de Studio, disponibilité MCP, premier edit et répétitions, lectures/écritures et invalidations locales ; ne pas déduire ces résultats d’un test à faux processus.
- [ ] Arrêter les seuls consommateurs possédés, supprimer copies/builds/environnements QA jetables et vérifier les chemins supprimés ; conserver résultats compacts et captures finales utiles.

Les tests de package rapides restent dans les suites existantes. Les parcours d’installation, signature et rendu natif lourds sont des checks locaux explicites. Aucune publication, release, signature avec nouveau certificat ou modification Git n’est autorisée par le seul présent plan.

## 10. Preuves et verdicts attendus

Pour chaque lot : fichiers/hunks concernés, Git d’entrée/sortie, commandes exactes et résultats, tests de contrats et de cycle de vie, limites de plateforme, mesures première/répétées, processus possédés/nettoyés, critique indépendante. Une capacité non distribuée ou un accès sandbox non vérifié laisse la livraison `PARTIAL`.

La certification finale distingue : tests unitaires, client MCP réel, bundle installé, accès natif signé, performance mesurée et headless. Fin de livraison en `TO REVIEW`, jamais `DONE` sans décision de Yoahn.

La rédaction seule n’exécute aucun de ces essais. L’ordre convenu reste : fiabilisation MCP d’abord, intégration Studio ensuite.
