import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('sandbox action catalog is explicitly non-production', () {
    expect(
      SandboxPlayerStateActions.descriptors.map((entry) => entry.id),
      containsAll({
        'sandbox.state.inspect',
        'sandbox.state.diff',
        'sandbox.party.recover',
        'sandbox.pc.deposit',
        'sandbox.pc.withdraw',
        'sandbox.bag.give',
        'sandbox.shop.purchase',
      }),
    );
    expect(
      SandboxPlayerStateActions.descriptors.every(
        (entry) => !entry.requiredPermissions.contains(
          AuthoringPermission.projectWrite,
        ),
      ),
      isTrue,
    );
    expect(
      AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((entry) => entry.id),
      isNot(contains('sandbox.bag.give')),
      reason: 'sandbox operations must not enter project mutations',
    );
  });
}
