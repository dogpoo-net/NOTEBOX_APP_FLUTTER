import 'package:flutter/material.dart';

class WorkspaceMenu extends StatelessWidget {
  const WorkspaceMenu({
    super.key,
    required this.projects,
    this.tags = const [],
  });
  final List<String> tags;
  final List<String> projects;
  @override
  Widget build(BuildContext context) => Dialog(
    alignment: AlignmentDirectional.topStart,
    insetPadding: const EdgeInsets.fromLTRB(16, 64, 16, 24),
    child: SizedBox(
      width: 320,
      height: 480,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 8, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'NOTEBOX',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '메뉴 닫기',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('메인'),
            onTap: () => Navigator.pop(context, -1),
          ),
          ListTile(
            leading: const Icon(Icons.subject),
            title: const Text('문단 쓰기'),
            onTap: () => Navigator.pop(context, -2),
          ),
          const Divider(indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              '프로젝트 ${projects.length}',
              style: Theme.of(context).textTheme.labelMedium,
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
                  for (var index = 0; index < projects.length; index++)
                    ListTile(
                      leading: const Icon(Icons.folder_outlined, size: 20),
                      title: Text(
                        projects[index],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.pop(context, index),
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
                      onTap: () => Navigator.pop(context, -3 - index),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
