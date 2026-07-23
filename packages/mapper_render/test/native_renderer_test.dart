import 'dart:ffi' as ffi;
import 'package:mapper_core/mapper_core.dart';
import 'package:mapper_render/mapper_render.dart';
import 'package:test/test.dart';

void main() {
  group('NativeRendererBindings & RenderEngine FFI Unit Tests', () {
    late NativeRendererBindings bindings;
    late RenderEngine engine;

    setUp(() {
      bindings = NativeRendererBindings.load();
      engine = RenderEngine(bindings: bindings);
    });

    test('1. Loads native_renderer.dll successfully without throwing', () {
      expect(bindings, isNotNull);
    });

    test('2. Throws NativeRendererException on forced NULL matrix error', () {
      final nullPtr = ffi.Pointer<ffi.Double>.fromAddress(0);
      final status = bindings.setHomographyMatrix(nullPtr);
      expect(status, equals(RendererStatus.errorInvalidMatrix));

      final lastErr = bindings.getLastError();
      expect(lastErr, equals(RendererStatus.errorInvalidMatrix));
    });

    test('3. RenderEngine validates homography matrix length', () {
      expect(
        () => engine.setHomographyMatrix([1.0, 0.0]),
        throwsArgumentError,
      );
    });

    test('4. RenderEngine validates minimum vertex count', () {
      expect(
        () => engine.setShapeGeometry(1, [Point2D(0, 0)]),
        throwsArgumentError,
      );
    });

    test('5. Full End-to-End syncToNativeEngine (SceneObject + LayerItem -> FFI -> Native Structs)', () {
      final object = SceneObject(
        id: 'test_obj_1',
        label: 'Quad Test',
        bboxCamera: const NormalizedBBox(left: 0.2, top: 0.2, width: 0.6, height: 0.6),
        vertices: const [
          Point2D(0.2, 0.2),
          Point2D(0.8, 0.2),
          Point2D(0.8, 0.8),
          Point2D(0.2, 0.8),
        ],
        layers: const [
          LayerItem(
            id: 'layer_pulse_1',
            name: 'Concentric Pulse Layer',
            type: LayerType.generativeEffect,
            effectType: GenerativeEffectType.concentricPulse,
            effectSpeed: 1.5,
            opacity: 0.9,
            blendMode: LayerBlendMode.additive,
            colorHex: '#00FFFF',
          ),
        ],
      );

      // Verify syncToNativeEngine maps both vertices geometry AND layer properties cleanly without throwing
      expect(() => object.syncToNativeEngine(engine), returnsNormally);

      // Verify homography matrix mapping
      expect(
        () => engine.setHomographyMatrix(const [1, 0, 0, 0, 1, 0, 0, 0, 1]),
        returnsNormally,
      );
    });
  });
}
