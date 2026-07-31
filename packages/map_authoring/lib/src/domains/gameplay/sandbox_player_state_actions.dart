import '../../contracts/action_descriptor.dart';

/// Public MCP/action catalog for the detached gameplay sandbox. These actions
/// are deliberately absent from the project mutation dispatcher.
abstract final class SandboxPlayerStateActions {
  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const [
      ('sandbox.state.inspect', AuthoringRiskLevel.readOnly),
      ('sandbox.state.diff', AuthoringRiskLevel.readOnly),
      ('sandbox.save.migrate', AuthoringRiskLevel.low),
      ('sandbox.party.recover', AuthoringRiskLevel.low),
      ('sandbox.pc.deposit', AuthoringRiskLevel.low),
      ('sandbox.pc.withdraw', AuthoringRiskLevel.low),
      ('sandbox.bag.give', AuthoringRiskLevel.low),
      ('sandbox.bag.consume', AuthoringRiskLevel.low),
      ('sandbox.shop.purchase', AuthoringRiskLevel.low),
      ('sandbox.shop.sell', AuthoringRiskLevel.low),
    ])
      AuthoringActionDescriptor(
        id: entry.$1,
        version: 1,
        summary: 'Operate on detached sandbox player state only',
        inputSchemaId: 'pokemap.authoring/${entry.$1}.input.v1',
        outputSchemaId: 'pokemap.authoring/${entry.$1}.output.v1',
        riskLevel: entry.$2,
        resourceKinds: const ['sandboxPlayerState'],
        capabilityIds: const ['authoring.sandbox.playerState'],
        requiredPermissions: const [AuthoringPermission.playtestControl],
        guarantees: const [AuthoringGuarantee.dryRun],
        extensions: const {'productionWriteAllowed': false},
      ),
  ]);
}
