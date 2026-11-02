import 'package:flutter/material.dart';

import 'paragraph_editor.dart';
import 'word_badge.dart';
import 'project_page.dart';
import 'project_builder.dart';
import 'workspace_menu.dart';

class Note {
  Note(this.content) : createdAt = DateTime.now();
  String content;
  List<Paragraph>? paragraphs;
  WritingProject? project;
  final DateTime createdAt;
  String get title => project?.name ?? content.trim().split('\n').first.trim();
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

  Future<void> _writeParagraphs([Note? note]) async {
    final words = _notes
        .map((n) => n.title.trim())
        .where((s) => s.isNotEmpty && !s.contains(' ') && s.length <= 20)
        .toSet()
        .toList();
    final result = await Navigator.push<List<Paragraph>>(
      context,
      MaterialPageRoute(
        builder: (_) => ParagraphEditor(
          initial: note?.paragraphs ?? const [],
          words: words,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final content = result.map((p) => p.text).join('\n\n');
      if (note == null) {
        _notes.insert(0, Note(content)..paragraphs = result);
      } else {
        note.content = content;
        note.paragraphs = result;
      }
    });
  }

  Future<void> _createProject() async {
    final available = _notes
        .where((n) => n.project == null)
        .expand((n) => n.paragraphs ?? <Paragraph>[])
        .toList();
    final words = _notes
        .where(
          (n) =>
              n.paragraphs == null && !n.content.trim().contains(RegExp(r'\s')),
        )
        .map((n) => n.title)
        .toSet()
        .toList();
    final project = await Navigator.push<WritingProject>(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectBuilder(available: available, words: words),
      ),
    );
    if (project == null || !mounted) return;
    final note = Note(project.paragraphs.map((p) => p.text).join('\n\n'))
      ..project = project
      ..paragraphs = project.paragraphs;
    setState(() => _notes.insert(0, note));
    await _showProject(note);
  }

  Future<void> _showProject(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectPage(project: note.project!)),
    );
    if (!mounted) return;
    setState(() {
      note.paragraphs = note.project!.paragraphs;
      note.content = note.paragraphs!.map((p) => p.text).join("\n\n");
    });
  }

  Future<void> _open(Note note) async {
    if (note.project != null) {
      await _showProject(note);
      return;
    }
    if (note.paragraphs != null) {
      await _writeParagraphs(note);
      return;
    }
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

  Future<void> _menu() async {
    FocusScope.of(context).unfocus();
    final projects = _notes.where((n) => n.project != null).toList();
    final choice = await showDialog<int>(
      context: context,
      builder: (_) =>
          WorkspaceMenu(projects: projects.map((n) => n.title).toList()),
    );
    if (!mounted || choice == null || choice == -1) return;
    if (choice == -2) {
      await _writeParagraphs();
    } else {
      await _showProject(projects[choice]);
    }
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
              hintText: '단어나 생각을 남겨보세요',
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
                  _notes.isEmpty ? '아직 메모가 없어요' : '일치하는 메모가 없어요',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _notes.isEmpty ? '첫 메모를 남겨보세요.' : '다른 단어로 찾아보세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant, height: 1.7),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: visible
              .where(
                (n) =>
                    n.paragraphs == null &&
                    !n.content.trim().contains(RegExp(r'\s')),
              )
              .map(
                (note) => WordBadge(word: note.title, onTap: () => _open(note)),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        for (final note in visible.where(
          (n) =>
              n.paragraphs != null || n.content.trim().contains(RegExp(r'\s')),
        ))
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
      leading: IconButton(
        tooltip: '메뉴 열기',
        onPressed: _menu,
        icon: const Icon(Icons.grid_view_rounded),
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
                Text('기록함', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => _writeParagraphs(),
                      icon: const Icon(Icons.subject, size: 18),
                      label: const Text('문단 쓰기'),
                    ),
                    TextButton.icon(
                      onPressed: _createProject,
                      icon: const Icon(
                        Icons.create_new_folder_outlined,
                        size: 18,
                      ),
                      label: const Text('프로젝트 생성'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 760
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: _list(),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(child: _composer()),
                          ],
                        )
                      : Column(
                          children: [
                            _composer(),
                            const SizedBox(height: 24),
                            _list(),
                          ],
                        ),
                ),
                const SizedBox(height: 24),
                Text(
                  '임시 저장 · 새로고침 시 초기화',
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
