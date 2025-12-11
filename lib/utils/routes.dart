import 'package:flutter/material.dart';
import '../hompage.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/complete_profile_screen.dart';
import '../screens/group/group_selection_screen.dart';
import '../screens/group/group_chat_screen.dart';
import '../screens/make_contribution_screen.dart';
import '../screens/contribution_history_screen.dart';
import '../screens/loan_approvals_screen.dart';
import '../screens/meetings_list_screen.dart';
import '../screens/guarantor_requests_screen.dart';
import '../screens/my_loans_screen.dart';
import '../screens/profile_settings_screen.dart';

class AppRoutes {
  // Route names
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String completeProfile = '/complete-profile';
  static const String groupSelection = '/group-selection';
  static const String groupChat = '/group-chat';
  static const String makeContribution = '/make-contribution';
  static const String contributionHistory = '/contribution-history';
  static const String loanApprovals = '/loan-approvals';
  static const String meetings = '/meetings';
  static const String guarantorRequests = '/guarantor-requests';
  static const String myLoans = '/my-loans';
  static const String profileSettings = '/profile-settings';

  // Route generator
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const MyHomePage());
      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => SignupScreen());
      case completeProfile:
        return MaterialPageRoute(builder: (_) => CompleteProfileScreen());
      case groupSelection:
        return MaterialPageRoute(builder: (_) => GroupSelectionScreen());
      case groupChat:
        return MaterialPageRoute(builder: (_) => GroupChatScreen());
      case makeContribution:
        return MaterialPageRoute(builder: (_) => MakeContributionScreen());
      case contributionHistory:
        return MaterialPageRoute(builder: (_) => ContributionHistoryScreen());
      case loanApprovals:
        return MaterialPageRoute(builder: (_) => LoanApprovalsScreen());
      case meetings:
        return MaterialPageRoute(builder: (_) => MeetingsListScreen());
      case guarantorRequests:
        return MaterialPageRoute(builder: (_) => GuarantorRequestsScreen());
      case myLoans:
        return MaterialPageRoute(builder: (_) => MyLoansScreen());
      case profileSettings:
        return MaterialPageRoute(builder: (_) => ProfileSettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
