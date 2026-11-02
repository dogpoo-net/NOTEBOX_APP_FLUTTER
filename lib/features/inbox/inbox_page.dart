import 'package:flutter/material.dart';

class Note {
  Note(this.content) : createdAt = DateTime.now();
  String content;
  final DateTime createdAt;
  String get title => content.trim().split('\n').first;
}

class InboxPage extends StatefulWidget {
  const InboxPage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;
  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final _draft = TextEditingController();
  final _focus = FocusNode();
  final List<Note> _notes = [];
  String _query = '';
  Note? _editing;

  @override
  void dispose() {
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _save() {
    if (_draft.text.trim().isEmpty) return;
    setState(() {
      if (_editing == null) {
        _notes.insert(0, Note(_draft.text));
      } else {
        _editing!.content = _draft.text;
      }
      _editing = null;
      _draft.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('기록함에 담았어요. 다음 생각도 남겨보세요.')));
    _focus.requestFocus();
  }

  Future<void> _open(Note note) async {
    if (_draft.text.isNotEmpty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('작성 중인 내용을 바꿀까요?'),
          content: const Text('다른 메모를 열면 아직 담지 않은 내용이 사라져요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('계속 작성'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('다른 메모 열기'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    setState(() {
      _editing = note;
      _draft.text = note.content;
    });
    _focus.requestFocus();
  }

  ColorScheme get colors => Theme.of(context).colorScheme;

  Widget _composer() => Card(
    color: colors.surfaceContainerLow,
    elevation: 0,
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded),
              const SizedBox(width: 8),
              Text(
                _editing == null ? '빠른 메모' : '메모 다듬기',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _draft,
            focusNode: _focus,
            minLines: 4,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: '지금 떠오른 생각은 무엇인가요?\n제목 없이, 한 줄부터 시작해도 좋아요.',
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '단어 하나부터, 편하게',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              FilledButton.icon(
                onPressed: _draft.text.trim().isEmpty ? null : _save,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                label: Text(_editing == null ? '기록함에 담기' : '수정 완료'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _list() {
    final visible = _notes
        .where((n) => n.content.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('모아둔 생각', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            Text('${_notes.length}', style: TextStyle(color: colors.primary)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: '메모에서 찾기',
            prefixIcon: Icon(Icons.search),
            isDense: true,
          ),
        ),
        const SizedBox(height: 20),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 12),
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 40, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  _notes.isEmpty ? '작은 생각이 지식의 시작이에요' : '일치하는 메모가 없어요',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _notes.isEmpty
                      ? '읽다가 떠오른 질문, 잊고 싶지 않은 문장.\n먼저 담아두고, 정리는 나중에 해요.'
                      : '다른 단어로 찾아보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant, height: 1.7),
                ),
              ],
            ),
          ),
        for (final note in visible)
          Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            color: colors.surfaceContainerLow,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              title: Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${note.createdAt.month}월 ${note.createdAt.day}일 · 빠른 메모',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => _open(note),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.grid_view_rounded,
            color: colors.onPrimaryContainer,
            size: 20,
          ),
        ),
      ),
      actions: [
        PopupMenuButton<ThemeMode>(
          tooltip: '테마 선택',
          initialValue: widget.themeMode,
          onSelected: widget.onThemeChanged,
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
          ),
          itemBuilder: (_) => [
            CheckedPopupMenuItem(
              value: ThemeMode.system,
              checked: widget.themeMode == ThemeMode.system,
              child: const Text('시스템 설정'),
            ),
            CheckedPopupMenuItem(
              value: ThemeMode.light,
              checked: widget.themeMode == ThemeMode.light,
              child: const Text('라이트'),
            ),
            CheckedPopupMenuItem(
              value: ThemeMode.dark,
              checked: widget.themeMode == ThemeMode.dark,
              child: const Text('다크'),
            ),
          ],
        ),
        const SizedBox(width: 12),
      ],
      title: Text(
        'NOTEBOX',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
      ),
      centerTitle: false,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MY WORKSPACE  /  INBOX',
                  style: TextStyle(color: colors.primary, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  '나의 기록함',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '완벽하게 쓰지 않아도 괜찮아요.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 760
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _list()),
                            const SizedBox(width: 32),
                            Expanded(child: _composer()),
                          ],
                        )
                      : Column(
                          children: [
                            _composer(),
                            const SizedBox(height: 32),
                            _list(),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  '미리보기 단계 · 메모는 앱을 재시작하면 초기화됩니다.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
