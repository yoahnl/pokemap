import 'package:flutter/material.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';

import 'resource_usage_dialog.dart';
import 'resource_usage_replacement_dialog.dart';

Future<void> openResourceUsages(
  BuildContext context,
  ResourceNavigation navigation,
  ResourceItem item,
) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (dialogContext) => ResourceUsageDialog(
    item: item,
    port: navigation.usages,
    changes: navigation,
    dirtyOwners: () => navigation.usageDraftOwners,
    onOpen: navigation.openUsageOwner,
    canOpen: navigation.canOpenUsageOwner,
    replaceUsages: (report) => replaceResourceUsages(
      dialogContext,
      navigation,
      target: report.target,
      name: item.name,
    ),
  ),
);
