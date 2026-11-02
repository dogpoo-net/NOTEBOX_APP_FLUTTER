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
  testWidgets('desktop arrow selection accepts with enter and space', (
    tester,
  ) async {
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
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, '생각 정리');
    await tester.enterText(field, '생');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, '생각');
  });
}
