import '../../contracts/authoring_request.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';
import 'narrative_document_actions.dart';
import 'standard_event_template.dart';

final class StandardEventTemplateActions {
  const StandardEventTemplateActions();

  static final descriptor = narrativeActionDescriptor(
    'event_v2.template.apply',
    'Create or edit one coordinated standard event with native conditional pages',
    resourceKinds: const ['project', 'map', 'eventV2', 'scene'],
    extensions: {
      'parameters': {
        'spec': {
          'schemaVersion': 1,
          'requiredFields': [
            'schemaVersion',
            'kind',
            'mapId',
            'entityId',
            'name',
            'parameters'
          ],
          'kinds': [
            for (final kind in StandardEventTemplateKind.values) kind.name
          ],
          'parameterFieldsByKind': {
            for (final kind in StandardEventTemplateKind.values)
              kind.name: {
                'allowed':
                    StandardEventTemplateSpec.parameterFields[kind]!.toList(),
                'required': StandardEventTemplateSpec
                    .requiredParameterFields[kind]!
                    .toList()
              }
          },
          'resourceReferences': 'existingUniqueProjectCatalogEntries',
          'quantity': {'type': 'integer', 'minimum': 1, 'maximum': 9999}
        },
        'mapRevision': {
          'type': 'string',
          'required': true,
          'meaning': 'current map resource bytes fingerprint'
        },
      },
      'dimension': 'twoD',
      'atomicResources': ['project', 'map'],
      'nativeContracts': ['MapEntityPresentation', 'EventV2', 'Scene'],
      'ownership': 'versionedRecipeAndExactRecompileBeforeOverwrite',
      'editing': 'sameKindStableOwnedIds',
      'duplication': 'applyParametersToAnotherEntityWithIndependentOwnedIds',
      'registryMode': 'dualReadOrV2OnlyRequiredNeverImplicitlyChanged',
      'pickupConsumption': 'oneShotOnlyAfterReceivedRetryableBagFull',
      'doorCondition': 'nativeSceneInventoryPredicate',
      'trainerCondition': 'nativeSceneTrainerVictoryPredicate',
      'preview': ['pages', 'conditions', 'actions', 'appearance', 'ownership'],
    },
  );

  Future<AuthoringMutationDraft> prepare(
      AuthoringPlanningContext context) async {
    rejectUnknownNarrativeParameters(
        context.request.parameters, const {'spec', 'mapRevision'});
    final spec = StandardEventTemplateSpec.fromJson(
        narrativeObjectParameter(context.request.parameters, 'spec'));
    final mapRevision =
        narrativeStringParameter(context.request.parameters, 'mapRevision');
    if (spec.parameters.containsKey('itemId') &&
        context.snapshot.itemCatalog == null) {
      throw NarrativeAuthoringException(
          'event_v2.template.item_catalog_unavailable',
          'Chargez le catalogue d’objets avant de créer cet événement.');
    }
    final projection = compileStandardEventTemplate(
        project: context.snapshot.manifest,
        maps: context.snapshot.maps,
        spec: spec,
        itemCatalog: context.snapshot.itemCatalog);
    final request = context.request;
    final publication = await const NarrativeDocumentActions().prepare(
        AuthoringPlanningContext(
            snapshot: context.snapshot,
            planId: context.planId,
            seed: context.seed,
            request: AuthoringRequest(
                requestId: request.requestId,
                actionId: 'narrative.publish_document',
                actionVersion: 1,
                workspaceHandle: request.workspaceHandle,
                expectedRevision: request.expectedRevision,
                idempotencyKey: request.idempotencyKey,
                dryRun: request.dryRun,
                parameters: {
                  'map': projection.map.toJson(),
                  'mapRevision': mapRevision,
                  'scenes':
                      projection.scenes.map((scene) => scene.toJson()).toList(),
                  'events':
                      projection.events.map((event) => event.toJson()).toList()
                })));
    return AuthoringMutationDraft(
        changeSet: publication.changeSet,
        projectedProject: publication.projectedProject,
        preview: {
          ...publication.preview,
          'spec': spec.toJson(),
          'eventIds': projection.events.map((event) => event.id).toList(),
          'sceneIds': projection.scenes.map((scene) => scene.id).toList(),
          'pages': [
            for (final page in projection.pages)
              {
                'id': page.id,
                'label': page.label,
                'condition': page.condition.toJson(),
                'actions': page.actions,
                'appearance': page.appearance.toJson()
              }
          ],
          'ownership': 'exactRecompileRequired',
        });
  }
}
