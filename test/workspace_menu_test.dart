import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebox/main.dart';
import 'package:notebox/features/inbox/workspace_menu.dart';

void main() {
  testWidgets('menu opens and launches paragraph editor', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byTooltip('메뉴 열기'));
    await tester.pumpAndSettle();
    expect(find.text('메인'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(WorkspaceMenu),
        matching: find.text('문단 쓰기'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('paragraph-0')), findsOneWidget);
  });
  testWidgets('only project list scrolls while navigation remains fixed', (
    tester,
  ) async {
    int? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                selected = await showDialog<int>(
                  context: context,
                  builder: (_) => WorkspaceMenu(
                    projects: List.generate(30, (i) => '프로젝트 $i'),
                  ),
                );
              },
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.text('메인'));
    await tester.scrollUntilVisible(
      find.text('프로젝트 29'),
      200,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('menu-projects')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(tester.getTopLeft(find.text('메인')), before);
    await tester.tap(find.text('프로젝트 29'));
    await tester.pumpAndSettle();
    expect(selected, 29);
  });
}
