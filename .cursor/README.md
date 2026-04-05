# Dossier `.cursor/` — mémoire projet PokeMap

Ce répertoire est une **mémoire locale** pour les interventions sur le dépôt (humains et assistants). Il complète `AGENTS.md` à la racine : `AGENTS.md` oriente l’exécution générale du monorepo ; `.cursor/` fixe la **vision produit**, la **discipline d’architecture**, et des **garde-fous** réutilisables.

## Contenu

| Fichier | Rôle |
|---------|------|
| [project_vision.md](project_vision.md) | Boussole produit PokeMap (no-code, accessibilité). |
| [clean_architecture_rules.md](clean_architecture_rules.md) | Règles d’architecture et de modularité. |
| [cutscene_studio_rules.md](cutscene_studio_rules.md) | Règles spécifiques Cutscene Studio. |
| [ui_ux_rules.md](ui_ux_rules.md) | Principes UI/UX desktop no-code. |
| [scope_rules.md](scope_rules.md) | Discipline de périmètre des changements. |
| [code_generation_rules.md](code_generation_rules.md) | Attentes pour le code et la documentation générés. |

## Usage

- Avant une refonte ou un module narratif, relire **scope** + **architecture** + le doc métier concerné (ex. Cutscene Studio).
- Après une passe structurante, mettre à jour ce dossier si une **décision durable** a été prise (nouvelle source de vérité, nouveau contrat runtime, etc.).
- Ne pas y mettre de secrets, tokens, ou données personnelles.

## Relation avec le code

Le découpage réel du domaine Cutscene Studio vit sous  
`packages/map_editor/lib/src/features/narrative/application/cutscene_studio/`.  
Les règles `.cursor/` décrivent l’intention ; le code et `packages/map_editor/reports/` documentent les faits après coup.
