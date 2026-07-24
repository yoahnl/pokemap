# GameSessionPort v1

## But

Fournir au Hub un contrat identique pour une session in-process ou enfant. Le
port ne transporte ni widget, ni composant Flame, ni path arbitraire.

## Descriptor de lancement

Le Hub crée un descriptor immuable :

- `protocolVersion: 1` ;
- `sessionId` et `sessionToken` opaques et non réutilisables ;
- `gameId`, `gameVersion`, `contentTreeHash` ;
- `profileId`, `slotId`, `launchMode` (`newGame`, `continue`, `load`) ;
- handle de version installée résolu par l’adaptateur ;
- `runtimeApi`, capabilities accordées, locale et options d’accessibilité ;
- handle de save en lecture, jamais un chemin fourni par le jeu.

## États

```text
idle → preparing → prepared → starting → loading → running ↔ paused
                                                ↘ completing → completed
starting | loading | running | paused ↔ lifecyclePaused(resumeState)
any non-terminal → failed
starting | loading | running | paused | completed | failed
  → stopping → disposed(exitReason)
```

Une transition inconnue, en retard ou issue d’un autre `sessionId` est rejetée.

## Commandes Hub → session

| Commande | États autorisés | Résultat |
|---|---|---|
| `start` | prepared | lance handshake et chargement |
| `pauseForLifecycle` | starting/loading/running/paused | suspend et mémorise `resumeState` |
| `resumeFromLifecycle` | lifecyclePaused | revient exactement à `resumeState` |
| `requestCheckpoint` | running/paused/completing | état métier renvoyé au Hub |
| `returnToTitle` | running/paused/completed/failed | checkpoint selon politique puis arrêt avec raison `title` |
| `returnToHub` | starting/loading/running/paused/completed/failed | checkpoint selon politique puis arrêt avec raison `hub` |
| `cancelLoading` | starting/loading | annulation puis teardown |
| `terminate` | tout état non terminal | arrêt gracieux |

Chaque commande porte `protocolVersion`, `sessionId`, `sequence` monotone et
`requestId`. Elle reçoit un ack idempotent ou une erreur typée.

## Événements session → Hub

- `ready`, `loadingProgress(stage, current, total?)`, `running`, `paused` ;
- `checkpointProposed(payload, metadata)` ; le Hub répond accepted/rejected ;
- `gameCompleted(resultSummary, checkpoint)` ;
- `returnRequested(reason)` ;
- `heartbeat(monotonicMillis)` ;
- `diagnostic(code, severity, safeDetails)` ;
- `fatal(code, recoverability)` ;
- `disposed(exitReason: title|hub|cancelled|failed|terminated)`.

Les payloads sont bornés et validés. Les logs, stacks ou secrets ne transitent
pas dans `safeDetails`.

## Timeouts et backpressure

- `ready` sous 30 s ;
- heartbeat toutes les 2 s, stale à 10 s ;
- une seule proposition de checkpoint en vol ;
- checkpoint borné par la politique save ; timeout UI explicite à 15 s, sans
  abandonner automatiquement la dernière save valide ;
- arrêt gracieux 5 s ;
- files de messages bornées ; un producteur trop rapide reçoit `busy`.

## Garanties

- une session n’écrit pas la bibliothèque, `current.json` ou les saves ;
- le Hub persiste seulement un `SaveEnvelope` validé ;
- le teardown complet précède le prochain lancement ;
- `GameCompleted` verrouille le gameplay avant le checkpoint final ;
- la topologie n’est jamais observable par l’UI joueur.

L’écran titre appartient au shell joueur, hors du port de gameplay. Une sortie
`disposed(exitReason=title)` déclenche la transition produit vers `playerTitle`.
Relancer depuis ce titre crée un nouveau descriptor et un nouveau `sessionId`.
`contentTreeHash` est l’alias transport exact de `content.treeSha256` du
manifeste ; aucune recanonicalisation n’est autorisée.

## Tests futurs

Tests table-driven de transitions, séquences dupliquées, mauvais token, timeout,
heartbeat perdu, checkpoint rejeté, completion, double session et teardown
jeu A → jeu B pour les deux adaptateurs.
