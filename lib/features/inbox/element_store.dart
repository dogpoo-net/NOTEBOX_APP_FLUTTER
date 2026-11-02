import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'word_badge.dart';

class ElementRecord {
  ElementRecord(this.text)
    : createdAt = DateTime.now(),
      id = 'element-${_next++}';
  static int _next = 0;
  final String id;
  final String text;
  final DateTime createdAt;
}

class ElementSource {
  ElementSource(this.label, this.text);
  final String label;
  final String text;
}

class ElementStore {
  final Map<String, ElementRecord> records = {};
  final Map<Object, List<ElementSource>> sources = {};
  ElementRecord add(String text) {
    final clean = text.trim();
    if (clean.isEmpty) throw ArgumentError('Empty element');
    return records.putIfAbsent(clean, () => ElementRecord(clean));
  }

  List<String> get words => records.keys.toList();
  List<({int start, int end, String word})> matches(String text) {
    final result = <({int start, int end, String word})>[];
    final ordered = words..sort((a, b) => b.length.compareTo(a.length));
    var cursor = 0;
    while (cursor < text.length) {
      String? match;
      for (final word in ordered) {
        if (text.startsWith(word, cursor)) {
          match = word;
          break;
        }
      }
      if (match == null) {
        cursor++;
      } else {
        result.add((start: cursor, end: cursor + match.length, word: match));
        cursor += match.length;
      }
    }
    return result;
  }

  void clear() {
    records.clear();
    sources.clear();
  }
}

final elements = ElementStore();

void showElementMetadata(BuildContext context, String word) {
  final element = elements.records[word];
  if (element == null) return;
  final uses = <String, int>{};
  final together = <String, int>{};
  for (final source in elements.sources.values.expand((s) => s)) {
    final hits = elements.matches(source.text);
    final count = hits.where((h) => h.word == word).length;
    if (count == 0) continue;
    uses.update(source.label, (v) => v + count, ifAbsent: () => count);
    for (final other
        in hits.map((h) => h.word).toSet().where((w) => w != word)) {
      together.update(other, (v) => v + 1, ifAbsent: () => 1);
    }
  }
  final ranked = together.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(word),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '생성: ${element.createdAt.toLocal().toString().split('.').first}',
              ),
              const SizedBox(height: 8),
              Text(
                '사용 ${uses.values.fold<int>(0, (a, b) => a + b)}회 · ${uses.length}개 위치',
              ),
              const SizedBox(height: 16),
              const Text('사용 위치'),
              if (uses.isEmpty) const Text('아직 사용하지 않았어요.'),
              for (final use in uses.entries)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${use.key} · ${use.value}회'),
                ),
              const SizedBox(height: 16),
              const Text('함께 쓰인 원소'),
              for (final entry in ranked)
                Text('${entry.key} · ${entry.value}개 문단'),
              const SizedBox(height: 16),
              const Text(
                '현재 저장된 문단·프로젝트 원문에서 정확히 일치하는 표현을 집계합니다. 겹치는 표현은 긴 원소를 우선합니다.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
}

class ElementText extends StatefulWidget {
  const ElementText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;
  @override
  State<ElementText> createState() => _ElementTextState();
}

class _ElementTextState extends State<ElementText> {
  final List<TapGestureRecognizer> _recognizers = [];
  void _clear() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _clear();
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final hit in elements.matches(widget.text)) {
      spans.add(TextSpan(text: widget.text.substring(cursor, hit.start)));
      final recognizer = TapGestureRecognizer()
        ..onTap = () => showElementMetadata(context, hit.word);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: hit.word,
          recognizer: recognizer,
          style: TextStyle(
            color: wordColor(context, hit.word),
            decoration: TextDecoration.underline,
          ),
        ),
      );
      cursor = hit.end;
    }
    spans.add(TextSpan(text: widget.text.substring(cursor)));
    return Text.rich(TextSpan(children: spans), style: widget.style);
  }
}
