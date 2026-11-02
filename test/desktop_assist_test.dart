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
  testWidgets('control toggles badge navigation with spatial arrows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final words = List.generate(24, (i) => '원소${i.toString().padLeft(2, '0')}');
    await tester.pumpWidget(MaterialApp(home: ParagraphEditor(words: words)));
    final field = find.byKey(const ValueKey('paragraph-0'));
    await tester.enterText(field, '원');
    await tester.pumpAndSettle();
    final controller = tester.widget<TextField>(field).controller!;
    String selected() => tester
        .widgetList<WordBadge>(find.byType(WordBadge))
        .singleWhere((b) => b.selected)
        .word;
    await tester.sendKeyEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(selected(), words.first);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(selected(), words[1]);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(selected(), words.first);
    final origin = tester.getCenter(
      find.byKey(ValueKey('suggestion-${words.first}')),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final below = selected();
    expect(words.indexOf(below), greaterThan(1));
    expect(
      tester.getCenter(find.byKey(ValueKey('suggestion-$below'))).dy,
      greaterThan(origin.dy),
    );
    expect(controller.selection.extentOffset, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(selected(), words.first);
    await tester.sendKeyEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(controller.selection.extentOffset, 0);
    expect(
      tester
          .widgetList<WordBadge>(find.byType(WordBadge))
          .any((b) => b.selected),
      isFalse,
    );
    controller.selection = const TextSelection.collapsed(offset: 1);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(controller.text, words.first);
  });
}
