import 'package:mapper_core/mapper_core.dart';
import 'package:test/test.dart';

void main() {
  test('identity homography preserves bbox center', () {
    const bbox = NormalizedBBox(left: 0.2, top: 0.3, width: 0.4, height: 0.2);
    final out = Homography.identity.transformBBox(bbox);
    expect(out.centerX, closeTo(bbox.centerX, 1e-6));
    expect(out.centerY, closeTo(bbox.centerY, 1e-6));
  });

  test('four point homography is computable', () {
    final h = Homography.fromCorrespondences(
      source: const [
        Point2D(0, 0),
        Point2D(1, 0),
        Point2D(1, 1),
        Point2D(0, 1),
      ],
      destination: const [
        Point2D(0.1, 0.1),
        Point2D(0.9, 0.05),
        Point2D(0.95, 0.9),
        Point2D(0.05, 0.85),
      ],
    );
    expect(h, isNotNull);
    expect(h!.matrix.length, 9);
  });
}
