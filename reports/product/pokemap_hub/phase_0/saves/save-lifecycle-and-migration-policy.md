# Saves — lifecycle et migrations v1

## Objectif, périmètre et ownership

HUB-003/Phase 2 remplace la save globale par des enveloppes isolées. Le contrat
et son codec appartiennent à `map_core`; le repository filesystem, les profils,
slots et politiques plateforme appartiennent au Hub. `map_runtime` propose un
état métier mais n’écrit jamais directement Application Support.

```text
Application Support/PokeMap/
├── games/
├── saves/<gameId>/<profileId>/<slotId>/
│   ├── save.json
│   └── save.backup.json
├── cache/<gameId>/<gameVersion>/<treeSha256>/
├── logs/
└── library.json
```

Chaque identifiant est validé avant composition du path et la résolution finale
doit rester sous la racine attendue. Les saves ne vivent jamais sous une version
installée.

## `SaveEnvelope`

[`save-envelope-v1.schema.json`](save-envelope-v1.schema.json) contient
l’identité game/profile/slot/save, les dates UTC, versions jeu/projet/save,
`compatibilityId`, statut, temps de jeu, état métier et checksum.

`schemaVersion` versionne l’enveloppe ; `saveFormat` versionne l’état métier
générique. Le checksum est :

```text
SHA256(UTF8(JCS(envelope sans la propriété checksum)))
```

La taille maximale de `save.json` est 64 MiB. Le repository vérifie schéma,
identités attendues, ordre temporel (`createdAt <= updatedAt`), checksum et
compatibilité avant exposition.

## Écriture atomique

Sous verrou exclusif du triplet game/profile/slot :

1. sérialiser l’enveloppe dans `save.json.tmp.<nonce>` sous la même racine ;
2. flush du fichier puis, si supporté, du répertoire ;
3. relire la temporaire, parser, valider le schéma et recalculer le checksum ;
4. déplacer l’ancien `save.json` valide vers `save.backup.json.next`, puis
   promouvoir atomiquement ce backup ;
5. renommer atomiquement la temporaire en `save.json` ;
6. relire le courant et confirmer ;
7. si une étape échoue, restaurer l’ancien courant/backup et conserver le
   diagnostic ; ne jamais promouvoir la temporaire invalide.

Les locks périmés sont récupérés après vérification du PID/session et des
temporaires. Une seule écriture par slot est autorisée ; les lectures observent
soit l’ancienne, soit la nouvelle version complète.

## Lecture et récupération

Ordre : `save.json`, puis `save.backup.json`. Une save corrompue est mise en
quarantaine par copie/move récupérable, jamais silencieusement supprimée. Si le
backup est choisi, l’UI informe le joueur avant de le promouvoir. Une save
future/incompatible reste listée avec son diagnostic.

## Profils, slots et actions

- un profil possède un ID local stable et un nom d’affichage séparé ;
- un slot possède un ID stable et des métadonnées dérivées de l’enveloppe ;
- **Continuer** choisit la save valide et compatible la plus récemment mise à
  jour dans le profil actif ; l’accueil Hub peut reprendre la plus récente
  globalement ;
- **Charger** liste les slots et leurs états ;
- **Nouvelle partie** cible un slot vide ; écraser exige confirmation et backup ;
- une save `completed` reste chargeable si le jeu l’autorise, sinon consultable.

## Lifecycle

Passage arrière-plan : suspendre input/horloges, demander un checkpoint borné,
persister s’il est valide, puis ack lifecycle. Sur délai OS trop court, la save
précédente reste valide. Retour foreground : revalider la session/version et
reprendre. Quitter au titre/Hub attend commit ou décision explicite d’abandon.

## Migrations

1. valider et copier source + backup ;
2. exécuter chaque migration moteur sur une copie ;
3. attribuer un nouveau `saveId`, garder `createdAt`, avancer `updatedAt` ;
4. recalculer checksum et valider contre la cible ;
5. conserver un snapshot pré-migration lié à la version précédente ;
6. promouvoir atomiquement seulement après succès.

Aucun script de package ne peut migrer une save. Un `compatibilityId` différent
bloque le chargement. Un rollback restaure le snapshot pré-update au lieu
d’ouvrir une save réécrite par une version plus récente.

## Save globale historique

`<ApplicationSupport>/pokemonProject/game_save.json` n’est jamais associée
automatiquement. Un assistant explicite exige :

1. sélection d’un jeu installé, profil et slot ;
2. lecture/validation du format historique ;
3. aperçu des métadonnées et confirmation ;
4. import par copie dans une enveloppe avec `origin.kind =
   legacy-global-save` ;
5. conservation du fichier historique inchangé.

En cas d’identité ou compatibilité indémontrable, l’import est refusé avec
export diagnostic ; aucune heuristique basée sur le titre/dossier n’est permise.

## Uninstall, repair et cache

Uninstall préserve les saves par défaut et propose une suppression séparée,
explicite et destructive. Repair ne touche pas aux saves. Caches, index et
catalogues dérivés sont scoppés par game/version/tree hash et peuvent être
supprimés sans perte.

## Tests, DONE et risques

Tests futurs : isolation interjeu, chemins, checksum, écriture/kill à chaque
étape, disque plein, recovery backup, concurrence, lifecycle, migration succès/
échec, future save, rollback et import legacy. DONE exige qu’aucun scénario ne
perde la dernière save valide. Risques : sémantique de rename/fsync différente
par OS et taille des états ; des adaptateurs plateforme et kill tests sont
obligatoires.
