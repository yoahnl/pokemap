part of 'map_host_fixture.dart';

extension MapHostFixtureDisk on MapHostFixture {
  Future<Map<String, List<int>>> disk() async => (await tester.runAsync(
    () async => {
      for (final file
          in await source.directory
              .list(recursive: true)
              .where(
                (file) => file is File && !file.path.contains('/.pokemap/'),
              )
              .cast<File>()
              .toList())
        file.path.substring(source.directory.path.length): await file
            .readAsBytes(),
    },
  ))!;
}
