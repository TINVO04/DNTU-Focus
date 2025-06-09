import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import '../../data/models/project_model.dart';
import '../../data/models/project_tag_repository.dart';
import '../../data/models/tag_model.dart';
import '../add_project_and_tags/add_project_screen.dart';
import '../add_project_and_tags/add_tag_screen.dart';
import 'archived_projects_screen.dart';
import 'archived_tags_screen.dart';
import 'edit_project_and_tags/edit_project_screen.dart';
import 'edit_project_and_tags/edit_tag_screen.dart';
// KHÔNG cần import theme.dart ở đây nếu không trực tiếp dùng SuccessColor extension

class ManageProjectsTagsScreen extends StatefulWidget {
  final ProjectTagRepository repository;

  const ManageProjectsTagsScreen({super.key, required this.repository});

  @override
  State<ManageProjectsTagsScreen> createState() => _ManageProjectsTagsScreenState();
}

class _ManageProjectsTagsScreenState extends State<ManageProjectsTagsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Sử dụng từ theme.dart
      appBar: AppBar(
        // backgroundColor và elevation đã được set trong appBarTheme của theme.dart
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color), // Sử dụng từ theme.dart
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Manage Projects and Tags',
          style: theme.appBarTheme.titleTextStyle, // Sử dụng từ theme.dart
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.textTheme.titleLarge?.color, // Sử dụng từ theme.dart
          unselectedLabelColor: theme.textTheme.bodyMedium?.color?.withOpacity(0.7), // Sử dụng từ theme.dart
          indicatorColor: theme.colorScheme.primary, // Sử dụng colorScheme.primary
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Projects'),
            Tab(text: 'Tags'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab Projects
          ValueListenableBuilder(
            valueListenable: widget.repository.projectBox.listenable(),
            builder: (context, Box<Project> box, _) {
              final projects = widget.repository.getProjects();
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: projects.length + 1,
                      itemBuilder: (context, index) {
                        if (index == projects.length) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Card( // CardTheme sẽ được áp dụng từ theme.dart
                              child: ListTile(
                                title: Text(
                                  'Archived Projects',
                                  style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color), // Sử dụng từ theme.dart
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color?.withOpacity(0.6)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ArchivedProjectsScreen(repository: widget.repository),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }

                        final project = projects[index];
                        IconData projectIconData = project.icon ?? Icons.work_outline;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card( // CardTheme sẽ được áp dụng từ theme.dart
                            child: ListTile(
                              leading: Icon(
                                projectIconData,
                                color: project.color,
                                size: 40,
                              ),
                              title: Text(
                                project.name,
                                style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color), // Sử dụng từ theme.dart
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, color: theme.iconTheme.color?.withOpacity(0.6)),
                                onSelected: (value) {
                                  final projectKey = project.key;
                                  if (value == 'Edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditProjectScreen(
                                          repository: widget.repository,
                                          projectKey: projectKey,
                                          onProjectUpdated: () {},
                                        ),
                                      ),
                                    );
                                  } else if (value == 'Lưu trữ') {
                                    widget.repository.archiveProjectByKey(projectKey);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'Edit',
                                    child: Text('Edit'), // Text color sẽ tự động theo theme
                                  ),
                                  const PopupMenuItem(
                                    value: 'Lưu trữ',
                                    child: Text('Lưu trữ'), // Text color sẽ tự động theo theme
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddProjectScreen(
                              repository: widget.repository,
                              onProjectAdded: () {},
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Add New Project',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.primary, // Sử dụng colorScheme.primary
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Tab Tags (Tương tự)
          ValueListenableBuilder(
            valueListenable: widget.repository.tagBox.listenable(),
            builder: (context, Box<Tag> box, _) {
              final tags = widget.repository.getTags();
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: tags.length + 1,
                      itemBuilder: (context, index) {
                        if (index == tags.length) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Card( // CardTheme sẽ được áp dụng
                              child: ListTile(
                                title: Text(
                                  'Archived Tags',
                                  style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color?.withOpacity(0.6)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ArchivedTagsScreen(repository: widget.repository),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                        final tag = tags[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card( // CardTheme sẽ được áp dụng
                            child: ListTile(
                              leading: Icon(
                                Icons.label_outline,
                                color: tag.textColor,
                                size: 40,
                              ),
                              title: Text(
                                tag.name,
                                style: TextStyle(fontSize: 16, color: theme.textTheme.bodyMedium?.color),
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, color: theme.iconTheme.color?.withOpacity(0.6)),
                                onSelected: (value) {
                                  final tagKey = tag.key;
                                  if (value == 'Edit') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditTagScreen(
                                          repository: widget.repository,
                                          tagKey: tagKey,
                                          onTagUpdated: () {},
                                        ),
                                      ),
                                    );
                                  } else if (value == 'Lưu trữ') {
                                    widget.repository.archiveTagByKey(tagKey);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'Edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'Lưu trữ',
                                    child: Text('Lưu trữ'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTagScreen(
                              repository: widget.repository,
                              onTagAdded: () {},
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Add New Tag',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.primary, // Sử dụng colorScheme.primary
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}