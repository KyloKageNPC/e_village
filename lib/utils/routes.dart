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
import '../screens/reports/financial_report_screen.dart';
import '../screens/reports/member_analytics_screen.dart';
import '../screens/reports/group_performance_screen.dart';
import '../screens/withdrawal_screen.dart';
import '../screens/mobile_money_history_screen.dart';
import '../screens/pending_disbursements_screen.dart';
import '../screens/balance_sheet_screen.dart';
import '../screens/cycles/cycle_list_screen.dart';

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
  static const String financialReport = '/reports/financial';
  static const String memberAnalytics = '/reports/member';
  static const String groupPerformance = '/reports/group';
  static const String withdrawal = '/withdrawal';
  static const String mobileMoneyHistory = '/mobile-money-history';
  static const String pendingDisbursements = '/pending-disbursements';
  static const String balanceSheet = '/balance-sheet';
  static const String cycles = '/cycles';

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
      case financialReport:
        return MaterialPageRoute(builder: (_) => const FinancialReportScreen());
      case memberAnalytics:
        final memberId = settings.arguments as String?;
        if (memberId == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('Member ID required for $memberAnalytics')),
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => MemberAnalyticsScreen(memberId: memberId));
      case groupPerformance:
        return MaterialPageRoute(builder: (_) => const GroupPerformanceScreen());
      case withdrawal:
        return MaterialPageRoute(builder: (_) => const WithdrawalScreen());
      case mobileMoneyHistory:
        return MaterialPageRoute(builder: (_) => const MobileMoneyHistoryScreen());
      case pendingDisbursements:
        return MaterialPageRoute(builder: (_) => const PendingDisbursementsScreen());
      case balanceSheet:
        return MaterialPageRoute(builder: (_) => const BalanceSheetScreen());
      case cycles:
        return MaterialPageRoute(builder: (_) => const CycleListScreen());
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
