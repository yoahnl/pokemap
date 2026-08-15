import '../models/cinematic_library_catalog.dart';

final class CinematicLibraryCatalogMutationException implements Exception {
  const CinematicLibraryCatalogMutationException(
    this.code,
    this.message, {
    this.details = const {},
  });

  final String code;
  final String message;
  final Map<String, Object?> details;

  @override
  String toString() => '$code: $message';
}

final class CinematicLibraryCatalogOperations {
  const CinematicLibraryCatalogOperations();

  CinematicLibraryCatalog createFolder(
    CinematicLibraryCatalog catalog, {
    required String folderId,
    required CinematicLibraryFamily family,
    required String name,
    required String? parentFolderId,
    required int targetIndex,
  }) {
    if (catalog.folders.any((folder) => folder.id == folderId)) {
      throw CinematicLibraryCatalogMutationException(
        'cinematic_library.folder_duplicate',
        'The cinematic library folder identity already exists.',
        details: {'folderId': folderId},
      );
    }
    final parent = parentFolderId == null
        ? null
        : _requireFolder(catalog, parentFolderId);
    if (parent != null && parent.family != family) {
      throw CinematicLibraryCatalogMutationException(
        'cinematic_library.family_mismatch',
        'The parent folder belongs to another cinematic family.',
        details: {'parentFolderId': parentFolderId},
      );
    }
    _assertNameAvailable(
      catalog,
      family: family,
      parentFolderId: parentFolderId,
      name: name,
    );
    final siblings =
        catalog.folders
            .where(
              (folder) =>
                  folder.family == family &&
                  folder.parentFolderId == parentFolderId,
            )
            .toList()
          ..sort(_compareFolderOrder);
    _assertInsertionIndex(targetIndex, siblings.length);
    siblings.insert(
      targetIndex,
      CinematicLibraryFolder(
        id: folderId,
        family: family,
        name: name,
        parentFolderId: parentFolderId,
        sortOrder: targetIndex,
      ),
    );
    final replacements = <String, CinematicLibraryFolder>{
      for (var index = 0; index < siblings.length; index++)
        siblings[index].id: siblings[index].copyWith(sortOrder: index),
    };
    return CinematicLibraryCatalog(
      folders: [
        for (final folder in catalog.folders)
          replacements.remove(folder.id) ?? folder,
        ...replacements.values,
      ],
      entries: catalog.entries,
    );
  }

  CinematicLibraryCatalog renameFolder(
    CinematicLibraryCatalog catalog, {
    required String folderId,
    required String name,
  }) {
    final folder = _requireFolder(catalog, folderId);
    _assertNameAvailable(
      catalog,
      family: folder.family,
      parentFolderId: folder.parentFolderId,
      name: name,
      excludedFolderId: folderId,
    );
    return CinematicLibraryCatalog(
      folders: [
        for (final current in catalog.folders)
          current.id == folderId ? current.copyWith(name: name) : current,
      ],
      entries: catalog.entries,
    );
  }

  CinematicLibraryCatalog setFolderArchived(
    CinematicLibraryCatalog catalog, {
    required String folderId,
    required bool isArchived,
  }) {
    _requireFolder(catalog, folderId);
    return CinematicLibraryCatalog(
      folders: [
        for (final folder in catalog.folders)
          folder.id == folderId
              ? folder.copyWith(isArchived: isArchived)
              : folder,
      ],
      entries: catalog.entries,
    );
  }

  CinematicLibraryCatalog deleteFolder(
    CinematicLibraryCatalog catalog, {
    required String folderId,
  }) {
    final folder = _requireFolder(catalog, folderId);
    final references = <String>[
      for (final child in catalog.folders)
        if (child.parentFolderId == folderId) 'folder:${child.id}',
      for (final entry in catalog.entries)
        if (entry.folderId == folderId)
          'cinematic:${entry.family.name}:${entry.cinematicId}',
    ]..sort();
    if (references.isNotEmpty) {
      throw CinematicLibraryCatalogMutationException(
        'cinematic_library.folder_not_empty',
        'The cinematic library folder must be empty before deletion.',
        details: {'folderId': folderId, 'references': references},
      );
    }
    final siblings =
        catalog.folders
            .where(
              (candidate) =>
                  candidate.id != folderId &&
                  candidate.family == folder.family &&
                  candidate.parentFolderId == folder.parentFolderId,
            )
            .toList()
          ..sort(_compareFolderOrder);
    final replacements = <String, CinematicLibraryFolder>{
      for (var index = 0; index < siblings.length; index++)
        siblings[index].id: siblings[index].copyWith(sortOrder: index),
    };
    return CinematicLibraryCatalog(
      folders: [
        for (final current in catalog.folders)
          if (current.id != folderId) replacements[current.id] ?? current,
      ],
      entries: catalog.entries,
    );
  }

  CinematicLibraryCatalog placeCinematic(
    CinematicLibraryCatalog catalog, {
    required CinematicLibraryFamily family,
    required String cinematicId,
    required String? targetFolderId,
    required int targetIndex,
  }) {
    final targetFolder = targetFolderId == null
        ? null
        : _requireFolder(catalog, targetFolderId);
    if (targetFolder != null && targetFolder.family != family) {
      throw CinematicLibraryCatalogMutationException(
        'cinematic_library.family_mismatch',
        'The target folder belongs to another cinematic family.',
        details: {'family': family.name, 'targetFolderId': targetFolderId},
      );
    }
    final existing = catalog.entryFor(family, cinematicId);
    final siblings =
        catalog.entries
            .where(
              (entry) =>
                  !(entry.family == family &&
                      entry.cinematicId == cinematicId) &&
                  entry.family == family &&
                  entry.folderId == targetFolderId,
            )
            .toList()
          ..sort(_compareEntryOrder);
    _assertInsertionIndex(targetIndex, siblings.length);
    siblings.insert(
      targetIndex,
      CinematicLibraryEntry(
        family: family,
        cinematicId: cinematicId,
        folderId: targetFolderId,
        sortOrder: targetIndex,
        isArchived: existing?.isArchived ?? false,
      ),
    );
    final targetReplacements = <String, CinematicLibraryEntry>{
      for (var index = 0; index < siblings.length; index++)
        _entryKey(siblings[index]): siblings[index].copyWith(sortOrder: index),
    };
    final entries = <CinematicLibraryEntry>[
      for (final entry in catalog.entries)
        if (!(entry.family == family && entry.cinematicId == cinematicId))
          targetReplacements.remove(_entryKey(entry)) ?? entry,
      ...targetReplacements.values,
    ];
    return CinematicLibraryCatalog(
      folders: catalog.folders,
      entries: _normalizeEntryOrders(entries),
    );
  }

  CinematicLibraryCatalog setCinematicArchived(
    CinematicLibraryCatalog catalog, {
    required CinematicLibraryFamily family,
    required String cinematicId,
    required bool isArchived,
  }) {
    _requireEntry(catalog, family, cinematicId);
    return CinematicLibraryCatalog(
      folders: catalog.folders,
      entries: [
        for (final entry in catalog.entries)
          entry.family == family && entry.cinematicId == cinematicId
              ? entry.copyWith(isArchived: isArchived)
              : entry,
      ],
    );
  }

  CinematicLibraryCatalog removeCinematic(
    CinematicLibraryCatalog catalog, {
    required CinematicLibraryFamily family,
    required String cinematicId,
  }) {
    _requireEntry(catalog, family, cinematicId);
    return CinematicLibraryCatalog(
      folders: catalog.folders,
      entries: _normalizeEntryOrders([
        for (final entry in catalog.entries)
          if (!(entry.family == family && entry.cinematicId == cinematicId))
            entry,
      ]),
    );
  }

  CinematicLibraryCatalog moveFolder(
    CinematicLibraryCatalog catalog, {
    required String folderId,
    required String? targetParentFolderId,
    required int targetIndex,
  }) {
    final folder = _requireFolder(catalog, folderId);
    final parent = targetParentFolderId == null
        ? null
        : _requireFolder(catalog, targetParentFolderId);
    if (parent != null && parent.family != folder.family) {
      throw CinematicLibraryCatalogMutationException(
        'cinematic_library.family_mismatch',
        'The target folder belongs to another cinematic family.',
        details: {
          'folderId': folderId,
          'targetParentFolderId': targetParentFolderId,
        },
      );
    }
    _assertNameAvailable(
      catalog,
      family: folder.family,
      parentFolderId: targetParentFolderId,
      name: folder.name,
      excludedFolderId: folderId,
    );
    if (parent != null && _isDescendantOf(catalog, parent.id, folderId)) {
      throw CinematicLibraryCatalogMutationException(
        'cinematic_library.cycle',
        'A cinematic library folder cannot be moved into its own subtree.',
        details: {
          'folderId': folderId,
          'targetParentFolderId': targetParentFolderId,
        },
      );
    }
    final siblings =
        catalog.folders
            .where(
              (candidate) =>
                  candidate.id != folderId &&
                  candidate.family == folder.family &&
                  candidate.parentFolderId == targetParentFolderId,
            )
            .toList()
          ..sort(_compareFolderOrder);
    _assertInsertionIndex(targetIndex, siblings.length);
    siblings.insert(
      targetIndex,
      folder.copyWith(parentFolderId: targetParentFolderId),
    );
    final replacements = <String, CinematicLibraryFolder>{
      for (var index = 0; index < siblings.length; index++)
        siblings[index].id: siblings[index].copyWith(sortOrder: index),
    };
    return CinematicLibraryCatalog(
      folders: [
        for (final current in catalog.folders)
          replacements[current.id] ?? current,
      ],
      entries: catalog.entries,
    );
  }
}

void _assertNameAvailable(
  CinematicLibraryCatalog catalog, {
  required CinematicLibraryFamily family,
  required String? parentFolderId,
  required String name,
  String? excludedFolderId,
}) {
  final normalized = name.trim().toLowerCase();
  final collides = catalog.folders.any(
    (folder) =>
        folder.id != excludedFolderId &&
        folder.family == family &&
        folder.parentFolderId == parentFolderId &&
        folder.name.toLowerCase() == normalized,
  );
  if (collides) {
    throw CinematicLibraryCatalogMutationException(
      'cinematic_library.name_collision',
      'A sibling cinematic folder already uses this name.',
      details: {
        'family': family.name,
        'parentFolderId': parentFolderId,
        'name': name,
      },
    );
  }
}

void _assertInsertionIndex(int targetIndex, int siblingCount) {
  if (targetIndex < 0 || targetIndex > siblingCount) {
    throw CinematicLibraryCatalogMutationException(
      'cinematic_library.index_invalid',
      'The target folder index is outside the sibling range.',
      details: {'targetIndex': targetIndex, 'maximum': siblingCount},
    );
  }
}

bool _isDescendantOf(
  CinematicLibraryCatalog catalog,
  String candidateId,
  String ancestorId,
) {
  var current = _requireFolder(catalog, candidateId);
  while (true) {
    if (current.id == ancestorId) return true;
    final parentId = current.parentFolderId;
    if (parentId == null) return false;
    current = _requireFolder(catalog, parentId);
  }
}

CinematicLibraryFolder _requireFolder(
  CinematicLibraryCatalog catalog,
  String folderId,
) {
  for (final folder in catalog.folders) {
    if (folder.id == folderId) return folder;
  }
  throw CinematicLibraryCatalogMutationException(
    'cinematic_library.folder_unknown',
    'The cinematic library folder is unknown.',
    details: {'folderId': folderId},
  );
}

CinematicLibraryEntry _requireEntry(
  CinematicLibraryCatalog catalog,
  CinematicLibraryFamily family,
  String cinematicId,
) {
  final entry = catalog.entryFor(family, cinematicId);
  if (entry != null) return entry;
  throw CinematicLibraryCatalogMutationException(
    'cinematic_library.entry_unknown',
    'The cinematic library entry is unknown.',
    details: {'family': family.name, 'cinematicId': cinematicId},
  );
}

List<CinematicLibraryEntry> _normalizeEntryOrders(
  Iterable<CinematicLibraryEntry> entries,
) {
  final groups = <String, List<CinematicLibraryEntry>>{};
  for (final entry in entries) {
    final key = '${entry.family.name}|${entry.folderId ?? ''}';
    groups.putIfAbsent(key, () => []).add(entry);
  }
  final normalized = <CinematicLibraryEntry>[];
  for (final group in groups.values) {
    group.sort(_compareEntryOrder);
    for (var index = 0; index < group.length; index++) {
      normalized.add(group[index].copyWith(sortOrder: index));
    }
  }
  return normalized;
}

String _entryKey(CinematicLibraryEntry entry) =>
    '${entry.family.name}|${entry.cinematicId}';

int _compareFolderOrder(
  CinematicLibraryFolder left,
  CinematicLibraryFolder right,
) {
  final order = left.sortOrder.compareTo(right.sortOrder);
  return order != 0 ? order : left.id.compareTo(right.id);
}

int _compareEntryOrder(
  CinematicLibraryEntry left,
  CinematicLibraryEntry right,
) {
  final order = left.sortOrder.compareTo(right.sortOrder);
  return order != 0 ? order : left.cinematicId.compareTo(right.cinematicId);
}
