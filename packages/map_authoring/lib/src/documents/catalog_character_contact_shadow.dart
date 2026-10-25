part of 'character_contact_shadow_authoring.dart';

final class _ContactCatalogSession {
  _ContactCatalogSession(this.descriptorBytes, this.projectId, this.store,
      this.editing, this.ledger, this.idempotency, this.projectDefault);

  final List<int> descriptorBytes;
  final String projectId;
  final CatalogStorageStore store;
  final CatalogEditingSession editing;
  final AuthoringIdempotencyLedger ledger;
  final IdempotencyStore idempotency;
  final bool projectDefault;
  Future<void> _pending = Future.value();

  Future<T> serialize<T>(Future<T> Function() operation) async {
    final previous = _pending;
    final completion = Completer<void>();
    _pending = completion.future;
    await previous;
    try {
      return await operation();
    } finally {
      completion.complete();
    }
  }
}

Map<String, Object?>? _catalogDescriptor(List<int> bytes) {
  if (bytes.length > 4096) return null;
  final raw = jsonDecode(utf8.decode(bytes));
  if (raw is! Map || !raw.containsKey('format')) return null;
  if (raw['format'] != 'avelune.working-catalog') {
    throw const FormatException('The catalog is unsupported or read-only.');
  }
  final descriptor = Map<String, Object?>.from(raw);
  WorkingProjectCatalogDescriptor.fromJson(descriptor);
  return descriptor;
}

extension _CatalogCharacterContactShadow
    on LocalCharacterContactShadowAuthoring {
  Future<void> _prepareCatalog(String root) async {
    final bytes = await _reader.readBytes(
        projectRoot: root, relativePath: 'project.json');
    final descriptor = _catalogDescriptor(bytes);
    if (descriptor == null) return;
    final projectId =
        WorkingProjectCatalogDescriptor.fromJson(descriptor).projectId;
    final gateway = await LocalTransactionFileGateway.open(
        projectRoot: root, expectedProjectRoot: root);
    final store = CatalogStorageStore(
        projectRoot: root, reader: _reader, gateway: gateway);
    final history = await FileAuthoringHistoryStore.open(
        projectRoot: root, incrementalWrites: true);
    final idempotency = FileIdempotencyStore(
        filePath: '$root/.pokemap/authoring/idempotency.jsonl');
    final ledger = AuthoringIdempotencyLedger(store: idempotency);
    final editing = await CatalogEditingSession.open(
        store: store,
        projectId: projectId,
        actorId: _actor.actorId,
        history: history,
        idempotency: ledger,
        faultInjector: _faultInjector);
    try {
      final catalog =
          await PortableProjectCatalog.fromSnapshot(editing.snapshot);
      if (narrativeEventBytesFingerprint(await _reader.readBytes(
              projectRoot: root, relativePath: 'project.json')) !=
          narrativeEventBytesFingerprint(bytes)) {
        throw const FormatException(
            'project.document_revision_conflict: The descriptor changed during preparation.');
      }
      if (_closed) {
        throw StateError('The character shadow authoring service is closed.');
      }
      _catalogs[root] = _ContactCatalogSession(
          List.unmodifiable(bytes),
          projectId,
          store,
          editing,
          ledger,
          idempotency,
          catalog.projectMetadata.settings.actorContactShadowsByDefault);
    } on Object {
      await editing.close();
      rethrow;
    }
  }

  Future<Map<String, Object?>> _inspectCatalog(
      String root, String characterId) async {
    final session = _catalogs[root]!;
    return session.serialize(() async {
      await _requireCatalogCurrent(root, session);
      final character = await _catalogCharacter(session, characterId);
      final value =
          _value(Map<String, dynamic>.from(character.payload['value']! as Map));
      return {
        'revision': 'sha256:${session.editing.snapshot.root.sha256}',
        'characterId': characterId,
        'contactShadow': value,
        'projectDefault': session.projectDefault,
        'effectiveContactShadow': value ?? session.projectDefault
      };
    });
  }

  Future<void> _requireCatalogCurrent(
      String root, _ContactCatalogSession session) async {
    final descriptor = await _reader.readBytes(
        projectRoot: root, relativePath: 'project.json');
    if (narrativeEventBytesFingerprint(descriptor) !=
            narrativeEventBytesFingerprint(session.descriptorBytes) ||
        await session.store.readHead() != session.editing.snapshot.root) {
      throw const FormatException(
          'project.document_revision_conflict: The catalog changed; reopen before editing.');
    }
  }

  Future<CatalogDefinitionUnit> _catalogCharacter(
      _ContactCatalogSession session, String id) async {
    final unit = await session.editing.snapshot
        .lookup(CatalogDefinitionKey(CatalogDefinitionKind.character, id));
    if (unit == null ||
        unit.payload['section'] != 'characters' ||
        unit.payload['value'] is! Map) {
      throw const FormatException(
          'The character identity is missing or ambiguous.');
    }
    final value = Map<String, dynamic>.from(unit.payload['value']! as Map);
    if (ProjectCharacterEntry.fromJson(value).id != id) {
      throw const FormatException(
          'The character identity does not match its catalog key.');
    }
    return unit;
  }

  Future<CharacterContactShadowMutation> _setCatalog(
      String root,
      List<int> descriptorBytes,
      String expectedRevision,
      String characterId,
      bool? enabled,
      String operationId,
      FutureOr<void> Function()? precondition) async {
    final session = _catalogs[root];
    if (session == null) {
      throw const FormatException(
          'catalog.preparation_required: Open this character before saving its shadow.');
    }
    return session.serialize(() async {
      if (narrativeEventBytesFingerprint(descriptorBytes) !=
          narrativeEventBytesFingerprint(session.descriptorBytes)) {
        throw const FormatException(
            'project.document_revision_conflict: The descriptor changed before replay or mutation.');
      }
      final request = AuthoringRequest(
          requestId: operationId,
          actionId: LocalCharacterContactShadowAuthoring.descriptor.id,
          actionVersion: 1,
          workspaceHandle: session.projectId,
          parameters: {'characterId': characterId, 'enabled': enabled},
          expectedRevision: expectedRevision,
          idempotencyKey: operationId,
          extensions: {'history': AuthoringHistoryContext().toJson()});
      final scope = AuthoringIdempotencyScope(
          actorId: _actor.actorId,
          projectId: session.projectId,
          actionId: request.actionId,
          actionVersion: 1,
          key: operationId);
      final record = await session.idempotency.read(scope);
      if (record != null) {
        if (record.payloadFingerprint !=
                computeAuthoringIdempotencyPayloadFingerprint(request) ||
            record.operationId != operationId) {
          throw AuthoringIdempotencyException(
              code: 'idempotency.payload_conflict',
              message:
                  'This operation already owns a different character mutation.');
        }
        var receipt = record.receipt;
        final recovered = record.status != AuthoringIdempotencyStatus.completed;
        if (recovered) {
          if (!_actor.allows(AuthoringPermissionScope.recoveryApply)) {
            throw const FormatException(
                'recovery.apply permission is required.');
          }
          receipt = await session.editing.reconcile(operationId,
              precondition: () async {
            final current = await _reader.readBytes(
                projectRoot: root, relativePath: 'project.json');
            if (narrativeEventBytesFingerprint(current) !=
                narrativeEventBytesFingerprint(session.descriptorBytes)) {
              throw const FormatException(
                  'project.document_revision_conflict: The descriptor changed before recovery.');
            }
          });
        }
        if (receipt == null) {
          throw const FormatException(
              'The catalog operation has no durable receipt.');
        }
        _requireCatalogReceipt(receipt, request);
        return _finishReplay(
            root,
            session.projectId,
            request,
            scope,
            session.ledger,
            session.store.gateway as LocalTransactionFileGateway,
            receipt,
            recovered: recovered);
      }
      await _requireCatalogCurrent(root, session);
      final beforeRoot = session.editing.snapshot.root;
      if ('sha256:${beforeRoot.sha256}' != expectedRevision) {
        throw const FormatException(
            'project.document_revision_conflict: The catalog changed before this edit.');
      }
      final unit = await _catalogCharacter(session, characterId);
      final value = Map<String, dynamic>.from(unit.payload['value']! as Map);
      final beforeValue = _value(value);
      if (enabled == null) {
        value.remove('contactShadow');
      } else {
        value['contactShadow'] = enabled;
      }
      final replacement = CatalogDefinitionUnit(
          key: unit.key,
          payload: {...unit.payload, 'value': value},
          references: unit.references);
      final preview =
          await session.editing.snapshot.patch(upserts: [replacement]);
      if (preview.isEmpty) {
        throw const FormatException(
            'catalog.no_changes: This character already has the requested shadow value.');
      }
      final afterRoot = preview.root;
      final diff = AuthoringDiff([
        AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: AuthoringResourceRef(kind: 'catalogHead', id: 'catalog'),
            path: '/characters/$characterId/contactShadow',
            before: beforeValue,
            after: enabled,
            extensions: {
              'documentBeforeRevision': expectedRevision,
              'documentAfterRevision': 'sha256:${afterRoot.sha256}',
              'catalogBeforeRoot': beforeRoot.toJson(),
              'catalogAfterRoot': afterRoot.toJson()
            }),
        revisionHistoryDiff(
            AuthoringResourceRef(kind: 'catalogHead', id: 'catalog'),
            beforeRevision: computeAuthoringBytesFingerprint(
                CatalogStorageStore.encodeHead(beforeRoot),
                logicalName: CatalogStorageStore.headStorageKey),
            afterRevision: computeAuthoringBytesFingerprint(
                CatalogStorageStore.encodeHead(afterRoot),
                logicalName: CatalogStorageStore.headStorageKey))
      ]);
      final now = DateTime.now();
      final publicPlan = AuthoringPlan(
          planId: _identity('plan_document_'),
          receiptId: _identity('receipt_document_'),
          request: request,
          baseRevision: expectedRevision,
          seed: 0,
          createdAt: now,
          expiresAt: now.add(const Duration(minutes: 10)),
          changeSet: AuthoringChangeSet(changes: [
            AuthoringResourceChange(
                resource:
                    AuthoringResourceRef(kind: 'catalogHead', id: 'catalog'),
                storageKey: CatalogStorageStore.headStorageKey,
                beforeBytes: CatalogStorageStore.encodeHead(beforeRoot),
                afterBytes: CatalogStorageStore.encodeHead(afterRoot))
          ], diff: diff));
      final prepared = await session.editing.planPatch(
          upserts: [replacement],
          publicPlan: publicPlan,
          publicDiff: diff,
          request: request,
          idempotencyKey: operationId);
      try {
        final authorization = AuthoringAuthorizationPolicy(
            confirmations: AuthoringConfirmationStore(clock: DateTime.now),
            clock: DateTime.now);
        authorization.authorize(AuthoringAuthorizationRequest(
            actor: _actor,
            projectId: session.projectId,
            operation: AuthoringSecurityOperation.apply,
            actionId: request.actionId,
            actionVersion: 1,
            riskLevel:
                LocalCharacterContactShadowAuthoring.descriptor.riskLevel,
            requestBytes: prepared.plan.authorizationRequestBytes,
            touchedResources: 1,
            planId: prepared.plan.planId,
            operationId: operationId,
            additionalPermissions: const [
              AuthoringPermissionScope.projectWrite
            ]));
        final receipt = await session.editing
            .apply(prepared, operationId: operationId, precondition: () async {
          await precondition?.call();
          final currentDescriptor = await _reader.readBytes(
              projectRoot: root, relativePath: 'project.json');
          if (narrativeEventBytesFingerprint(currentDescriptor) !=
              narrativeEventBytesFingerprint(descriptorBytes)) {
            throw const FormatException(
                'project.document_revision_conflict: The descriptor changed before publication.');
          }
        });
        await _catalogAudit(
            root,
            session.projectId,
            request,
            prepared.plan.planId,
            receipt.receiptId,
            AuthoringAuditDecision.succeeded,
            'mutation.succeeded');
        return CharacterContactShadowMutation.fromReceipt(receipt);
      } on AuthoringTransactionSimulatedCrash {
        rethrow;
      } on Object {
        await _catalogAudit(
            root,
            session.projectId,
            request,
            prepared.plan.planId,
            null,
            AuthoringAuditDecision.failed,
            'mutation.failed');
        rethrow;
      } finally {
        await prepared.plan.releaseAppliedPayload();
      }
    });
  }

  Future<void> _catalogAudit(
      String root,
      String projectId,
      AuthoringRequest request,
      String planId,
      String? receiptId,
      AuthoringAuditDecision decision,
      String code) async {
    final audit = await FileAuthoringAuditLog.open(
        projectRoot: root, incrementalWrites: true);
    await audit.append(AuthoringAuditRecord(
        auditId: _identity('audit_document_'),
        actorId: _actor.actorId,
        projectId: projectId,
        operation: AuthoringSecurityOperation.apply,
        decision: decision,
        requestId: request.requestId,
        actionId: request.actionId,
        actionVersion: 1,
        riskLevel: LocalCharacterContactShadowAuthoring.descriptor.riskLevel,
        planId: planId,
        receiptId: receiptId,
        code: code,
        timestamp: DateTime.now()));
  }
}

void _requireCatalogReceipt(
    AuthoringReceipt receipt, AuthoringRequest request) {
  final flag = receipt.diff.entries
      .where((entry) => entry.path.endsWith('/contactShadow'))
      .single;
  final head = receipt.diff.entries
      .where((entry) =>
          entry.resource.kind == 'catalogHead' &&
          entry.resource.id == 'catalog' &&
          entry.path == r'$')
      .single;
  final before = CatalogObjectReference.fromJson(
      Map<String, dynamic>.from(flag.extensions['catalogBeforeRoot']! as Map));
  final after = CatalogObjectReference.fromJson(
      Map<String, dynamic>.from(flag.extensions['catalogAfterRoot']! as Map));
  if (request.expectedRevision != 'sha256:${before.sha256}' ||
      flag.extensions['documentAfterRevision'] != 'sha256:${after.sha256}' ||
      head.before !=
          computeAuthoringBytesFingerprint(
              CatalogStorageStore.encodeHead(before),
              logicalName: CatalogStorageStore.headStorageKey) ||
      head.after !=
          computeAuthoringBytesFingerprint(
              CatalogStorageStore.encodeHead(after),
              logicalName: CatalogStorageStore.headStorageKey)) {
    throw const FormatException(
        'The catalog replay does not match its generation change.');
  }
}
