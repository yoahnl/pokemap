part of 'environment_editor_screen.dart';

class _EnvironmentDecorPicker extends StatefulWidget {
  const _EnvironmentDecorPicker({
    required this.project,
    required this.visuals,
    required this.excluded,
  });
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final Set<String> excluded;
  @override
  State<_EnvironmentDecorPicker> createState() =>
      _EnvironmentDecorPickerState();
}

class _EnvironmentDecorPickerState extends State<_EnvironmentDecorPicker> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elements = widget.project.elements
        .where(
          (element) =>
              !widget.excluded.contains(element.id) &&
              element.name.toLowerCase().contains(search.text.toLowerCase()),
        )
        .toList();
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      child: SizedBox(
        width: (size.width - 48).clamp(0, 650),
        height: (size.height - 80).clamp(0, 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choisir un décor',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              StudioSearchField(
                controller: search,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: elements.isEmpty
                    ? const Center(child: Text('Aucun autre décor disponible.'))
                    : ListView.builder(
                        itemCount: elements.length,
                        itemBuilder: (context, index) {
                          final element = elements[index];
                          return StudioChoice(
                            key: ValueKey('environment-decor-${element.id}'),
                            label: element.name,
                            leading: widget.visuals.thumbnail(
                              element,
                              size: 64,
                            ),
                            onTap: () => Navigator.pop(context, element),
                          );
                        },
                      ),
              ),
              StudioButton(
                label: 'Annuler',
                secondary: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
