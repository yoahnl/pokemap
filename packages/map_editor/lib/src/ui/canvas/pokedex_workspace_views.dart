// Compatibilité de nommage pour les anciens imports UI du workspace Pokédex.
//
// Les vues ont été réparties dans le sous-dossier `pokedex_workspace/`. On
// réexporte les symboles publics existants pour éviter une casse artificielle du
// code extérieur à ce réalignement.
export 'pokedex_workspace/pokedex_workspace_page.dart'
    show
        PokedexWorkspaceLoadingState,
        PokedexWorkspaceErrorState,
        PokedexWorkspaceNoResultsState,
        PokedexWorkspaceSpeciesList,
        PokedexWorkspaceFeedbackBanner,
        PokedexWorkspaceImportEmptyState,
        PokedexWorkspaceDetailPane,
        PokedexWorkspaceStateCard,
        PokedexWorkspaceStateFrame,
        showPokedexImportFlowSheet;
