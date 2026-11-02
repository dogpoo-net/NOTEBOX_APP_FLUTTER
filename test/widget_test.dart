import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebox/main.dart';

void main() {
  testWidgets('capture, search and edit preserve Markdown', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.enterText(find.byType(TextField).first, '# 생각\n연결하기');
    await tester.pump();
    await tester.tap(find.text('기록함에 담기'));
    await tester.pump();
    expect(find.text('# 생각'), findsOneWidget);
    await tester.ensureVisible(find.text('# 생각'));
    await tester.tap(find.text('# 생각'));
    await tester.pump();
    expect(find.text('# 생각\n연결하기'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '수정한 생각');
    await tester.ensureVisible(find.text('수정 완료'));
    await tester.tap(find.text('수정 완료'));
    await tester.pump();
    expect(find.text('수정한 생각'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '없는 검색어');
    await tester.pump();
    expect(find.text('일치하는 메모가 없어요'), findsOneWidget);
  });
  testWidgets('narrow screen and keyboard fit', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
