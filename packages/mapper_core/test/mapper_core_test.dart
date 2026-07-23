import 'package:mapper_core/mapper_core.dart';
import 'package:test/test.dart';

void main() {
  test('creates a default Scene with empty objects', () {
    final scene = Scene(id: 'test-scene', name: 'Test', projectId: 'test-proj');
    expect(scene.id, 'test-scene');
    expect(scene.name, 'Test');
    expect(scene.objects, isEmpty);
  });
}
