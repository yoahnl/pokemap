# PMCP-083 — MCP lecture seule et resources

Date : 2026-07-31
Lot : `PMCP-083` — premier serveur MCP utile sans mutation
Verdict proposé : **DONE**

## Résultat

Le binaire MCP compilé inspecte désormais un projet PokeMap réel via le worker JSONL canonique Dart. Il expose exactement cinq tools read-only :

- `pokemap_artifact`
- `pokemap_describe`
- `pokemap_query`
- `pokemap_validate`
- `pokemap_workspace`

Il expose aussi quatre resource templates : projet, map, catalogue et diagnostics. Les requêtes conservent les handles opaques, la révision de snapshot, les cursors canoniques et les erreurs structurées de `map_authoring`. Aucun tool plan/apply/undo/recover n'est enregistré dans cette version.

## Audit initial

- Base : commit `61042cab` (`PMCP-082`).
- Le worker `packages/map_authoring/bin/pokemap_authoring.dart` exposait déjà la session JSONL canonique et appliquait `WorkspacePolicy` aux racines autorisées.
- Aucun client TypeScript ne gérait encore le cycle de vie du process Dart, la corrélation des réponses, les timeouts ou l'arrêt propre.
- Aucun tool métier ni resource template n'était branché au binaire de production ; seule la sonde de compatibilité PMCP-082 existait.
- Les modifications externes Smart Tiles/World Map, `.superpowers/brainstorm/...` et `examples/playable_runtime_host/pubspec.lock` étaient présentes et ont été laissées hors périmètre.

## Architecture retenue

```text
Client MCP
  -> tools/resources TypeScript read-only
  -> LocalAuthoringClient (JSONL corrélé)
  -> dart run bin/pokemap_authoring.dart --root ...
  -> AuthoringReadApi / ProjectSnapshotLoader / WorkspacePolicy
```

Le MCP ne parse pas `project.json`, ne lit pas directement les maps et ne réimplémente aucune règle PokeMap. La seule frontière filesystem produit reste le worker Dart, déjà sandboxé et testé.

## Passes de contrôle et verdicts

Aucun sub-agent n'a été lancé, conformément à la contrainte active de session. Cinq passes locales ont été exécutées.

1. **Contrat** — `PASS` : liste exacte des cinq tools, annotations read-only et output schemas présents.
2. **Intégration réelle** — `PASS` : `golden_fangame_slice` est ouvert, paginé, validé et fermé via le worker Dart.
3. **Resources** — `PASS` : quatre templates listables et lisibles avec handles explicites ; URI de traversée refusée.
4. **Sécurité** — `PASS` : sortie de racine refusée avec `workspace.path_outside_allowed_roots`, artefacts limités à `artifact://`, stdout protocolaire propre.
5. **Non-mutation** — `PASS` : aucun tool de mutation n'est listé et aucun accès filesystem direct n'existe dans les handlers MCP.

## Fichiers créés

- `tools/pokemap_mcp/README.md` — build, configuration locale et workflow read-only.
- `tools/pokemap_mcp/src/authoring_client.ts` — client JSONL process-safe et erreurs typées.
- `tools/pokemap_mcp/src/artifacts.ts` — port de lecture par handle opaque et registre mémoire.
- `tools/pokemap_mcp/src/config.ts` — parsing sûr des racines, Dart et package canonique.
- `tools/pokemap_mcp/src/resources/read_only.ts` — quatre resource templates.
- `tools/pokemap_mcp/src/server.ts` — composition du serveur MCP produit.
- `tools/pokemap_mcp/src/tools/read_only.ts` — cinq tools et enveloppes structurées.
- `tools/pokemap_mcp/test/read_only_server.test.ts` — preuves end-to-end sur projet réel et refus négatifs.
- `reports/analysis/pmcp_083_mcp_read_only_evidence.md` — présent rapport.
- `reports/analysis/pmcp_083_mcp_read_only_evidence_appendix.md` — contenu intégral des fichiers créés.

## Fichiers modifiés

- `tools/pokemap_mcp/src/index.ts` — remplace la sonde par le serveur produit configuré, ferme le worker avec le transport.
- `tools/pokemap_mcp/test/protocol_compatibility.test.ts` — teste le binaire produit moderne, ses cinq tools et l'échec de configuration sans bruit protocolaire.

L'appendice reproduit les huit fichiers source/test/documentation créés. Les deux rapports ne sont pas reproduits récursivement.

## Contrats et zones précises

### Client Authoring

- un process Dart démarré à la première requête ;
- IDs `mcp-N` corrélés aux enveloppes `requestId` ;
- timeout externe de 15 s et timeout worker de 10 s ;
- stdout exclusivement JSONL, stderr drainé mais jamais renvoyé au modèle ;
- arrêt stdin, attente bornée puis `SIGTERM` si nécessaire ;
- erreurs canoniques conservant code, `domainCode`, retryabilité et remédiation.

### Tools

- `pokemap_workspace` utilise une union discriminée open/close ;
- `pokemap_query` expose les cinq opérations, les vues, filtres, tris, field masks, page size `1..200` et cursor opaque ;
- `pokemap_validate` transmet la vérité de capacité optionnelle ;
- `pokemap_artifact` n'accepte que les handles `artifact://` déjà enregistrés ; aucun `file://` ou HTTPS arbitraire ;
- tous les tools déclarent `readOnlyHint`, `destructiveHint: false`, `idempotentHint` et `openWorldHint: false`.

### Resources

- `pokemap://project/{projectHandle}`
- `pokemap://project/{projectHandle}/catalog/{resourceKind}`
- `pokemap://project/{projectHandle}/diagnostics`
- `pokemap://project/{projectHandle}/map/{mapId}`

Les resources délèguent à `query` ou `validate`; elles ne transforment jamais un URI en chemin local.

## TDD et incidents utiles

Le test initial a échoué comme attendu :

```text
test/read_only_server.test.ts
TS2307: Cannot find module '../src/authoring_client.js'
TS2307: Cannot find module '../src/artifacts.js'
TS2307: Cannot find module '../src/server.js'
```

Une première lecture de resource map en vue `detail` a révélé une limitation du fixture legacy `golden_fangame_slice` : le worker renvoie `worker.request_invalid` lors de la sérialisation détaillée de l'une de ses maps. La resource map utilise donc la vue summary, stable sur ce fixture ; `pokemap_query` conserve l'option detail et propage honnêtement l'erreur canonique. Cette limite n'a pas été masquée par un parseur MCP alternatif.

Le test stdio PMCP-082 a aussi été mis à jour parce que le binaire produit exige maintenant au moins une racine autorisée, conformément à la sandbox.

## Commandes et résultats exacts

### MCP TypeScript

```text
cd tools/pokemap_mcp
npm run check
Résultat exact : tsc -p tsconfig.json --noEmit — exit 0

npm test
Résultat exact : tests 10, pass 10, fail 0, cancelled 0, skipped 0, todo 0
Le script exécute npm run build avant les tests.
```

La matrice couvre : protocole moderne, fallback, rejet de version, binaire stdio, configuration négative, projet réel, pagination, resources, artefacts et sandbox.

### Worker Dart canonique

```text
cd packages/map_authoring
dart test test/tooling/jsonl_worker_test.dart test/tooling/cli_golden_test.dart --reporter compact
Résultat exact : +14, All tests passed!

dart analyze
Résultat exact : No issues found!
```

## État Git

État initial : `61042cab`, avec changements externes non liés dans Smart Tiles/World Map, `.superpowers/brainstorm/...` et le lockfile du host runtime.

État attendu du commit : uniquement les dix fichiers `tools/pokemap_mcp` du lot et les deux rapports PMCP-083 sont indexés. `node_modules/` et `dist/` restent ignorés.

## Critères de fin PMCP-083

- Client MCP inspecte un projet réel : **oui**, `golden_fangame_slice`.
- Tools list stable et schémas valides : **oui**, liste exacte testée et type-check strict.
- Resource URI invalide refusée : **oui**, traversal testée.
- Aucune écriture possible par cette version : **oui**, cinq tools read-only seulement ; mutations absentes.
- Pagination et structured content : **oui**, cursor opaque et enveloppes structurées testés.
- Handles explicites : **oui**, project/workspace/artifact handles jamais interprétés comme chemins.
- Sandbox de chemins : **oui**, refus hors racine testé par le worker canonique.

## Non-objectifs et limites

- Le worker Dart combiné décrit ses capacités de mutation (`readOnly: false`), mais la surface MCP PMCP-083 n'enregistre aucun handler de mutation. La liste MCP, et non la description interne, est la gate effective.
- Le registre d'artefacts de production démarre vide ; PMCP-084 l'alimentera avec les sorties render/playtest/job. Le port et les refus sont déjà testés.
- Une resource catalogue renvoie au maximum 200 éléments et expose le `nextCursor` dans son JSON ; les gros parcours doivent employer `pokemap_query`.
- La resource map utilise summary sur le fixture legacy décrit plus haut.
- Pas de transport réseau, pas d'auth distante et pas de conformance totale PMCP-085.

## Auto-critique

Le serveur est utile et réduit réellement le tâtonnement : un agent peut découvrir, ouvrir, parcourir et valider sans lire le filesystem lui-même. Le choix d'un worker enfant par process MCP ajoute un coût de démarrage Dart visible dans les tests (~3–4 s), mais garantit la parité canonique et une isolation nette. La resource map summary est une concession documentée à un fixture legacy ; la voie générique reste disponible pour corriger le problème à la source plus tard. Le verdict `DONE` est justifié pour le périmètre read-only, sans anticiper PMCP-084.

## Suite recommandée

Passer à `PMCP-084` : enregistrer plan/apply/render/playtest/job/history/recovery, alimenter le registre d'artefacts, conserver les confirmations et démontrer retry/conflit/permissions/cancel/parité API-CLI-MCP.
