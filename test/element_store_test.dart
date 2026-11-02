import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebox/features/inbox/element_store.dart';
import 'package:notebox/features/inbox/paragraph_editor.dart';
import 'package:notebox/features/inbox/project_page.dart';

void main() {
  setUp(elements.clear);
  test(
    'phrase identity, timestamp and longest non-overlapping occurrences',
    () {
      final a = elements.add('작은 생각');
      expect(identical(a, elements.add(' 작은 생각 ')), isTrue);
      expect(a.createdAt.isAfter(DateTime.now()), isFalse);
      elements.add('생각');
      expect(elements.matches('작은 생각, 작은 생각 그리고 생각').map((m) => m.word), [
        '작은 생각',
        '작은 생각',
        '생각',
      ]);
    },
  );
  testWidgets('project adds global phrase but lists only used elements', (
    tester,
  ) async {
    elements.add('작은 생각');
    elements.add('다른 원소');
    final project = WritingProject(
      [const Paragraph('작은 생각', ParagraphRole.body)],
      [],
      name: '시험',
    );
    await tester.pumpWidget(MaterialApp(home: ProjectPage(project: project)));
    await tester.tap(find.text('원소'));
    await tester.pumpAndSettle();
    expect(find.text('작은 생각'), findsOneWidget);
    expect(find.text('다른 원소'), findsNothing);
    await tester.enterText(find.byType(TextField), '새로운 원소');
    await tester.tap(find.text('글로벌 원소 저장'));
    await tester.pumpAndSettle();
    expect(elements.words, contains('새로운 원소'));
    expect(find.text('새로운 원소'), findsNothing);
    await tester.tap(find.text('작은 생각'));
    await tester.pumpAndSettle();
    expect(find.text('사용 1회 · 1개 위치'), findsOneWidget);
    expect(find.text('시험 · 문단 1 · 1회'), findsOneWidget);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('미리보기'));
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getTopLeft(find.text('작은 생각', findRichText: true)) +
          const Offset(20, 12),
    );
    await tester.pumpAndSettle();
    expect(find.text('사용 1회 · 1개 위치'), findsOneWidget);
  });
}
