import 'package:flutter/material.dart';

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
    required this.words,
  });
  final List<Paragraph> initial;
  final List<String> words;
  @override
  State<ParagraphEditor> createState() => _ParagraphEditorState();
}

class _ParagraphEditorState extends State<ParagraphEditor> {
  final List<TextEditingController> _controllers = [];
  final List<ParagraphRole> _roles = [];
  final List<FocusNode> _focus = [];
  int _active = 0;
  bool _dirty = false;
  static const _labels = ['타이틀', '부제목', '본문'];

  @override
  void initState() {
    super.initState();
    for (final p in widget.initial) {
      _add(p);
    }
    if (_controllers.isEmpty) _add(const Paragraph('', ParagraphRole.body));
  }

  void _add(Paragraph p) {
    _controllers.add(TextEditingController(text: p.text));
    _roles.add(p.role);
    _focus.add(FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _insert(String word) {
    final c = _controllers[_active];
    final selection = c.selection;
    final start = selection.isValid ? selection.start : c.text.length;
    final end = selection.isValid ? selection.end : start;
    c.value = TextEditingValue(
      text: c.text.replaceRange(start, end, '$word '),
      selection: TextSelection.collapsed(offset: start + word.length + 1),
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
              child: const Text('기록함에 담기'),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    '단어를 씨앗으로, 한 편의 글로',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.words.isEmpty ? '시작을 돕는 예시 원소단어' : '내 메모에서 가져온 원소단어',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        (widget.words.isEmpty
                                ? ['관찰', '질문', '연결', '기억', '성장']
                                : widget.words)
                            .map(
                              (word) => ActionChip(
                                label: Text(word),
                                onPressed: () => _insert(word),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('단어를 누르거나 바로 써보세요. 쓰기 시작하면 문단의 역할을 고를 수 있어요.'),
                  const SizedBox(height: 24),
                  for (var i = 0; i < _controllers.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
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
                          if (_controllers[i].text.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                for (final role in ParagraphRole.values)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: ChoiceChip(
                                      label: Text(_labels[role.index]),
                                      selected: _roles[i] == role,
                                      onSelected: (_) {
                                        setState(() {
                                          _roles[i] = role;
                                          _active = i;
                                          _dirty = true;
                                        });
                                        _focus[i].requestFocus();
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ],
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
                    '메모는 현재 실행 중에만 보관됩니다.',
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
