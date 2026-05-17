import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapper_core/mapper_core.dart';

import '../../providers/app_state.dart';
import '../presentation/presentation_screen.dart';
import '../scene_editor/scene_editor_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appStateProvider);
    final scene = ref.watch(sceneStoreProvider).activeScene;

    return Scaffold(
      appBar: AppBar(
        title: Text('Project Mapping · ${scene?.name ?? "..."}'),
        actions: [
          SegmentedButton<AppMode>(
            segments: const [
              ButtonSegment(
                value: AppMode.setup,
                label: Text('Setup'),
                icon: Icon(Icons.tune),
              ),
              ButtonSegment(
                value: AppMode.rehearsal,
                label: Text('Ensayo'),
                icon: Icon(Icons.visibility_outlined),
              ),
              ButtonSegment(
                value: AppMode.show,
                label: Text('Show'),
                icon: Icon(Icons.play_arrow),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) {
              ref.read(appStateProvider.notifier).setMode(s.first);
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: switch (mode) {
        AppMode.setup => const SceneEditorScreen(),
        AppMode.rehearsal => const PresentationScreen(),
        AppMode.show => const PresentationScreen(),
      },
    );
  }
}
