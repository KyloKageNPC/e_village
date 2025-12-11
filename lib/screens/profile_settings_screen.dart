import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/notification_provider.dart';
import 'edit_profile_screen.dart';
import '../utils/routes.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.userProfile;
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.orange.shade600,
                        Colors.orange.shade400,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      // Avatar
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Text(
                            user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        user?.fullName ?? 'User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        authProvider.currentUser?.email ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      SizedBox(height: 8),
                      if (user?.phoneNumber != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              user!.phoneNumber!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.edit, size: 18),
                        label: Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.orange.shade600,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 20),

            // Account Information
            _buildSection(
              title: 'Account Information',
              children: [
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final user = authProvider.userProfile;
                    return Column(
                      children: [
                        if (user?.idNumber != null)
                          _buildInfoTile(
                            icon: Icons.badge,
                            title: 'ID Number',
                            value: user!.idNumber!,
                          ),
                        if (user?.dateOfBirth != null)
                          _buildInfoTile(
                            icon: Icons.cake,
                            title: 'Date of Birth',
                            value: _formatDate(user!.dateOfBirth!),
                          ),
                        if (user?.address != null)
                          _buildInfoTile(
                            icon: Icons.location_on,
                            title: 'Address',
                            value: user!.address!,
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: 20),

            // Current Group
            _buildSection(
              title: 'Current Group',
              children: [
                Consumer<GroupProvider>(
                  builder: (context, groupProvider, _) {
                    final group = groupProvider.selectedGroup;
                    if (group == null) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No group selected',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        _buildInfoTile(
                          icon: Icons.groups,
                          title: 'Group Name',
                          value: group.name,
                        ),
                        if (group.location != null)
                          _buildInfoTile(
                            icon: Icons.place,
                            title: 'Location',
                            value: group.location!,
                          ),
                        _buildInfoTile(
                          icon: Icons.people,
                          title: 'Members',
                          value: '${groupProvider.groupMembers.length} members',
                        ),
                        _buildInfoTile(
                          icon: Icons.admin_panel_settings,
                          title: 'Your Role',
                          value: groupProvider.currentMembership?.role.toString().split('.').last.toUpperCase() ?? 'MEMBER',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),

            SizedBox(height: 20),

            // Notification Settings
            Consumer<NotificationProvider>(
              builder: (context, notifProvider, _) {
                return _buildSection(
                  title: 'Notifications',
                  children: [
                    SwitchListTile(
                      secondary: Icon(Icons.notifications, color: Colors.orange.shade600),
                      title: Text('Enable Notifications'),
                      subtitle: Text('Receive push notifications'),
                      value: notifProvider.notificationsEnabled,
                      activeTrackColor: Colors.orange.shade600,
                      onChanged: (value) {
                        notifProvider.toggleNotifications(value);
                      },
                    ),
                    if (notifProvider.notificationsEnabled) ...[
                      Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(Icons.email, color: Colors.blue.shade600),
                        title: Text('Email Notifications'),
                        subtitle: Text('Receive notifications via email'),
                        value: notifProvider.emailNotifications,
                        activeTrackColor: Colors.orange.shade600,
                        onChanged: (value) {
                          notifProvider.toggleEmailNotifications(value);
                        },
                      ),
                      Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(Icons.account_balance_wallet, color: Colors.green.shade600),
                        title: Text('Loan Alerts'),
                        subtitle: Text('Loan requests and approvals'),
                        value: notifProvider.loanAlerts,
                        activeTrackColor: Colors.orange.shade600,
                        onChanged: (value) {
                          notifProvider.toggleLoanAlerts(value);
                        },
                      ),
                      Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(Icons.event, color: Colors.purple.shade600),
                        title: Text('Meeting Reminders'),
                        subtitle: Text('Upcoming meetings and attendance'),
                        value: notifProvider.meetingReminders,
                        activeTrackColor: Colors.orange.shade600,
                        onChanged: (value) {
                          notifProvider.toggleMeetingReminders(value);
                        },
                      ),
                      Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(Icons.chat, color: Colors.teal.shade600),
                        title: Text('Chat Messages'),
                        subtitle: Text('New messages in group chat'),
                        value: notifProvider.chatNotifications,
                        activeTrackColor: Colors.orange.shade600,
                        onChanged: (value) {
                          notifProvider.toggleChatNotifications(value);
                        },
                      ),
                      Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(Icons.savings, color: Colors.amber.shade600),
                        title: Text('Contribution Reminders'),
                        subtitle: Text('Monthly contribution reminders'),
                        value: notifProvider.contributionReminders,
                        activeTrackColor: Colors.orange.shade600,
                        onChanged: (value) {
                          notifProvider.toggleContributionReminders(value);
                        },
                      ),
                    ],
                  ],
                );
              },
            ),

            SizedBox(height: 20),

            // App Settings
            _buildSection(
              title: 'App Settings',
              children: [
                ListTile(
                  leading: Icon(Icons.language, color: Colors.orange.shade600),
                  title: Text('Language'),
                  subtitle: Text('English'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement language selection
                    _showComingSoon(context);
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.security, color: Colors.orange.shade600),
                  title: Text('Security'),
                  subtitle: Text('Change password, biometrics'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement security settings
                    _showComingSoon(context);
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.storage, color: Colors.orange.shade600),
                  title: Text('Data & Storage'),
                  subtitle: Text('Manage offline data'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement data management
                    _showComingSoon(context);
                  },
                ),
              ],
            ),

            SizedBox(height: 20),

            // About & Support
            _buildSection(
              title: 'About & Support',
              children: [
                ListTile(
                  leading: Icon(Icons.info, color: Colors.orange.shade600),
                  title: Text('About E-Village Banking'),
                  subtitle: Text('Version 1.0.0'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.help, color: Colors.orange.shade600),
                  title: Text('Help & Support'),
                  subtitle: Text('FAQs and contact us'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showComingSoon(context);
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: Colors.orange.shade600),
                  title: Text('Privacy Policy'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showComingSoon(context);
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.description, color: Colors.orange.shade600),
                  title: Text('Terms of Service'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showComingSoon(context);
                  },
                ),
              ],
            ),

            SizedBox(height: 20),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: Icon(Icons.logout),
                  label: Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange.shade600),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Colors.black.withValues(alpha: 0.6),
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coming soon!'),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_balance, color: Colors.orange.shade600),
            SizedBox(width: 8),
            Text('E-Village Banking'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'A modern mobile application for village banking groups to manage savings, loans, and group activities.',
            ),
            SizedBox(height: 16),
            Text(
              '© 2025 E-Village Banking',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await context.read<AuthProvider>().signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }
}
