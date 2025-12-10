import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../models/village_group.dart';
import 'group_dashboard_screen.dart';

class BrowseGroupsScreen extends StatefulWidget {
  const BrowseGroupsScreen({super.key});

  @override
  State<BrowseGroupsScreen> createState() => _BrowseGroupsScreenState();
}

class _BrowseGroupsScreenState extends State<BrowseGroupsScreen> {
  bool _isLoading = true;
  List<VillageGroup> _availableGroups = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);

    try {
      final groupProvider = context.read<GroupProvider>();
      final groups = await groupProvider.loadAllGroups();

      setState(() {
        _availableGroups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading groups: $e')),
        );
      }
    }
  }

  List<VillageGroup> get _filteredGroups {
    if (_searchQuery.isEmpty) return _availableGroups;

    return _availableGroups.where((group) {
      return group.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (group.location?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(
          'Browse Groups',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search groups by name or location...',
                prefixIcon: Icon(Icons.search, color: Colors.orange.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.orange.shade50,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Groups List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.orange.shade600,
                    ),
                  )
                : _filteredGroups.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadGroups,
                        color: Colors.orange.shade600,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredGroups.length,
                          itemBuilder: (context, index) {
                            return _buildGroupCard(_filteredGroups[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.black26,
          ),
          SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No groups available' : 'No groups found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Create the first group!'
                : 'Try a different search term',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(VillageGroup group) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _showGroupDetails(group),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Group Icon
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.groups,
                      color: Colors.orange.shade600,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),

                  // Group Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (group.location != null) ...[
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.black45,
                              ),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  group.location!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              if (group.description != null) ...[
                SizedBox(height: 12),
                Text(
                  group.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              SizedBox(height: 12),

              // Bottom Info
              Row(
                children: [
                  if (group.memberCount != null) ...[
                    Icon(Icons.people, size: 16, color: Colors.black38),
                    SizedBox(width: 4),
                    Text(
                      '${group.memberCount} members',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                  Spacer(),
                  TextButton(
                    onPressed: () => _joinGroup(group),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade600,
                      backgroundColor: Colors.orange.shade50,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Join Group',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showGroupDetails(VillageGroup group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDashboardScreen(group: group),
      ),
    );
  }

  Future<void> _joinGroup(VillageGroup group) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to join a group')),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Join Group?'),
        content: Text(
          'Do you want to join "${group.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text('Join'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final groupProvider = context.read<GroupProvider>();
      final success = await groupProvider.joinGroup(
        groupId: group.id,
        userId: authProvider.currentUser!.id,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined "${group.name}"!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join group. Please try again.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }
}
