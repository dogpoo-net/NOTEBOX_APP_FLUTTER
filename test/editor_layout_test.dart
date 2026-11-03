import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebox/features/inbox/paragraph_editor.dart';

void main() {
  testWidgets('mobile web viewport shrink also reveals the bottom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: ParagraphEditor(
          words: const ['기억'],
          initial: List.generate(
            8,
            (i) => Paragraph(i == 0 ? '' : '문단 $i', ParagraphRole.body),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('paragraph-0')));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(390, 524);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    final list = find.byKey(const ValueKey('paragraph-scroll'));
    final scroll = tester.widget<ListView>(list).controller!;
    expect(scroll.offset, closeTo(scroll.position.maxScrollExtent, 1));
    expect(
      tester.getRect(find.text('다음 문단')).bottom,
      lessThan(tester.getRect(find.byKey(const ValueKey('assist-popup'))).top),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'keyboard opening scrolls to bottom without shrinking body for assist',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(
        MaterialApp(
          home: ParagraphEditor(
            words: const ['기억'],
            initial: List.generate(
              8,
              (i) => Paragraph(i == 0 ? '' : '문단 $i', ParagraphRole.body),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('paragraph-0')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      final list = find.byKey(const ValueKey('paragraph-scroll'));
      final controller = tester.widget<ListView>(list).controller!;
      expect(
        controller.offset,
        closeTo(controller.position.maxScrollExtent, 1),
      );
      expect(tester.getBottomRight(list).dy, closeTo(524, 1));
      expect(
        tester.getRect(find.text('다음 문단')).bottom,
        lessThan(
          tester.getRect(find.byKey(const ValueKey('assist-popup'))).top,
        ),
      );
      await tester.drag(list, const Offset(0, 100));
      await tester.pumpAndSettle();
      final offset = controller.offset;
      await tester.pump(const Duration(seconds: 1));
      expect(controller.offset, offset);
      expect(offset, lessThan(controller.position.maxScrollExtent));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('mobile candidates scroll inside a fixed bottom-left panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        home: ParagraphEditor(
          words: List.generate(40, (i) => '원소${i.toString().padLeft(2, '0')}'),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('paragraph-0')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final popup = find.byKey(const ValueKey('assist-popup'));
    final bounds = tester.getRect(popup);
    expect(bounds.left, 12);
    expect(bounds.bottom, lessThanOrEqualTo(544));
    final scroll = find.descendant(
      of: popup,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('suggestion-원소39')),
      100,
      scrollable: scroll,
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(popup), bounds);
    await tester.tap(find.byKey(const ValueKey('suggestion-원소39')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('paragraph-0')))
          .controller!
          .text,
      '원소39',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('project preview uses unsaved text and returns intact', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ParagraphEditor(
          projectEditing: true,
          words: [],
          initial: [Paragraph('기존 제목', ParagraphRole.title)],
        ),
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('paragraph-0')), '변경한 제목');
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('미리보기')).dx,
      lessThan(tester.getCenter(find.text('저장')).dx),
    );
    await tester.tap(find.text('미리보기'));
    await tester.pumpAndSettle();
    expect(find.text('변경한 제목'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('paragraph-0')))
          .controller!
          .text,
      '변경한 제목',
    );
  });
  testWidgets('RTL assist stays above keyboard and survives scroll', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const ParagraphEditor(
          words: ['كتاب'],
          initial: [
            Paragraph('', ParagraphRole.body),
            Paragraph('second', ParagraphRole.body),
            Paragraph('third', ParagraphRole.body),
          ],
        ),
      ),
    );
    await tester.enterText(find.byKey(const ValueKey('paragraph-0')), 'ك');
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('suggestion-كتاب')), findsOneWidget);
    expect(
      tester.getBottomRight(find.byKey(const ValueKey('assist-popup'))).dy,
      lessThanOrEqualTo(544),
    );
    final popupBefore = tester.getRect(
      find.byKey(const ValueKey('assist-popup')),
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('assist-popup')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey('assist-popup'))),
      popupBefore,
    );
    expect(
      tester.getBottomRight(find.byType(ListView).first).dy,
      closeTo(544, 1),
    );
    expect(tester.takeException(), isNull);
  });
}
