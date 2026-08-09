import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/infrastructure/riverpod_retry_policy.dart';

void main() {
  test('editor container preserves the Riverpod 2 no-retry behavior', () async {
    var attempts = 0;
    final failingProvider = FutureProvider<int>((ref) async {
      attempts += 1;
      throw Exception('expected failure');
    });
    final container = ProviderContainer(retry: disableAutomaticProviderRetry);
    addTearDown(container.dispose);
    final subscription = container.listen(
      failingProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(attempts, 1);
    expect(container.read(failingProvider), isA<AsyncError<int>>());
  });
}
