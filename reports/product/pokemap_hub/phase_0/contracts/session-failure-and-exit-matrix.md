# Matrice d’échec et de sortie de session

| Situation | Détection | Save | Bibliothèque | UI / recovery |
|---|---|---|---|---|
| annulation pendant chargement | commande `cancelLoading` | inchangée | inchangée | retour détail/titre |
| manifest devenu invalide | validation pré-lancement | inchangée | version marquée à réparer, jamais supprimée | Réparer / rollback |
| timeout `ready` 30 s | superviseur | inchangée | inchangée | arrêter, diagnostics, réessayer |
| heartbeat absent 10 s | superviseur | dernière save valide | inchangée | attendre ou forcer l’arrêt |
| exception runtime récupérable | `fatal(recoverable)` | checkpoint seulement s’il se valide | inchangée | titre ou Hub |
| crash/exit enfant non nul | code OS + crash marker | temp rejetée, backup conservé | inchangée | Hub reste actif, Réparer |
| OOM même processus mobile | crash marker au prochain démarrage | dernière save atomique | inchangée | démarrage Hub sûr |
| checkpoint invalide | validation Hub | rejeté, backup conservé | inchangée | avertissement, continuer ou quitter |
| disque plein | erreur repository | ancienne save conservée | inchangée | libérer de l’espace / réessayer |
| `GameCompleted` | événement v1 | save finale `completed` atomique | temps/progression après commit | résultat puis crédits |
| Retour au titre | commande/événement | selon checkpoint explicite | inchangée | titre après unload monde |
| Retour au Hub | commande/événement | selon choix save/abandon | inchangée | Hub après `disposed` |
| fermeture OS | lifecycle + délai OS | checkpoint best-effort, jamais promotion invalide | inchangée | crash marker si teardown incomplet |
| protocole incompatible | handshake | inchangée | inchangée | mise à jour Hub/runtime requise |
| lancement B pendant A | garde Hub | inchangée | inchangée | refuser jusqu’à `disposed(A)` |

## Codes de sortie enfant

- `0` : teardown propre ;
- `10` : contrat/protocole incompatible ;
- `11` : package ou project invalide ;
- `12` : save incompatible/invalide ;
- `20` : erreur runtime récupérable devenue fatale ;
- `21` : erreur non classée ;
- signal/exit OS : crash externe, jamais remappé en succès.

## Règle de sécurité

Aucun chemin, stack brute ou contenu de save n’est affiché dans une erreur
joueur. Un identifiant de diagnostic permet d’ouvrir des détails locaux
redactés. Repair, rollback et uninstall ne suppriment jamais les saves.
