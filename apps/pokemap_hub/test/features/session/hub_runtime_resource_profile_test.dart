import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_startup_bootstrap.dart';

void main() {
  const mebibyte = 1024 * 1024;

  test('3D sessions get the same resident budget as 2D sessions', () {
    final spatial = hubRuntimeResourceProfile(spatial: true);
    final flat = hubRuntimeResourceProfile(spatial: false);
    expect(spatial.maximumResidentBytes, 256 * mebibyte);
    expect(spatial.maximumResidentBytes, flat.maximumResidentBytes);
  });

  test('3D sessions keep the default decode staging and concurrency', () {
    final spatial = hubRuntimeResourceProfile(spatial: true);
    const defaults = RuntimeResourceProfile();
    expect(spatial.maximumTransientBytes, defaults.maximumTransientBytes);
    expect(spatial.maximumConcurrentDecodes, defaults.maximumConcurrentDecodes);
    expect(spatial.maximumEncodedBytes, defaults.maximumEncodedBytes);
  });

  test('2D sessions keep their existing profile', () {
    final flat = hubRuntimeResourceProfile(spatial: false);
    expect(flat.maximumResidentBytes, 256 * mebibyte);
    expect(flat.maximumTransientBytes, 256 * mebibyte);
    expect(flat.maximumConcurrentDecodes, 1);
  });

  test('a 3D budget admits a map plus neighbours above the former 64 MiB',
      () async {
    final budget = RuntimeResourceBudget(
      profile: hubRuntimeResourceProfile(spatial: true),
    );
    final leases = <RuntimeResourceReservation>[];
    for (var index = 0; index < 6; index++) {
      final lease = await budget.acquire(residentBytes: 20 * mebibyte);
      lease.commit();
      leases.add(lease);
    }
    expect(budget.residentBytes, 120 * mebibyte);
    await expectLater(
      budget.acquire(residentBytes: 137 * mebibyte),
      throwsA(isA<RuntimeResourceAdmissionException>()),
    );
    for (final lease in leases) {
      lease.release();
    }
    expect(budget.residentBytes, 0);
  });
}
