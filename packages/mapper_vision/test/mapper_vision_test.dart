import 'package:mapper_vision/mapper_vision.dart';
import 'package:test/test.dart';

void main() {
  test('TrackingState initializes inactive with empty tracks', () {
    final state = TrackingState();
    expect(state.isActive, isFalse);
    expect(state.tracks, isEmpty);
  });
}
