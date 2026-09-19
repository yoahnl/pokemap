import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_tool.dart';
import 'workspace_resource_diagnostic.dart';

class WorkspaceResourceDiagnosticDetail extends StatelessWidget {
  const WorkspaceResourceDiagnosticDetail({super.key, required this.items});
  final List<WorkspaceResourceDiagnostic> items;

  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: 560,
      height: MediaQuery.sizeOf(context).height * .65,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Diagnostic complet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StudioTool(
                  label: 'Fermer le diagnostic complet',
                  icon: Icons.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: SelectableText(
                      '${item.name}\n${item.resourceId}\n'
                      '${item.message}\n${item.detail ?? 'Aucun détail technique disponible.'}',
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
