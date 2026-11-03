import 'dart:async';

import 'package:flutter/material.dart';

import 'word_badge.dart';
import 'caret_assist.dart';
import 'element_store.dart';

enum ParagraphRole { title, subtitle, body }

class Paragraph {
  const Paragraph(this.text, this.role);
  final String text;
  final ParagraphRole role;
}

class ParagraphEditor extends StatefulWidget {
  const ParagraphEditor({
    super.key,
    this.initial = const [],
    this.projectEditing = false,
    required this.words,
  });
  final bool projectEditing;
  final List<Paragraph> initial;
  final List<String> words;
  @override
  State<ParagraphEditor> createState() => _ParagraphEditorState();
}

class _ParagraphEditorState extends State<ParagraphEditor> {
  final List<TextEditingController> _controllers = [];
  final List<ParagraphRole> _roles = [];
  final List<FocusNode> _focus = [];
  final _scroll = ScrollController();
  Timer? _keyboardScroll;
  double _lastInset = 0;
  Size? _lastSize;
  double _expandedHeight = 0;
  bool _keyboardResizedViewport = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    final inset = media.viewInsets.bottom;
    final previous = _lastSize;
    final shrank =
        previous != null &&
        media.size.width == previous.width &&
        media.size.height < previous.height;
    if (previous == null ||
        previous.width != media.size.width ||
        media.size.height > _expandedHeight) {
      _expandedHeight = media.size.height;
    }
    if (previous != null) {
      if (previous.width != media.size.width ||
          media.size.height > previous.height) {
        _keyboardResizedViewport = false;
      } else if (_expandedHeight - media.size.height > 80 &&
          _focus.any((f) => f.hasFocus)) {
        _keyboardResizedViewport = true;
      }
    }
    if ((inset > 0 && inset != _lastInset) ||
        (shrank && _focus.any((f) => f.hasFocus))) {
      _keyboardScroll?.cancel();
      // Wait for the keyboard resize and EditableText's caret reveal to settle.
      _keyboardScroll = Timer(const Duration(milliseconds: 280), () {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
        WidgetsBinding.instance.ensureVisualUpdate();
      });
    } else if ((inset == 0 && _lastInset > 0) ||
        (previous != null && media.size.height > previous.height)) {
      _keyboardScroll?.cancel();
    }
    _lastInset = inset;
    _lastSize = media.size;
  }

  int _active = 0;
  bool _dirty = false;
  static const _labels = ['제목', '부제', '본문'];
  List<String> get words => widget.words.isEmpty ? starterWords : widget.words;

  @override
  void initState() {
    super.initState();
    for (final p in widget.initial) {
      _add(p);
    }
    if (_controllers.isEmpty) _add(const Paragraph('', ParagraphRole.body));
  }

  void _add(Paragraph p) {
    _controllers.add(
      TextEditingController(text: p.text)..addListener(() {
        if (mounted) setState(() {});
      }),
    );
    _roles.add(p.role);
    _focus.add(FocusNode());
  }

  @override
  void dispose() {
    _keyboardScroll?.cancel();
    _scroll.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _insert(String word, {bool complete = false}) {
    final c = _controllers[_active];
    final selection = c.selection;
    final prefix = complete ? completionPrefix(c.value, words) : "";
    final start =
        (selection.isValid ? selection.start : c.text.length) - prefix.length;
    final end = selection.isValid ? selection.end : start;
    c.value = TextEditingValue(
      text: c.text.replaceRange(start, end, word),
      selection: TextSelection.collapsed(offset: start + word.length),
    );
    setState(() => _dirty = true);
    _focus[_active].requestFocus();
  }

  Future<void> _back() async {
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('작성 중인 글을 닫을까요?'),
          content: const Text('아직 담지 않은 문단은 사라집니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('계속 작성'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasText = _controllers.any((c) => c.text.trim().isNotEmpty);
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back),
            tooltip: '돌아가기',
          ),
          title: const Text('문단 쓰기'),
          actions: [
            if (widget.projectEditing)
              TextButton(
                onPressed: hasText
                    ? () {
                        _focus[_active].unfocus();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(title: const Text('미리보기')),
                              body: SafeArea(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 800,
                                    ),
                                    child: ListView(
                                      padding: const EdgeInsets.all(24),
                                      children: [
                                        for (
                                          var i = 0;
                                          i < _controllers.length;
                                          i++
                                        )
                                          if (_controllers[i].text
                                              .trim()
                                              .isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 20,
                                              ),
                                              child: ElementText(
                                                _controllers[i].text,
                                                style: TextStyle(
                                                  height: 1.7,
                                                  fontSize:
                                                      _roles[i] ==
                                                          ParagraphRole.title
                                                      ? 30
                                                      : _roles[i] ==
                                                            ParagraphRole
                                                                .subtitle
                                                      ? 22
                                                      : 16,
                                                  fontWeight:
                                                      _roles[i] ==
                                                          ParagraphRole.body
                                                      ? FontWeight.normal
                                                      : FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text('미리보기'),
              ),

            TextButton(
              onPressed: hasText
                  ? () {
                      final result = [
                        for (var i = 0; i < _controllers.length; i++)
                          if (_controllers[i].text.trim().isNotEmpty)
                            Paragraph(_controllers[i].text, _roles[i]),
                      ];
                      Navigator.pop(context, result);
                    }
                  : null,
              child: const Text('저장'),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                key: const ValueKey('paragraph-scroll'),
                controller: _scroll,
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  (MediaQuery.viewInsetsOf(context).bottom > 0 ||
                          _keyboardResizedViewport)
                      ? mobileAssistHeight(MediaQuery.of(context)) + 36
                      : 20,
                ),
                children: [
                  for (var i = 0; i < _controllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: ToggleButtons(
                                direction: Axis.horizontal,
                                borderRadius: BorderRadius.circular(16),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 28,
                                ),
                                textStyle: const TextStyle(fontSize: 11),
                                isSelected: ParagraphRole.values
                                    .map((role) => role == _roles[i])
                                    .toList(),
                                onPressed: (index) {
                                  setState(() {
                                    _roles[i] = ParagraphRole.values[index];
                                    _active = i;
                                    _dirty = true;
                                  });
                                  _focus[i].requestFocus();
                                },
                                children: _labels
                                    .map(
                                      (label) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        child: Text(label),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                          CaretAssist(
                            controller: _controllers[i],
                            focus: _focus[i],
                            words: words,
                            onWord: (word) {
                              _active = i;
                              _insert(word, complete: true);
                            },
                            child: TextField(
                              key: ValueKey('paragraph-$i'),
                              controller: _controllers[i],
                              focusNode: _focus[i],
                              minLines: 2,
                              maxLines: null,
                              onTap: () => setState(() => _active = i),
                              onChanged: (_) => setState(() {
                                _active = i;
                                _dirty = true;
                              }),
                              style: TextStyle(
                                fontSize: _roles[i] == ParagraphRole.title
                                    ? 28
                                    : _roles[i] == ParagraphRole.subtitle
                                    ? 21
                                    : 16,
                                fontWeight: _roles[i] == ParagraphRole.body
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                                height: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText: i == 0
                                    ? '단어 하나로 시작해보세요'
                                    : '다음 생각을 이어보세요',
                                labelText: '문단 ${i + 1}',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _add(const Paragraph('', ParagraphRole.body));
                        _active = _controllers.length - 1;
                      });
                      _focus.last.requestFocus();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('다음 문단'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '저장을 누르면 문단이 보관됩니다.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
