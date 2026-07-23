import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final api = ref.watch(appStateProvider.notifier).api;
    final isCloudEnabled = api != null;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.blur_on, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Project Mapping',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isCloudEnabled
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : const Color(0xFF6366F1).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isCloudEnabled
                                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                    : const Color(0xFF6366F1).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isCloudEnabled ? Icons.cloud_done : Icons.dns_outlined,
                                  size: 12,
                                  color: isCloudEnabled
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF818CF8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCloudEnabled ? 'Cloud Sync' : 'Modo Local',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isCloudEnabled
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF818CF8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        scene?.name ?? 'Cargando escena...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
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
                        icon: Icon(Icons.grid_4x4),
                      ),
                      ButtonSegment(
                        value: AppMode.show,
                        label: Text('Show'),
                        icon: Icon(Icons.play_arrow_rounded),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) {
                      ref.read(appStateProvider.notifier).setMode(s.first);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: 300.ms,
        child: switch (mode) {
          AppMode.setup => const SceneEditorScreen(),
          AppMode.rehearsal => const PresentationScreen(),
          AppMode.show => const PresentationScreen(),
        },
      ),
    );
  }
}
