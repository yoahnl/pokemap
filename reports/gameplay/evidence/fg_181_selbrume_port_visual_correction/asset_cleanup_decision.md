# Décision de nettoyage des assets — FG-181

## Verdict

Le module tile-only `module_port_ref_foam_v_short` a été supprimé du builder,
de la provenance et de la composition finale parce que sa ligne d’écume
verticale était artificielle. L’atlas partagé a été régénéré et ne contient
plus ce module.

Aucun fichier source historique, `ProjectElement` ou atlas supplémentaire n’a
été supprimé. Les quinze modules générés restants sont tous utilisés par la
composition finale et présents dans les couches visuelles de la map.

## Audit automatisé

Le dry-run hash-locké est conservé dans `asset_usage.json` :

- 5 660 fichiers inspectés ;
- 5 546 classés comme utilisés au runtime ;
- 87 candidats automatiques à la suppression ;
- SHA du manifeste :
  `d77be7e540cb9d65f43e12e02fd34019623a3453986582155abaea590143b733`.

La suppression n’a pas été appliquée. Parmi les 87 candidats se trouvent les
18 feuilles alpha/chroma `port_reference_v3` que le builder charge par chemins
construits dynamiquement. Le scanner textuel ne sait pas reconstituer ces
chemins et produit donc des faux positifs démontrables. Les autres candidats
appartiennent à des familles v2 et à un chantier concurrent ; les supprimer
aurait dépassé le périmètre sûr du lot.

## Conclusion

Le nettoyage sûr du lot est terminé au niveau modulaire. Une suppression de
fichiers physiques demanderait d’abord d’enseigner au scanner le graphe des
sources de build dynamiques, puis de refaire un dry-run revu manuellement.
