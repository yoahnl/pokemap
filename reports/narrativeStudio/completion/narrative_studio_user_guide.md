# Guide utilisateur — Narrative Studio

Version : Narrative Studio v1 / Selbrume, 2026-07-21

## Le modèle mental en une phrase

La map contient les choses physiques ; Narrative Studio décrit ce qui arrive
quand le joueur interagit avec elles.

Un PNJ, un objet ou une zone doit donc d'abord exister dans le Map Editor.
L'Event Builder ne crée pas une seconde copie de cet élément : il sélectionne
sa source physique et lui associe des conditions, une Scene et un comportement
narratif.

## Ordre d'authoring recommandé

1. **Maps** — placer les PNJ, objets, zones et points d'entrée physiques.
2. **Facts** — définir les informations persistantes du monde : booléens,
   nombres ou textes.
3. **Dialogues** — écrire les échanges et déclarer leurs outcomes.
4. **Cinematics** — préparer les séquences linéaires et leurs médias/FX.
5. **Scenes** — assembler Dialogue, Cinematic, Combat, Conditions, Actions,
   branches, merges et fins.
6. **Storylines** — organiser Chapters et Steps, puis lier les Scenes.
7. **Events** — choisir une source réelle de map et la Scene à lancer.
8. **World Rules** — projeter les Facts sur la visibilité, les dialogues et
   l'état des Events.
9. **Validateur** — corriger les erreurs, examiner les avertissements et
   produire une preuve runtime fraîche.

## Storylines, Chapters et Steps

Une Storyline représente un arc narratif. Ses Chapters structurent cet arc et
ses Steps décrivent la progression jouable. Utilisez les pickers de Scenes et
de dépendances : un ID technique ne doit pas être saisi manuellement dans le
workflow normal.

Le graph est une projection de la structure canonique. Déplacer un élément
dans le graph ne doit pas créer une deuxième vérité narrative.

## Dialogues et outcomes

Le Dialogue Studio conserve le document Yarn riche. Un outcome est un résultat
nommé, par exemple `accepted`, `refused` ou `completed`. Les Scenes utilisent
ces outcomes comme ports de sortie. Avant de renommer ou supprimer un outcome,
examinez ses consommateurs ; l'outil bloque les suppressions dangereuses.

Utilisez Preview pour vérifier la lecture, puis sauvegardez. Après fermeture et
reload, le document, son nœud d'entrée et ses outcomes doivent rester identiques.

## Scenes

Une Scene est le graphe exécutable :

- **Start** démarre le flux ;
- **Dialogue**, **Cinematic** et **Combat** attendent un résultat réel ;
- **Condition** lit un Fact, une Step ou un Event consommé ;
- **Action/Consequence** applique une commande typée ;
- **Branch** sépare les outcomes ;
- **Merge** rassemble des chemins ;
- **End** publie le résultat terminal et sa politique de retry.

Reliez toujours les ports nommés. Le Validator signale les chemins sans fin,
les références absentes et les outcomes impossibles.

## Events et sources de map

Dans Événements, la liste peut être regroupée par map, mais la map n'est pas
un conteneur narratif supplémentaire. Elle sert à retrouver les sources
physiques disponibles :

- entrée sur une map ;
- entrée dans une zone/trigger ;
- interaction avec un PNJ ;
- interaction avec un objet ;
- réception d'un outcome.

Pour créer un Event :

1. créer le brouillon et lui donner un nom lisible ;
2. choisir une source physique existante ;
3. ajouter les conditions avec les pickers de Facts/Events ;
4. choisir la Scene ;
5. régler réutilisation, reset, priorité et ordre ;
6. publier puis activer ;
7. lancer la simulation et le Validator.

Si la source physique n'existe pas, revenez au Map Editor pour la placer. Une
source proposée par l'Event Builder passe par une transaction récupérable : en
cas d'écriture interrompue, utilisez l'action de reprise au lieu de recréer la
source.

## Facts et World Rules

Les Facts sont la mémoire narrative persistante. Choisissez le type avant la
valeur et utilisez uniquement les opérateurs compatibles proposés par l'UI.

Les World Rules traduisent un état narratif en changement visible du monde.
Le simulateur permet d'essayer des Facts hypothétiques sans modifier le projet
et explique quelles règles contribuent au résultat.

## Cinematics

Une Cinematic reste linéaire : les décisions de gameplay appartiennent à la
Scene. La timeline peut contenir caméra, déplacement, orientation, emote,
dialogue, shake, fade, son, musique, FX et markers selon les contrats publiés.

Un média absent ou une commande non supportée doit produire un diagnostic
explicite. Ne publiez jamais une séquence qui ne peut pas être jouée par le
runtime.

## Validator

Le Validator sépare quatre dimensions :

- structure et références ;
- solvabilité narrative bornée ;
- atteignabilité physique ;
- receipt runtime frais.

`Jouable` signifie que les dimensions obligatoires passent pour le fingerprint
courant. Un budget dépassé reste `indeterminate`, jamais un succès. Les
avertissements supprimés restent traçables ; ils ne disparaissent pas sans
justification.

## Sauvegarde et recovery

- sauvegardez après une modification cohérente ;
- attendez l'état Synchronisé/Sauvegardé avant de fermer ;
- si une révision stale ou une écriture interrompue est détectée, utilisez
  l'action de recovery présentée par l'UI ;
- une demande de sauvegarde pendant une Scene awaitable est refusée sans
  écriture partielle ; sauvegardez après l'outcome/End ;
- vérifiez toujours une campagne importante par fermeture et reload.

## Compatibilité legacy

Les anciens GlobalStory et Map Events peuvent encore être lus et prévisualisés
pour migration. Ils ne sont pas le chemin d'authoring normal. Utilisez les
écrans de migration consolidés, examinez le diff, appliquez la conversion puis
validez. Ne modifiez pas l'ancien JSON comme solution permanente.

## Avant de livrer

1. sauvegarder, fermer et recharger le projet ;
2. lancer le Validator et obtenir 0 erreur bloquante ;
3. exécuter les chemins victoire, défaite et retry ;
4. sauvegarder/recharger dans le runtime ;
5. vérifier clavier, 200 % de texte et petite fenêtre ;
6. conserver le receipt correspondant exactement au fingerprint livré.

Pour la procédure exhaustive, suivre
`reports/narrativeStudio/completion/ns_completion_human_qa_checklist.md`.
