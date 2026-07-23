import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapper_desktop/app.dart';

void main() {
  testWidgets('App renders Project Mapping title', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: ProjectMappingApp(),
      ),
    );
    expect(find.text('Project Mapping'), findsWidgets);
  });
}
