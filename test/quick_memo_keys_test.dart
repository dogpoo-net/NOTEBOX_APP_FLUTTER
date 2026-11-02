import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebox/main.dart';
import 'package:notebox/features/inbox/element_store.dart';

void main() {
  testWidgets(
    'desktop enter saves; shift and alt enter insert newline',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      final field = find.byKey(const ValueKey('quick-memo'));
      await tester.enterText(field, '첫째');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(tester.widget<TextField>(field).controller!.text, '첫째\n');
      await tester.enterText(field, '첫째\n둘째');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      expect(tester.widget<TextField>(field).controller!.text, '첫째\n둘째\n');
      expect(elements.words, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(elements.words, ['첫째\n둘째']);
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.linux,
      TargetPlatform.windows,
      TargetPlatform.macOS,
    }),
  );
}
