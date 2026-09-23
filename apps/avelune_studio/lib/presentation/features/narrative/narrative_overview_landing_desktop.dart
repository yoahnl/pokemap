part of 'narrative_overview_landing.dart';

extension _NarrativeOverviewLandingDesktop on NarrativeOverviewLanding {
  Widget _desktop(
    BuildContext context,
    double mainWidth,
    double sideWidth,
    String query,
  ) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _hero(context, mainWidth),
              const SizedBox(height: 12),
              StudioSearchField(
                controller: search,
                label: 'Rechercher dans Histoire',
                hint:
                    'Histoires, étapes, scènes, dialogues, événements et cartes',
                onChanged: onSearch,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  key: const PageStorageKey(
                    'narrative-overview-content-scroll',
                  ),
                  child: query.isNotEmpty
                      ? _searchResults(context, query)
                      : Column(
                          children: [
                            _stories(context, mainWidth),
                            const SizedBox(height: 12),
                            _lower(context, mainWidth),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: sideWidth,
          child: SingleChildScrollView(
            key: const PageStorageKey('narrative-overview-side-scroll'),
            child: _side(context),
          ),
        ),
      ],
    ),
  );
}
