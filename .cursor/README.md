# Dossier `.cursor/` — mémoire projet PokeMap

Ce répertoire est une **mémoire locale** pour les interventions sur le dépôt (humains et assistants). Il ne remplace **pas** les sources obligatoires à la racine du dépôt.

## Sources canoniques (racine)

| Fichier | Rôle |
|---------|------|
| [`AGENTS.md`](../AGENTS.md) | **Référence du monorepo** : graphique des packages, frontières d’architecture, contexte Surface Engine, matrice de tests/analyse, génération de code, compétences agents. |
| [`codex_rule.md`](../codex_rule.md) | **Règles Codex pour les lots** : audit, remise en cause du prompt, sub-agents, rapport, tests, build, honnêteté. |

La règle Cursor **`.cursor/rules/repository-instructions.mdc`** (`alwaysApply: true`) rappelle cette hiérarchie et oblige l’agent à s’y aligner. Les tâches « lot » s’appuient aussi sur **`.cursor/rules/codex-lot-workflow.mdc`**.

`AGENTS.md` oriente l’exécution générale du monorepo ; `codex_rule.md` cadre le travail par lots. Le dossier `.cursor/` (hors `rules/`) fixe en complément la **vision produit**, la **discipline d’architecture**, et des **garde-fous** réutilisables.

## Contenu

| Fichier | Rôle |
|---------|------|
| [project_vision.md](project_vision.md) | Boussole produit PokeMap (no-code, accessibilité). |
| [clean_architecture_rules.md](clean_architecture_rules.md) | Règles d’architecture et de modularité. |
| [cutscene_studio_rules.md](cutscene_studio_rules.md) | Règles spécifiques Cutscene Studio. |
| [ui_ux_rules.md](ui_ux_rules.md) | Principes UI/UX desktop no-code. |
| [scope_rules.md](scope_rules.md) | Discipline de périmètre des changements. |
| [code_generation_rules.md](code_generation_rules.md) | Attentes pour le code et la documentation générés. |

### Règles Cursor (`.cursor/rules/`)

| Fichier | Rôle |
|---------|------|
| [rules/repository-instructions.mdc](rules/repository-instructions.mdc) | Rappelle `AGENTS.md` + `codex_rule.md` comme sources obligatoires (`alwaysApply`). |
| [rules/codex-lot-workflow.mdc](rules/codex-lot-workflow.mdc) | Rituel lot (audit, tests, rapport, honnêteté) — complète `codex_rule.md`. |

## Usage

- Avant une refonte ou un module narratif, relire **scope** + **architecture** + le doc métier concerné (ex. Cutscene Studio).
- Après une passe structurante, mettre à jour ce dossier si une **décision durable** a été prise (nouvelle source de vérité, nouveau contrat runtime, etc.).
- Ne pas y mettre de secrets, tokens, ou données personnelles.

## Relation avec le code

Le découpage réel du domaine Cutscene Studio vit sous  
`packages/map_editor/lib/src/features/narrative/application/cutscene_studio/`.  
Les règles `.cursor/` décrivent l’intention ; le code et `packages/map_editor/reports/` documentent les faits après coup.
