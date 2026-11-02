import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notebox/features/inbox/paragraph_editor.dart';
import 'package:notebox/features/inbox/word_badge.dart';

void main() {
  test('one character prefixes, two contain, prefixes rank first', () {
    expect(wordSuggestions(['생각', '작은 생각', '생각 정리'], '생'), ['생각', '생각 정리']);
    expect(wordSuggestions(['작은 생각', '생각 정리', '생각'], '생각'), [
      '생각',
      '생각 정리',
      '작은 생각',
    ]);
    expect(
      completionPrefix(
        const TextEditingValue(
          text: '문장\n생',
          selection: TextSelection.collapsed(offset: 4),
        ),
        [],
      ),
      '생',
    );
  });
  testWidgets('desktop badge selection requires control', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(home: ParagraphEditor(words: ['생각', '생각 정리', '작은 생각'])),
    );
    final field = find.byKey(const ValueKey('paragraph-0'));
    await tester.enterText(field, '생각');
    await tester.pumpAndSettle();
    final controller = tester.widget<TextField>(field).controller!;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(controller.selection.extentOffset, 1);
    expect(controller.text, '생각');
    controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pumpAndSettle();
    expect(find.byType(WordBadge), findsWidgets);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, '생각 정리');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.enterText(field, '생');
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, '생각');
  });
}
