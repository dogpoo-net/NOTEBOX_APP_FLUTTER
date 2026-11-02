import 'dart:math';

import 'package:flutter/material.dart';

final _random = Random();
final _wordHues = <String, double>{};
const starterWords = ['관찰', '질문', '연결', '기억', '성장'];

class WordBadge extends StatelessWidget {
  const WordBadge({super.key, required this.word, required this.onTap});
  final String word;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final hue = _wordHues.putIfAbsent(word, () => _random.nextDouble() * 360);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: HSLColor.fromAHSL(
          1,
          hue,
          .55,
          dark ? .25 : .9,
        ).toColor(),
        foregroundColor: HSLColor.fromAHSL(
          1,
          hue,
          .5,
          dark ? .9 : .23,
        ).toColor(),
        minimumSize: const Size(0, 30),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      child: Text(word),
    );
  }
}

String wordPrefix(TextEditingValue value) {
  if (!value.selection.isValid || !value.selection.isCollapsed) return '';
  return RegExp(r'[^\s.,!?;:،؛؟()\[\]{}]+$')
          .stringMatch(value.text.substring(0, value.selection.extentOffset)) ??
      '';
}

bool matchesWord(String word, String prefix) {
  if (_hangulParts(word.toLowerCase())
      .startsWith(_hangulParts(prefix.toLowerCase()))) {
    return true;
  }
  const initials = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';
  if (prefix.length == 1 && initials.contains(prefix) && word.isNotEmpty) {
    final code = word.runes.first - 0xAC00;
    return code >= 0 && code < 11172 && initials[code ~/ 588] == prefix;
  }
  return false;
}

// Compare composing Hangul without changing the user's composing text.
String _hangulParts(String text) {
  const initial = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ';
  const vowels = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ';
  const finalLetters = ' ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ';
  final result = StringBuffer();
  for (final rune in text.runes) {
    final index = rune - 0xAC00;
    if (index < 0 || index >= 11172) {
      result.writeCharCode(rune);
      continue;
    }
    result.write(initial[index ~/ 588]);
    result.write(vowels[(index % 588) ~/ 28]);
    if (index % 28 != 0) result.write(finalLetters[index % 28]);
  }
  return result.toString();
}
