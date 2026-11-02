import 'project_folders.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'dart:convert';

import 'package:file_selector/file_selector.dart';

import 'workspace_storage.dart';
import 'hashtags.dart';
import 'tag_page.dart';

import 'paragraph_editor.dart';
import 'word_badge.dart';
import 'project_page.dart';
import 'project_builder.dart';
import 'workspace_menu.dart';
import 'element_store.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({
    super.key,
    this.storage,
    required this.themeMode,
    required this.onThemeChanged,
  });
  final WorkspaceStorage? storage;
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
  bool _menuVisible = true;
  Note? _editing;
  String? _storageError;
  bool _restoreBlocked = false;
  @override
  void initState() {
    super.initState();
    projectFolders.clear();
    elements.addListener(_elementDeleted);
    try {
      final raw = widget.storage?.read();
      if (raw != null) {
        final snapshot = WorkspaceSnapshot.decode(raw);
        snapshot.apply();
        _notes.addAll(snapshot.notes);
      }
    } catch (_) {
      _restoreBlocked = true;
      _storageError = '저장 데이터를 읽지 못했습니다. 원본을 보존합니다. JSON 백업으로 복원해주세요.';
    }
  }

  void _elementDeleted() {
    setState(() {
      _notes.removeWhere(
        (n) =>
            n.project == null &&
            n.paragraphs == null &&
            !elements.records.containsKey(n.content),
      );
      for (final note in _notes) {
        note.project?.words.removeWhere(
          (w) => !elements.records.containsKey(w),
        );
      }
      if (_editing != null && !_notes.contains(_editing)) {
        _editing = null;
        _draft.clear();
      }
    });
    _persist();
  }

  Future<void> _createFolder() async {
    var folderName = '';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 만들기'),
        content: TextField(
          onChanged: (value) => folderName = value,
          autofocus: true,
          decoration: const InputDecoration(labelText: '폴더 이름'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, folderName.trim()),
            child: const Text('만들기'),
          ),
        ],
      ),
    );
    if (!mounted || name == null || name.isEmpty) return;
    if (!projectFolders.contains(name)) {
      setState(() => projectFolders.add(name));
      await _persist();
    }
  }

  Future<void> _persist() async {
    if (widget.storage == null || _restoreBlocked) return;
    try {
      await widget.storage!.write(WorkspaceSnapshot.encode(_notes));
    } catch (_) {
      if (mounted) {
        setState(() => _storageError = '기기 저장 실패 · JSON 백업을 내려받아주세요.');
      }
    }
  }

  Future<void> _reset() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 데이터를 초기화할까요?'),
        content: const Text(
          '원소·문단·프로젝트와 이 앱의 기기 저장본을 삭제합니다. 다운로드한 JSON 파일은 삭제되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('모두 삭제'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await widget.storage?.clear();
      if (!mounted) return;
      setState(() {
        projectFolders.clear();
        elements.clear();
        restoreWordColors({});
        _notes.clear();
        _draft.clear();
        _editing = null;
        _storageError = null;
        _restoreBlocked = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('메모리와 기기 저장 데이터를 초기화했습니다.')));
    } catch (_) {
      if (mounted) {
        setState(() => _storageError = '기기 데이터 삭제에 실패했습니다. 다시 시도해주세요.');
      }
    }
  }

  Future<void> _export() async {
    try {
      final data = WorkspaceSnapshot.encode(_notes);
      final file = XFile.fromData(
        Uint8List.fromList(utf8.encode(data)),
        mimeType: 'application/json',
        name: 'notebox-backup.json',
      );
      if (kIsWeb) {
        await file.saveTo('notebox-backup.json');
      } else {
        final location = await getSaveLocation(
          suggestedName: 'notebox-backup.json',
        );
        if (location != null) await file.saveTo(location.path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('백업 파일 저장에 실패했습니다.')));
      }
    }
  }

  Future<void> _import() async {
    try {
      final file = await openFile(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'JSON',
            extensions: ['json'],
            mimeTypes: ['application/json'],
            uniformTypeIdentifiers: ['public.json'],
          ),
        ],
      );
      if (file == null || !mounted) return;
      if (await file.length() > 10000000) {
        throw const FormatException('Too large');
      }
      final snapshot = WorkspaceSnapshot.decode(await file.readAsString());
      if (!mounted) return;
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('백업으로 복원할까요?'),
          content: const Text('현재 데이터를 교체합니다. 기존 데이터는 먼저 JSON 백업으로 보관해주세요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('복원'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
      setState(() {
        snapshot.apply();
        _notes
          ..clear()
          ..addAll(snapshot.notes);
        _editing = null;
        _draft.clear();
        _restoreBlocked = false;
        _storageError = null;
      });
      await _persist();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('백업 파일을 읽을 수 없습니다. 현재 데이터는 유지됩니다.')),
        );
      }
    }
  }

  @override
  void dispose() {
    elements.removeListener(_elementDeleted);
    _draft.dispose();
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _quickMemoKey(FocusNode node, KeyEvent event) {
    final desktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
    if (!desktop ||
        event is KeyUpEvent ||
        (event.logicalKey != LogicalKeyboardKey.enter &&
            event.logicalKey != LogicalKeyboardKey.numpadEnter)) {
      return KeyEventResult.ignored;
    }
    final value = _draft.value;
    if (value.composing.isValid && !value.composing.isCollapsed) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed || keyboard.isMetaPressed) {
      return KeyEventResult.ignored;
    }
    if (event is KeyRepeatEvent) return KeyEventResult.handled;
    if (keyboard.isShiftPressed || keyboard.isAltPressed) {
      final selection = value.selection;
      final start = selection.isValid ? selection.start : value.text.length;
      final end = selection.isValid ? selection.end : start;
      setState(
        () => _draft.value = TextEditingValue(
          text: value.text.replaceRange(start, end, '\n'),
          selection: TextSelection.collapsed(offset: start + 1),
        ),
      );
    } else if (value.text.trim().isNotEmpty) {
      _save();
    }
    return KeyEventResult.handled;
  }

  void _save() {
    if (_draft.text.trim().isEmpty) return;
    if (parseTaggedInput(_draft.text).text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('태그와 함께 원소 내용을 입력해주세요.')));
      return;
    }
    final record = elements.add(_draft.text, replaceTags: _editing != null);
    setState(() {
      if (_editing == null) {
        _notes.insert(0, Note(record.text));
      } else {
        _editing!.content = record.text;
      }
      _editing = null;
      _draft.clear();
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('기록함에 담았어요. 다음 생각도 남겨보세요.')));
    _persist();
    _focus.requestFocus();
  }

  Future<void> _writeParagraphs([Note? note]) async {
    final words = elements.words;
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
      if (note != null) _notes.remove(note);
      for (final paragraph in result.reversed) {
        _notes.insert(0, Note(paragraph.text)..paragraphs = [paragraph]);
      }
    });
    await _persist();
  }

  Future<void> _createProject() async {
    final available = _notes
        .where((n) => n.project == null)
        .expand((n) => n.paragraphs ?? <Paragraph>[])
        .toList();
    final words = elements.words;
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
    await _persist();
    await _showProject(note);
  }

  Future<void> _showProject(Note note) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProjectPage(project: note.project!, onChanged: _persist),
      ),
    );
    if (!mounted) return;
    setState(() {
      note.paragraphs = note.project!.paragraphs;
      note.content = note.paragraphs!.map((p) => p.text).join("\n\n");
    });
    await _persist();
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
      final tags = elements.records[note.content.trim()]?.tags ?? <String>{};
      _draft.text = [note.content, ...tags.map((t) => '#$t')].join(' ');
    });
    _focus.requestFocus();
  }

  Future<void> _menu() async {
    FocusScope.of(context).unfocus();
    final projects = _notes.where((n) => n.project != null).toList();
    final tags = elements.tags;
    final choice = await showDialog<int>(
      context: context,
      builder: (_) => WorkspaceMenu(
        projects: projects.map((n) => n.title).toList(),
        onPin: MediaQuery.sizeOf(context).width >= 1000
            ? () {
                Navigator.pop(context);
                setState(() => _menuVisible = true);
              }
            : null,
        tags: tags,
        folders: projectFolders,
        projectFolderNames: projects.map((n) => n.project!.folder).toList(),
      ),
    );
    await _selectMenu(choice, projects, tags);
  }

  Future<void> _selectMenu(
    int? choice,
    List<Note> projects,
    List<String> tags,
  ) async {
    if (!mounted || choice == null || choice == -1) return;
    if (choice == WorkspaceMenu.createFolder) {
      await _createFolder();
      return;
    }
    if (choice <= -3) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TagPage(tag: tags[-3 - choice], notes: _notes, onOpen: _open),
        ),
      );
    } else if (choice == -2) {
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
          Focus(
            canRequestFocus: false,
            onKeyEvent: _quickMemoKey,
            child: TextField(
              key: const ValueKey('quick-memo'),
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
                hintText: '단어나 생각을 남겨보세요 #독서 #아이디어',
                contentPadding: EdgeInsets.zero,
              ),
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
                label: Text(_editing == null ? '저장' : '저장'),
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
          children: elements.words
              .where(
                (word) => word.toLowerCase().contains(_query.toLowerCase()),
              )
              .map(
                (word) => WordBadge(
                  onLongPress: () => showElementMetadata(context, word),
                  word: word,
                  onTap: () {
                    final notes = _notes.where(
                      (n) => n.paragraphs == null && n.content.trim() == word,
                    );
                    if (notes.isNotEmpty) {
                      _open(notes.first);
                    } else {
                      showElementMetadata(context, word);
                    }
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        for (final note in visible.where(
          (n) => n.paragraphs != null || n.project != null,
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
                '${note.createdAt.month}월 ${note.createdAt.day}일 · ${note.project != null ? '프로젝트' : ['제목', '부제', '본문'][note.paragraphs!.first.role.index]}',
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
  Widget build(BuildContext context) {
    elements.sources[this] = [
      for (var i = 0; i < _notes.length; i++)
        if (_notes[i].paragraphs != null && _notes[i].project == null)
          ElementSource(
            '독립 문단 ${i + 1}: ${_notes[i].title}',
            _notes[i].content,
          ),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MediaQuery.sizeOf(context).width >= 1000 && _menuVisible
              ? '메뉴 숨기기'
              : '메뉴 열기',
          onPressed: MediaQuery.sizeOf(context).width >= 1000 && _menuVisible
              ? () => setState(() => _menuVisible = false)
              : _menu,
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
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 1000 && _menuVisible)
            SafeArea(
              child: WorkspaceMenu(
                embedded: true,
                onHide: () => setState(() => _menuVisible = false),
                projects: _notes
                    .where((n) => n.project != null)
                    .map((n) => n.title)
                    .toList(),
                projectFolderNames: _notes
                    .where((n) => n.project != null)
                    .map((n) => n.project!.folder)
                    .toList(),
                folders: projectFolders,
                tags: elements.tags,
                onSelected: (choice) => _selectMenu(
                  choice,
                  _notes.where((n) => n.project != null).toList(),
                  elements.tags,
                ),
              ),
            ),
          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '기록함',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
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
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: _export,
                              icon: const Icon(
                                Icons.download_outlined,
                                size: 18,
                              ),
                              label: const Text('JSON 백업'),
                            ),
                            TextButton.icon(
                              onPressed: _import,
                              icon: const Icon(
                                Icons.upload_file_outlined,
                                size: 18,
                              ),
                              label: const Text('백업 복원'),
                            ),
                            TextButton.icon(
                              onPressed: _reset,
                              icon: const Icon(Icons.delete_outline, size: 18),
                              label: const Text('데이터 초기화'),
                            ),
                          ],
                        ),
                        LayoutBuilder(
                          builder: (context, constraints) =>
                              constraints.maxWidth >= 760
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
                          _storageError ??
                              (widget.storage == null
                                  ? '기기 저장을 사용할 수 없습니다 · JSON 백업을 이용해주세요'
                                  : '이 브라우저에 저장됨 · 다른 기기로 옮길 때 JSON 백업을 사용하세요'),
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
          ),
        ],
      ),
    );
  }
}
