import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final wire = <String, dynamic>{
    'id': 'travel-device',
    'label': 'Carnet de voyage',
    'acquiredFactId': 'has-device',
    'emptyMessage': 'Aucun contact enregistré.',
    'contacts': [
      {
        'id': 'mentor',
        'label': 'Mentor',
        'registeredFactId': 'knows-mentor',
        'availableFactId': 'mentor-available',
        'sceneId': 'mentor-call',
        'unavailableSceneId': 'mentor-busy',
        'characterId': 'mentor-character',
      },
    ],
  };

  test(
    'device and authored conversations round trip without game identifiers',
    () {
      final device = ProjectContactDeviceConfig.fromJson(wire);
      expect(device.toJson(), wire);
      expect(device.contacts.single.id, 'mentor');
      expect(device.contacts.single.sceneId, 'mentor-call');
    },
  );

  test('duplicate contacts and duplicate registration facts are rejected', () {
    final contact = (wire['contacts'] as List).single;
    expect(
      () => ProjectContactDeviceConfig.fromJson({
        ...wire,
        'contacts': [contact, contact],
      }),
      throwsFormatException,
    );
    expect(
      () => ProjectContactDeviceConfig.fromJson({
        ...wire,
        'contacts': [
          contact,
          {...contact as Map, 'id': 'another'},
        ],
      }),
      throwsFormatException,
    );
  });

  test(
    'empty names, unresolved routing and unknown wire fields fail closed',
    () {
      for (final field in ['id', 'label', 'acquiredFactId', 'emptyMessage']) {
        expect(
          () => ProjectContactDeviceConfig.fromJson({...wire, field: ''}),
          throwsFormatException,
        );
      }
      expect(
        () => ProjectContactDeviceConfig.fromJson({...wire, 'network': true}),
        throwsFormatException,
      );
      final contact = Map<String, dynamic>.from(
        (wire['contacts'] as List).single as Map,
      );
      contact.remove('unavailableSceneId');
      expect(
        () => ProjectContactDeviceConfig.fromJson({
          ...wire,
          'contacts': [contact],
        }),
        throwsFormatException,
      );
    },
  );

  test('project validation rejects dangling contact facts and scenes', () {
    final project = ProjectManifest(
      name: 'Adventure',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
      ),
      maps: [],
      tilesets: [],
      contactDevice: ProjectContactDeviceConfig.fromJson(wire),
    );
    expect(
      () => ProjectValidator.validate(project),
      throwsA(isA<ValidationException>()),
    );
    expect(
      ProjectContactDeviceConfig.fromJson(
        wire,
      ).referenceErrors(facts: [], sceneIds: {}, characterIds: {}),
      hasLength(6),
    );
  });
  test('2D projects reject a contact configuration explicitly', () {
    final project = ProjectManifest(
      name: 'Adventure',
      maps: [],
      tilesets: [],
      contactDevice: ProjectContactDeviceConfig.fromJson(wire),
    );
    expect(
      () => ProjectValidator.validate(project),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.toString(),
          'message',
          contains('requires a 3D project'),
        ),
      ),
    );
  });
}
