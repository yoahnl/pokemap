# Architecture d’information joueur

## Principes

Le Hub est la racine. Une session n’est jamais la racine de l’application.
L’interface joueur masque les notions de workspace, seed, map technique,
collision et chemin de fichier. Toute action risquée possède un aperçu, un
impact sur les saves et une confirmation adaptée.

## Arborescence

```text
Hub
├── Accueil
│   ├── Reprendre la dernière partie
│   ├── Jeux récents/installés
│   ├── Importer un jeu
│   └── Activité : install/update/error/espace
├── Bibliothèque
│   ├── Recherche/tri
│   ├── Vue vide guidée
│   └── Détail du jeu
│       ├── Continuer / Nouvelle partie
│       ├── Versions et mise à jour
│       ├── Gérer les sauvegardes
│       ├── Réparer
│       └── Désinstaller
├── Imports et installations
│   ├── Inspection/compatibilité/confiance
│   ├── Progression par étape + annulation
│   └── Résultat/diagnostics
├── Préférences
│   ├── audio, langue, inputs, accessibilité
│   └── stockage et confidentialité
└── Diagnostics
    ├── état bibliothèque/versions/receipts
    └── logs redactés/export diagnostic

Player
├── Écran titre
│   ├── Continuer
│   ├── Nouvelle partie
│   ├── Charger
│   ├── Options
│   ├── Crédits / À propos
│   └── Retour au Hub
├── Session
│   └── Pause
│       ├── Reprendre
│       ├── Équipe / Sac / Pokédex / Carte
│       ├── Sauvegarder
│       ├── Options
│       └── Retour au titre
└── Fin
    ├── Résultat
    ├── Crédits
    └── Titre ou Hub
```

## Contenu des écrans

Accueil : reprise, jeux, import, progression, erreurs de compatibilité, updates,
espace disque et diagnostics. Détail : icon/cover, titre, auteur, description,
version, confiance, dernière save, temps de jeu et actions contextuelles.

Titre : branding déclaratif uniquement (logo, fond, hero, accent, musique,
layout autorisé). Aucun widget ou script du jeu. Pause : responsive portrait,
paysage et desktop ; navigation tactile, clavier et manette.

## Navigation et focus

Un routeur d’input partagé expose directions, confirmer, retour, Menu/Start,
tabs et actions contextuelles. Chaque route restaure un focus logique. Les
modales piègent le focus et annoncent leur titre. Le text scaling, semantics,
reduced motion, contraste et glyphes d’input suivent les préférences globales.

## États transverses

Chargement affiche étape, progression connue/inconnue, temps écoulé,
annulation et timeout. Une erreur donne : impact, données préservées, action
recommandée, code diagnostic. Aucune opération longue ne bloque la navigation
globale sans raison de cohérence.

## Non-objectifs et dépendances

Pas de store, social, cloud save ou compte en Phase 0. L’IA dépend de
GameLibrary, SaveRepository et GameSessionPort, et guide les contrats
`map_player_ui`; elle ne fixe pas encore le style visuel.

## Tests et DONE

Tests widget/contrat futurs : routes, focus, back, deep links internes, écrans
vides, loading/error/recovery, responsive et semantics. DONE exige qu’un joueur
puisse installer, lancer, sauver, terminer et revenir au Hub sans écran debug
ni état sans issue.
