import '../models/bounding_box.dart';
import 'point2d.dart';

/// Computes a 3x3 homography (row-major) from 4 point correspondences
/// using the Direct Linear Transform (DLT) for planar mapping.
class Homography {
  Homography(this.matrix);

  /// Row-major 3x3.
  final List<double> matrix;

  static const identity = Homography([
    1, 0, 0,
    0, 1, 0,
    0, 0, 1,
  ]);

  static Homography? fromCorrespondences({
    required List<Point2D> source,
    required List<Point2D> destination,
  }) {
    if (source.length != 4 || destination.length != 4) return null;

    final a = List.generate(8, (_) => List<double>.filled(8, 0));
    final b = List<double>.filled(8, 0);

    for (var i = 0; i < 4; i++) {
      final sx = source[i].x;
      final sy = source[i].y;
      final dx = destination[i].x;
      final dy = destination[i].y;

      final r1 = i * 2;
      final r2 = r1 + 1;

      a[r1][0] = -sx;
      a[r1][1] = -sy;
      a[r1][2] = -1;
      a[r1][6] = sx * dx;
      a[r1][7] = sy * dx;
      b[r1] = -dx;

      a[r2][3] = -sx;
      a[r2][4] = -sy;
      a[r2][5] = -1;
      a[r2][6] = sx * dy;
      a[r2][7] = sy * dy;
      b[r2] = -dy;
    }

    final h = _solveLinear8x8(a, b);
    if (h == null) return null;

    return Homography([
      h[0], h[1], h[2],
      h[3], h[4], h[5],
      h[6], h[7], 1.0,
    ]);
  }

  Point2D transform(Point2D p) {
    final x = p.x;
    final y = p.y;
    final w = matrix[6] * x + matrix[7] * y + matrix[8];
    if (w.abs() < 1e-9) return p;
    final nx = (matrix[0] * x + matrix[1] * y + matrix[2]) / w;
    final ny = (matrix[3] * x + matrix[4] * y + matrix[5]) / w;
    return Point2D(nx, ny);
  }

  NormalizedBBox transformBBox(NormalizedBBox bbox) {
    final corners = [
      Point2D(bbox.left, bbox.top),
      Point2D(bbox.right, bbox.top),
      Point2D(bbox.right, bbox.bottom),
      Point2D(bbox.left, bbox.bottom),
    ];
    final mapped = corners.map(transform).toList();
    final xs = mapped.map((p) => p.x);
    final ys = mapped.map((p) => p.y);
    final left = xs.reduce((a, b) => a < b ? a : b);
    final right = xs.reduce((a, b) => a > b ? a : b);
    final top = ys.reduce((a, b) => a < b ? a : b);
    final bottom = ys.reduce((a, b) => a > b ? a : b);
    return NormalizedBBox(
      left: left,
      top: top,
      width: (right - left).clamp(0.01, 1.0),
      height: (bottom - top).clamp(0.01, 1.0),
    );
  }

  static List<double>? _solveLinear8x8(List<List<double>> a, List<double> b) {
    final n = 8;
    final aug = List.generate(
      n,
      (i) => [...a[i], b[i]],
    );

    for (var col = 0; col < n; col++) {
      var pivot = col;
      for (var row = col + 1; row < n; row++) {
        if (aug[row][col].abs() > aug[pivot][col].abs()) pivot = row;
      }
      if (aug[pivot][col].abs() < 1e-12) return null;
      final tmp = aug[col];
      aug[col] = aug[pivot];
      aug[pivot] = tmp;

      final div = aug[col][col];
      for (var j = col; j <= n; j++) {
        aug[col][j] /= div;
      }

      for (var row = 0; row < n; row++) {
        if (row == col) continue;
        final factor = aug[row][col];
        for (var j = col; j <= n; j++) {
          aug[row][j] -= factor * aug[col][j];
        }
      }
    }

    return List.generate(n, (i) => aug[i][n]);
  }
}
