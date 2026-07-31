# PMCP-082 — Décision SDK et compatibilité MCP

Date : 2026-07-31
Lot : `PMCP-082` — gate SDK et protocole MCP
Verdict proposé : **DONE**

## Décision

PokeMap retient le SDK TypeScript officiel MCP v2, avec les versions verrouillées suivantes :

- `@modelcontextprotocol/server@2.0.0`
- `@modelcontextprotocol/client@2.0.0`
- `@modelcontextprotocol/core@2.0.0`
- Node.js `>=20`
- TypeScript `7.0.2`

Le serveur local est distribué en JavaScript compilé et servi sur **stdio**. Il préfère le protocole `2026-07-28`, accepte `2025-11-25` comme fallback documenté et refuse une version épinglée inconnue.

Le transport Streamable HTTP reste différé : PokeMap cible d'abord un MCP local lancé par le client, il n'a donc pas besoin d'exposer un port, une authentification distante ou une politique DNS/rebinding. Le SDK retenu le supporte et permettra une gate dédiée si une distribution distante devient un besoin produit.

Les tâches longues utilisent le tool PokeMap `pokemap_job` et non l'extension MCP Tasks. La version officielle testée sait négocier le protocole moderne, mais n'expose pas encore d'API serveur stable d'enregistrement pour l'extension Tasks `2026-07-28`. Ce fallback est compatible avec le périmètre `PMCP-084` (`pokemap_job` **ou** Tasks) et évite de coupler `map_authoring` à une API expérimentale.

## Sources officielles revalidées

- [SDK TypeScript officiel](https://github.com/modelcontextprotocol/typescript-sdk) — la ligne v2 sépare les packages client, server et core.
- [Guide client TypeScript](https://github.com/modelcontextprotocol/typescript-sdk/blob/main/docs/client.md) — transports stdio/Streamable HTTP et négociation côté client.
- [Guide serveur TypeScript](https://github.com/modelcontextprotocol/typescript-sdk/blob/main/docs/server.md) — resources, structured content, stdio et état de Tasks.
- [Support de la révision 2026-07-28](https://ts.sdk.modelcontextprotocol.io/v2/migration/support-2026-07-28) — négociation moderne opt-in et repli explicite.
- [Système de tiers des SDK MCP](https://modelcontextprotocol.io/community/sdk-tiers) — critères de conformance et statut officiel.
- [Spécification MCP 2026-07-28](https://modelcontextprotocol.io/specification/2026-07-28) — protocole moderne retenu.

## Audit initial

- `tools/` était absent ; aucun prototype MCP antérieur ne devait être conservé.
- Runtime local : Node `v26.3.1`, npm `11.16.0`.
- Métadonnées npm vérifiées le 2026-07-31 : packages officiels client/server/core en `2.0.0`, moteurs Node `>=20`.
- Le package Dart `map_authoring` ne dépend d'aucun protocole MCP ; cette séparation devait rester stricte.
- Les changements externes Smart Tiles/World Map et `examples/playable_runtime_host/pubspec.lock` étaient présents et sont restés hors périmètre.

## Matrice de compatibilité reproduite

| Cas | Transport | Version demandée | Résultat |
|---|---|---:|---|
| Moderne in-process | paire mémoire du SDK servie par la gate stdio | `2026-07-28` épinglée | `PASS`, ère `modern` |
| Fallback historique | paire mémoire du SDK servie par la gate stdio | client legacy par défaut | `PASS`, `2025-11-25` |
| Version inconnue | paire mémoire | `2099-01-01` épinglée | `PASS`, refus fermé |
| Distribution réelle | process Node compilé sur stdio | `2026-07-28` épinglée | `PASS` |
| Tools | mémoire et stdio | moderne + fallback | `PASS`, liste et appel |
| Resources | mémoire et stdio | moderne + fallback | `PASS`, liste et lecture JSON |
| Structured content | mémoire et stdio | moderne + fallback | `PASS`, schéma de sortie validé |
| Tasks | API publique server v2.0.0 | `2026-07-28` | fallback `pokemap_job` retenu |
| Streamable HTTP | non requis pour la distribution locale | n/a | différé avec gate future |

## Passes de contrôle et verdicts

Aucun sub-agent n'a été lancé, conformément à la contrainte active de session. Cinq passes locales ont été exécutées.

1. **Sélection SDK** — `PASS` : SDK officiel v2 stable, versions exactes verrouillées par lockfile.
2. **Conformance protocolaire ciblée** — `PASS` : moderne, fallback et rejet négatif couverts.
3. **Transport** — `PASS` : le binaire compilé dialogue sur stdio sans pollution de stdout.
4. **Primitives MCP** — `PASS` : tools, resources et structured content traversent les deux ères.
5. **Frontière PokeMap** — `PASS` : aucun import ni changement protocolaire dans `packages/map_authoring`.

## Fichiers créés

- `tools/pokemap_mcp/.gitignore`
- `tools/pokemap_mcp/package.json`
- `tools/pokemap_mcp/package-lock.json`
- `tools/pokemap_mcp/tsconfig.json`
- `tools/pokemap_mcp/src/protocol.ts`
- `tools/pokemap_mcp/src/compatibility_server.ts`
- `tools/pokemap_mcp/src/index.ts`
- `tools/pokemap_mcp/test/protocol_compatibility.test.ts`
- `reports/analysis/pmcp_082_mcp_sdk_compatibility_decision.md`
- `reports/analysis/pmcp_082_mcp_sdk_compatibility_decision_appendix.md`

Le contenu intégral des huit fichiers du serveur est reproduit dans l'appendice ; les rapports ne sont pas reproduits récursivement.

## Zones et contrats introduits

- `protocol.ts` fige identité serveur, versions préférée/fallback, transport retenu et fallback jobs.
- `compatibility_server.ts` construit une même factory valable dans les deux ères et expose une sonde temporaire testable avec resource JSON et structured content.
- `index.ts` utilise `serveStdio`, qui choisit l'ère sur le premier échange et instancie le même serveur pour les clients modernes ou legacy.
- Le test démarre aussi `dist/src/index.js` dans un vrai process enfant, ce qui valide la forme distribuée et pas seulement une fixture in-process.

## Commandes et résultats exacts

### Versions et installation

```text
node --version
v26.3.1

npm --version
11.16.0

npm install
added 21 packages, and audited 22 packages in 5s
found 0 vulnerabilities
```

npm a signalé que le script `postinstall` d'`esbuild@0.28.1` n'était pas couvert par `allowScripts`. Les tests via `tsx` fonctionnent malgré ce warning ; aucune approbation globale de script n'a été ajoutée silencieusement.

### Vérification finale

```text
cd tools/pokemap_mcp
npm run check
Résultat exact : tsc -p tsconfig.json --noEmit — exit 0

npm test
Résultat exact : tests 5, pass 5, fail 0, cancelled 0, skipped 0, todo 0
Le script exécute d'abord npm run build, puis le runner Node.
```

Le premier passage de type-check a échoué sur l'accès non discriminé à `ResourceContents.text`; le test a été corrigé par un narrowing `"text" in content`. Le premier test moderne in-process a ensuite révélé que `McpServer.connect` seul démarre la voie legacy ; la fixture a été corrigée pour utiliser la gate d'ère `serveStdio` avec un transport mémoire. Ces deux échecs ont renforcé la preuve finale.

## État Git

État initial : commit `5f534dc4` pour PMCP-081, plus changements externes non liés dans Smart Tiles/World Map, des tests éditeur, `.superpowers/brainstorm/...` et `examples/playable_runtime_host/pubspec.lock`.

État attendu du commit : uniquement `tools/pokemap_mcp/**` et les deux rapports PMCP-082 sont indexés. `node_modules/`, `dist/` et `coverage/` sont ignorés localement.

## Stratégie d'upgrade et fallback

1. Les versions du SDK sont exactes dans `package.json` et `package-lock.json` ; aucune plage flottante.
2. Toute montée de SDK doit repasser `npm run check`, `npm test` et la matrice moderne/legacy/rejet.
3. `2026-07-28` reste la préférence ; `2025-11-25` reste disponible tant qu'un client produit supporté l'exige.
4. La suppression du fallback legacy demande une décision séparée et une preuve de compatibilité des clients réels.
5. Tasks ne remplace `pokemap_job` que lorsqu'une API officielle stable passe des tests create/get/result/cancel et la compatibilité client.
6. Streamable HTTP ne peut être activé qu'avec tests Host/Origin, authentification, statelessness et isolation des racines.

## Non-objectifs et limites

- La sonde `pokemap_protocol_probe` est un outil de gate ; la surface métier stable arrive avec PMCP-083.
- Aucun accès à un projet PokeMap réel dans ce lot.
- Aucun serveur HTTP ni exposition réseau.
- Aucune revendication de conformance MCP complète : PMCP-085 garde cette responsabilité.
- L'Inspector MCP n'a pas été utilisé ; le client officiel v2 est la preuve client automatisée reproductible de ce lot.

## Auto-critique

La matrice prouve précisément les capacités nécessaires au lancement des lots MCP, mais ce n'est pas la suite officielle complète de conformance. Le choix stdio réduit fortement la surface d'attaque initiale, au prix de différer la distribution distante. La stratégie Tasks est prudente : elle ajoute un tool PokeMap à maintenir, mais évite une dépendance prématurée à une extension dont l'API TypeScript server n'est pas stabilisée. Le lot satisfait sa gate de décision et peut être proposé `DONE`.

## Suite recommandée

Passer à `PMCP-083` : remplacer la sonde temporaire par les cinq tools read-only, les resources/templates projet, la pagination, les handles explicites et la sandbox de racines.
