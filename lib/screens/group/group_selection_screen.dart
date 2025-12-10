import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../hompage.dart';
import 'create_group_screen.dart';
import 'browse_groups_screen.dart';

class GroupSelectionScreen extends StatefulWidget {
  const GroupSelectionScreen({super.key});

  @override
  State<GroupSelectionScreen> createState() => _GroupSelectionScreenState();
}

class _GroupSelectionScreenState extends State<GroupSelectionScreen> {
  bool _isLoading = true;
  List<dynamic> _userGroups = [];

  @override
  void initState() {
    super.initState();
    _loadUserGroups();
  }

  Future<void> _loadUserGroups() async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      final groupProvider = context.read<GroupProvider>();
      final groups = await groupProvider.loadUserGroups(
        userId: authProvider.currentUser!.id,
      );

      setState(() {
        _userGroups = groups;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.orange.shade600,
                ),
              )
            : _userGroups.isEmpty
                ? _buildWelcomeScreen()
                : _buildGroupListScreen(),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups,
                size: 80,
                color: Colors.orange.shade600,
              ),
            ),
            SizedBox(height: 32),

            // Title
            Text(
              'Welcome to E-Village Banking',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),

            // Description
            Text(
              'You need to join or create a village group to start banking together',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 48),

            // Create Group Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCreateGroup(),
                icon: Icon(Icons.add_circle_outline),
                label: Text('Create New Group'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Join Group Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _navigateToBrowseGroups(),
                icon: Icon(Icons.search),
                label: Text('Join Existing Group'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade600,
                  side: BorderSide(color: Colors.orange.shade600, width: 2),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupListScreen() {
    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Village Groups',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Select a group to continue',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),

        // Group List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _userGroups.length,
            itemBuilder: (context, index) {
              final group = _userGroups[index];
              return _buildGroupCard(group);
            },
          ),
        ),

        // Add Group Buttons
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToBrowseGroups(),
                  icon: Icon(Icons.search, size: 20),
                  label: Text('Join Group'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange.shade600,
                    side: BorderSide(color: Colors.orange.shade600),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToCreateGroup(),
                  icon: Icon(Icons.add, size: 20),
                  label: Text('Create Group'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(dynamic group) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _selectGroup(group),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
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
                  size: 32,
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
                          Text(
                            group.location!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (group.memberCount != null) ...[
                      SizedBox(height: 4),
                      Text(
                        '${group.memberCount} members',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.black26,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectGroup(dynamic group) async {
    final authProvider = context.read<AuthProvider>();
    final groupProvider = context.read<GroupProvider>();

    if (authProvider.currentUser == null) return;

    try {
      await groupProvider.selectGroup(group, authProvider.currentUser!.id);

      if (!mounted) return;

      // Navigate to homepage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyHomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _navigateToCreateGroup() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CreateGroupScreen()),
    );

    if (result == true) {
      _loadUserGroups();
    }
  }

  Future<void> _navigateToBrowseGroups() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BrowseGroupsScreen()),
    );

    if (result == true) {
      _loadUserGroups();
    }
  }
}
