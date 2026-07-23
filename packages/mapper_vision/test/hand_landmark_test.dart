import 'package:mapper_core/mapper_core.dart';
import 'package:mapper_vision/mapper_vision.dart';
import 'package:test/test.dart';

void main() {
  final service = HandLandmarkService();

  test('Classifies point gesture correctly', () {
    final landmarks = List.generate(21, (i) => HandLandmark(id: i, x: 0.5, y: 0.5));
    // Index finger extended (y smaller than PIP)
    landmarks[6] = const HandLandmark(id: 6, x: 0.5, y: 0.4);
    landmarks[8] = const HandLandmark(id: 8, x: 0.5, y: 0.2); // tip higher

    // Middle, ring, pinky folded (y larger than PIP)
    landmarks[10] = const HandLandmark(id: 10, x: 0.5, y: 0.4);
    landmarks[12] = const HandLandmark(id: 12, x: 0.5, y: 0.5);

    landmarks[14] = const HandLandmark(id: 14, x: 0.5, y: 0.4);
    landmarks[16] = const HandLandmark(id: 16, x: 0.5, y: 0.5);

    landmarks[18] = const HandLandmark(id: 18, x: 0.5, y: 0.4);
    landmarks[20] = const HandLandmark(id: 20, x: 0.5, y: 0.5);

    final gesture = service.classify(landmarks);
    expect(gesture, equals(HandGesture.point));
  });

  test('Finds nearest scene object when pointing', () {
    final fingertip = const HandLandmark(id: 8, x: 0.2, y: 0.25);
    final objects = [
      SceneObject(
        id: 'obj1',
        label: 'Target',
        bboxCamera: const NormalizedBBox(left: 0.1, top: 0.1, width: 0.2, height: 0.3),
      ),
      SceneObject(
        id: 'obj2',
        label: 'Far Object',
        bboxCamera: const NormalizedBBox(left: 0.8, top: 0.8, width: 0.1, height: 0.1),
      ),
    ];

    final targetId = service.findTargetObjectId(fingertip, objects);
    expect(targetId, equals('obj1'));
  });
}
