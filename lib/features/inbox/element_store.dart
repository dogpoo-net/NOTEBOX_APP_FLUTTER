import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import 'word_badge.dart';
import 'hashtags.dart';

class ElementRecord {
  ElementRecord(this.text)
    : createdAt = DateTime.now(),
      id = 'element-${DateTime.now().microsecondsSinceEpoch}-${_next++}';
  ElementRecord.restored(
    this.id,
    this.text,
    this.createdAt, {
    Iterable<String> tags = const [],
  }) {
    this.tags.addAll(tags);
  }
  final Set<String> tags = {};
  static int _next = 0;
  final String id;
  final String text;
  final DateTime createdAt;
}

class ElementSource {
  ElementSource(this.label, this.text, {this.isProject = false});
  final bool isProject;
  final String label;
  final String text;
}

class ElementStore extends ChangeNotifier {
  void remove(String word) {
    if (records.remove(word) != null) notifyListeners();
  }

  final Map<String, ElementRecord> records = {};
  final Map<Object, List<ElementSource>> sources = {};
  ElementRecord add(String text, {bool replaceTags = false}) {
    final parsed = parseTaggedInput(text);
    final clean = parsed.text;
    if (clean.isEmpty) throw ArgumentError('Empty element');
    ensureWordColor(clean);
    final record = records.putIfAbsent(clean, () => ElementRecord(clean));
    if (replaceTags) record.tags.clear();
    record.tags.addAll(parsed.tags);
    return record;
  }

  List<String> get words => records.keys.toList();
  List<String> get tags =>
      records.values.expand((r) => r.tags).toSet().toList()..sort();
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
    if (!source.isProject) continue;
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
      title: Align(
        alignment: AlignmentDirectional.centerStart,
        child: elementBadge(context, word),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (element.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: element.tags
                      .map((tag) => Chip(label: Text('#$tag')))
                      .toList(),
                ),
                const Divider(height: 20),
              ],
              Text('생성일', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              Text(element.createdAt.toLocal().toString().split('.').first),
              const Divider(height: 28),
              Text('프로젝트 사용', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              Text(
                '사용 ${uses.values.fold<int>(0, (a, b) => a + b)}회 · ${uses.length}개 위치',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text('독립 문단 제외', style: Theme.of(context).textTheme.bodySmall),
              const Divider(height: 28),
              Text('사용 위치', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              if (uses.isEmpty) const Text('사용한 프로젝트가 없어요.'),
              for (final use in uses.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${use.key} · ${use.value}회'),
                ),
              const Divider(height: 28),
              Text('함께 쓰인 원소', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              if (ranked.isEmpty) const Text('함께 쓰인 원소가 없어요.'),
              for (final entry in ranked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      elementBadge(context, entry.key),
                      Text(
                        '${entry.value}개 프로젝트 문단',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('원소를 삭제할까요?'),
                content: const Text('모든 원소 목록에서 삭제합니다. 문단과 프로젝트의 글은 유지됩니다.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('삭제'),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              elements.remove(word);
              Navigator.pop(context);
            }
          },
          child: const Text('원소 삭제'),
        ),
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
            decorationStyle: TextDecorationStyle.dotted,
            decorationColor: wordBackgroundColor(context, hit.word),
            decorationThickness: 2,
          ),
        ),
      );
      cursor = hit.end;
    }
    spans.add(TextSpan(text: widget.text.substring(cursor)));
    return Text.rich(TextSpan(children: spans), style: widget.style);
  }
}
