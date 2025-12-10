import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';

class GroupSelectionScreen extends StatefulWidget {
  const GroupSelectionScreen({super.key});

  @override
  State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroups();
    });
  }

  Future<void> _loadGroups() async {
    // Groups will be loaded when selecting
    // For now we can just show empty state and allow creation
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Create New Group',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.orange.shade50,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.orange.shade50,
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.orange.shade50,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.black)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a group name')),
                );
                return;
              }

              Navigator.pop(context);

              // Create group and then redirect to group selection
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Group created successfully! Feature coming soon...'),
                  backgroundColor: Colors.green.shade600,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      appBar: AppBar(
        title: Text(
          'Select Village Group',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
      ),
      body: Consumer<GroupProvider>(
        builder: (context, groupProvider, _) {
          if (groupProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.orange.shade600,
              ),
            );
          }

          if (groupProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
                  SizedBox(height: 16),
                  Text(
                    'Error loading groups',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      groupProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadGroups,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (groupProvider.userGroups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 100,
                    color: Colors.orange.shade400,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No Groups Found',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Create a new group to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _showCreateGroupDialog,
                    icon: Icon(Icons.add),
                    label: Text('Create Group'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (groupProvider.selectedGroup != null)
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Group',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              groupProvider.selectedGroup!.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Feature coming soon')),
                          );
                        },
                        icon: Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Groups',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showCreateGroupDialog,
                      icon: Icon(Icons.add, color: Colors.orange.shade600),
                      label: Text(
                        'Create New',
                        style: TextStyle(color: Colors.orange.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: groupProvider.userGroups.length,
                  itemBuilder: (context, index) {
                    final group = groupProvider.userGroups[index];
                    final isSelected = groupProvider.selectedGroup?.id == group.id;

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isSelected
                            ? BorderSide(color: Colors.green.shade600, width: 2)
                            : BorderSide.none,
                      ),
                      child: InkWell(
                        onTap: () async {
                          final authProvider = context.read<AuthProvider>();
                          if (authProvider.currentUser != null) {
                            await groupProvider.selectGroup(
                              group,
                              authProvider.currentUser!.id,
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${group.name} selected'),
                                backgroundColor: Colors.green.shade600,
                                duration: Duration(seconds: 1),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.groups,
                                  color: Colors.orange.shade600,
                                  size: 32,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    if (group.description != null) ...[
                                      SizedBox(height: 4),
                                      Text(
                                        group.description!,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black.withValues(alpha: 0.6),
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.people,
                                            size: 16,
                                            color: Colors.black.withValues(alpha: 0.5)),
                                        SizedBox(width: 4),
                                        Text(
                                          'Village Group',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        if (group.location != null) ...[
                                          SizedBox(width: 16),
                                          Icon(Icons.location_on,
                                              size: 16,
                                              color: Colors.black.withValues(alpha: 0.5)),
                                          SizedBox(width: 4),
                                          Text(
                                            group.location!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black.withValues(alpha: 0.5),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                  size: 32,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
