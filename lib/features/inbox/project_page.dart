import 'package:flutter/material.dart';

import 'paragraph_editor.dart';
import 'word_badge.dart';
import 'element_store.dart';

class WritingProject {
  WritingProject(this.paragraphs, List<String> words, {required this.name})
    : words = List.of(words);
  String name;
  List<Paragraph> paragraphs;
  final List<String> words;
  String get title => name;
}

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key, required this.project});
  final WritingProject project;
  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  int _tab = 0;
  final _word = TextEditingController();
  @override
  void dispose() {
    _word.dispose();
    super.dispose();
  }

  Future<void> _edit() async {
    final result = await Navigator.push<List<Paragraph>>(
      context,
      MaterialPageRoute(
        builder: (_) => ParagraphEditor(
          projectEditing: true,
          initial: widget.project.paragraphs,
          words: elements.words,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => widget.project.paragraphs = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    elements.sources[project] = [
      for (var i = 0; i < project.paragraphs.length; i++)
        ElementSource(
          '${project.name} · 문단 ${i + 1}',
          project.paragraphs[i].text,
        ),
    ];
    final usedWords = project.paragraphs
        .expand((p) => elements.matches(p.text).map((h) => h.word))
        .toSet();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          project.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _edit,
            tooltip: '프로젝트 편집',
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in ['미리보기', '원소', '문단'].asMap().entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _tab == entry.key,
                        onSelected: (_) => setState(() => _tab = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_tab == 0) ...[
                  const Text('미리보기', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 20),
                  for (final p in project.paragraphs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ElementText(
                        p.text,
                        style: TextStyle(
                          height: 1.7,
                          fontSize: p.role == ParagraphRole.title
                              ? 30
                              : p.role == ParagraphRole.subtitle
                              ? 22
                              : 16,
                          fontWeight: p.role == ParagraphRole.body
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                ],
                if (_tab == 1) ...[
                  const Text('이 프로젝트에서 사용한 원소'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: usedWords
                        .map(
                          (w) => WordBadge(
                            word: w,
                            onTap: () {
                              showElementMetadata(context, w);
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _word,
                    decoration: const InputDecoration(labelText: '원소단어 추가'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      final word = _word.text.trim();
                      if (word.isEmpty) return;
                      setState(() {
                        elements.add(word);
                        _word.clear();
                      });
                    },
                    child: const Text('글로벌 원소 저장'),
                  ),
                ],
                if (_tab == 2) ...[
                  for (var i = 0; i < project.paragraphs.length; i++)
                    Card(
                      child: ListTile(
                        title: Text(project.paragraphs[i].text),
                        subtitle: Text(
                          '문단 ${i + 1} · ${['제목', '부제', '본문'][project.paragraphs[i].role.index]}',
                        ),
                        onTap: _edit,
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                const Text(
                  '프로젝트는 현재 실행 중에만 보관됩니다.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
