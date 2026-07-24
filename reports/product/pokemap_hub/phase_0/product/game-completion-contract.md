# Contrat de fin de jeu v1

## Commande auteur

L’Event Builder expose une commande no-code **Terminer le jeu** :

- résultat (`completed`, `victory`, `alternateEnding`) ;
- `endingId` stable ;
- résumé/localisation déclaratifs ;
- séquence de crédits déclarative ;
- destination autorisée après crédits (`title`, `hub`, `playerChoice`) ;
- option `allowPostGameContinue`.

Aucun script ou widget personnalisé. La validation éditeur exige crédits et
destination valides.

## Événement runtime

Le runtime émet une fois :

```text
GameCompleted {
  eventVersion: 1,
  sessionId,
  gameId,
  endingId,
  outcome,
  completedAt,
  playTimeSeconds,
  resultSummary,
  finalCheckpoint
}
```

L’événement est idempotent par `(sessionId, endingId)`. À sa création :

1. verrouiller mouvement, interactions, combats et nouvelles commandes ;
2. terminer/annuler proprement les transitions autorisées ;
3. proposer le checkpoint final au Hub ;
4. attendre commit ou erreur explicite ;
5. seulement après commit, publier `completed`.

## Save complétée

Le Hub construit une `SaveEnvelope` avec `status=completed` et `completedAt`.
L’ancienne save reste valide tant que le commit n’a pas réussi. Si le stockage
échoue, le joueur peut réessayer, libérer de l’espace ou quitter en conservant
la save précédente ; l’UI ne prétend pas que la progression est enregistrée.

## Résultat et crédits

Le résultat utilise un snapshot canonique, puis les crédits affichent au
minimum titre, auteur, contributeurs, licences et ending. Tous les contenus
sont localisables, scrollables, compatibles text scaling/reduced motion et
skippables selon la policy du jeu. La musique/illustration est déclarative et
résolue dans le package.

Après crédits :

- `title` décharge le monde et revient à l’écran titre de la même session ;
- `hub` effectue le teardown complet puis retourne au détail/accueil ;
- `playerChoice` propose les deux ;
- post-game charge la save completed seulement si capability/policy l’autorise.

## Erreurs et idempotence

Un deuxième événement est ignoré et journalisé. Un événement pour un autre
gameId/session est fatal au contrat. Un crash avant commit laisse la save
active précédente ; après commit, la completed est récupérable même si
l’écran résultat n’a pas été vu.

## Ownership et futurs fichiers

La commande/modèle auteur est partagée via `map_core` et exposée par
`map_editor`; l’événement/snapshot appartient à `map_runtime`; les écrans
appartiennent à `map_player_ui`; commit et sortie appartiennent au Hub.

## Tests, DONE et risques

Tests : sérialisation commande, validation no-code, émission unique, gameplay
lock, save failure/retry, crash avant/après commit, crédits, title/Hub et
post-game. DONE exige qu’aucune fin ne perde la dernière save valide ou laisse
le gameplay actif derrière l’UI. Le roadmap fangame n’a pas encore de lot
explicite pour ce contrat : créer un lot dédié avant l’implémentation.
