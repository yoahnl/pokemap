# Matrice de disponibilité des actions

| Surface | Action | Disponible si | Sinon |
|---|---|---|---|
| Accueil | Reprendre | save valide compatible + version installée | masquée avec accès au diagnostic depuis le jeu |
| Accueil | Importer | espace et permissions minimales | désactivée avec raison |
| Détail | Continuer | au moins une save compatible | désactivée |
| Détail | Nouvelle partie | jeu launchable + slot disponible/confirmé | erreur compatibilité |
| Détail | Réparer | receipt/package source disponible | explique la source requise |
| Détail | Mettre à jour | candidate supérieure compatible | masquée ou diagnostic |
| Détail | Gérer saves | saves présentes, même si jeu absent | disponible depuis bibliothèque des saves |
| Détail | Désinstaller | aucune install/update active | confirmation ; saves préservées par défaut |
| Titre | Continuer | profil actif + save compatible | désactivée |
| Titre | Nouvelle partie | slot vide ou overwrite confirmé | sélecteur de slot |
| Titre | Charger | au moins un slot | désactivée |
| Titre | Options | toujours | — |
| Titre | Crédits/À propos | métadonnées légales valides | À propos minimal du Hub |
| Titre | Retour au Hub | aucune mutation save non résolue | attend commit/abandon |
| Pause | Reprendre | session running/paused | — |
| Pause | Équipe | capability et état gameplay l’autorisent | désactivée avec raison |
| Pause | Sac | capability et état gameplay l’autorisent | désactivée |
| Pause | Pokédex | capability/unlock/Facts | masquée ou désactivée selon design |
| Pause | Carte | map joueur disponible | désactivée |
| Pause | Sauvegarder | policy du jeu, lieu/état et stockage autorisent | raison lisible |
| Pause | Options | toujours | — |
| Pause | Retour au titre | pas de transition critique | confirmation + checkpoint |
| Monde | Boutique | interaction monde ou capability explicite + Facts | absente |
| Monde | Centre Pokémon | interaction monde ou capability explicite + Facts | absent |
| Monde | PC | interaction monde ou capability explicite + Facts | absent |
| Fin | Continuer crédits | save completed committée | retry save / quitter sans perdre ancienne |

## Règles globales

- Une action désactivée est focusable seulement si son explication est utile et
  accessible ; sinon elle est masquée.
- Double activation et répétition manette sont idempotentes.
- Install/update/repair/uninstall ont progression, annulation quand sûre et
  verrou de mutation ciblé.
- Les actions debug, seeds, FPS, collisions, map ID et save/load de harness
  n’existent jamais dans le produit.
- Branding, locale ou plateforme ne changent pas les règles métier.

## Tests futurs

Chaque ligne devient un test table-driven entre snapshot d’état et liste
d’actions. Ajouter focus clavier/manette, semantics, portrait/paysage et
race conditions update/session/save.
