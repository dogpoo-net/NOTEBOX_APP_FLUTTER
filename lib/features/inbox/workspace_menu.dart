import 'package:flutter/material.dart';

class WorkspaceMenu extends StatelessWidget {
  const WorkspaceMenu({
    super.key,
    required this.projects,
    this.tags = const [],
    this.embedded = false,
    this.onSelected,
    this.onHide,
    this.onPin,
    this.folders = const [],
    this.projectFolderNames = const [],
  });
  final bool embedded;
  final ValueChanged<int>? onSelected;
  final VoidCallback? onHide;
  final VoidCallback? onPin;
  void _select(BuildContext context, int choice) {
    if (onSelected != null) {
      onSelected!(choice);
    } else {
      Navigator.pop(context, choice);
    }
  }

  static const createFolder = -1000000;
  final List<String> folders;
  final List<String?> projectFolderNames;
  final List<String> tags;
  final List<String> projects;
  @override
  Widget build(BuildContext context) {
    final content = _content(context);
    if (embedded) return Material(child: SizedBox(width: 280, child: content));
    return Dialog(
      alignment: AlignmentDirectional.topStart,
      insetPadding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
      child: SizedBox(width: 320, height: 480, child: content),
    );
  }

  Widget _content(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 4),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'NOTEBOX',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 2),
              ),
            ),
            if (!embedded && onPin != null)
              IconButton(
                tooltip: '메뉴 고정하기',
                onPressed: onPin,
                icon: const Icon(Icons.push_pin_outlined),
              ),
            IconButton(
              tooltip: embedded ? '메뉴 숨기기' : '메뉴 닫기',
              onPressed: embedded ? onHide : () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
      ListTile(
        leading: const Icon(Icons.home_outlined),
        title: const Text('메인'),
        onTap: () => _select(context, -1),
      ),
      ListTile(
        leading: const Icon(Icons.subject),
        title: const Text('문단 쓰기'),
        onTap: () => _select(context, -2),
      ),
      const Divider(indent: 16, endIndent: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '프로젝트 ${projects.length}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            IconButton(
              tooltip: '폴더 만들기',
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              onPressed: () => _select(context, createFolder),
              icon: const Icon(Icons.create_new_folder_outlined),
            ),
          ],
        ),
      ),
      Expanded(
        child: Scrollbar(
          child: ListView(
            key: const ValueKey('menu-projects'),
            padding: const EdgeInsets.only(bottom: 12),
            children: [
              if (projects.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('아직 프로젝트가 없어요'),
                ),
              for (final folder in folders)
                ExpansionTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(folder),
                  children: [
                    for (var i = 0; i < projects.length; i++)
                      if (i < projectFolderNames.length &&
                          projectFolderNames[i] == folder)
                        ListTile(
                          title: Text(projects[i]),
                          leading: const Icon(Icons.article_outlined),
                          onTap: () => _select(context, i),
                        ),
                  ],
                ),
              for (var i = 0; i < projects.length; i++)
                if (i >= projectFolderNames.length ||
                    projectFolderNames[i] == null)
                  ListTile(
                    title: Text(projects[i]),
                    leading: const Icon(Icons.article_outlined),
                    onTap: () => _select(context, i),
                  ),
              const Divider(indent: 16, endIndent: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text('해시태그'),
              ),
              if (tags.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('아직 해시태그가 없어요'),
                ),
              for (var index = 0; index < tags.length; index++)
                ListTile(
                  leading: const Icon(Icons.tag, size: 20),
                  title: Text('#${tags[index]}'),
                  onTap: () => _select(context, -3 - index),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
