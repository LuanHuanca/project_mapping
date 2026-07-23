import 'package:mapper_core/mapper_core.dart';
import 'package:mapper_vision/mapper_vision.dart';
import 'package:test/test.dart';

void main() {
  test('BboxTracker resets and tracks object positions', () {
    final tracker = BboxTracker();
    final obj = SceneObject(
      id: 'obj1',
      label: 'Box',
      bboxCamera: const NormalizedBBox(left: 0.1, top: 0.1, width: 0.2, height: 0.2),
    );

    tracker.resetFromScene([obj]);
    expect(tracker.state.tracks.containsKey('obj1'), isTrue);

    tracker.tick();
    final updated = tracker.applyToObjects([obj]);
    expect(updated.first.bboxCamera.left, closeTo(0.1, 1e-4));
  });

  test('BboxTracker clamps coordinates strictly in range 0..1', () {
    final tracker = BboxTracker();
    final obj = SceneObject(
      id: 'outOfBounds',
      label: 'Overflow',
      bboxCamera: const NormalizedBBox(left: -0.5, top: 1.5, width: 2.0, height: 2.0),
    );

    tracker.resetFromScene([obj]);
    final trackedBbox = tracker.state.tracks['outOfBounds']!.bboxCamera;

    expect(trackedBbox.left, greaterThanOrEqualTo(0.0));
    expect(trackedBbox.top, lessThanOrEqualTo(0.95));
  });
}
