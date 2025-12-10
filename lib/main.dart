import 'package:e_village/hompage.dart';
import 'package:e_village/screens/auth/login_screen.dart';
import 'package:e_village/screens/complete_profile_screen.dart';
import 'package:e_village/screens/group/group_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/loan_provider.dart';
import 'providers/group_provider.dart';
import 'providers/savings_provider.dart';
import 'providers/meeting_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/guarantor_provider.dart';
import 'providers/repayment_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => LoanProvider()),
        ChangeNotifierProvider(create: (_) => GroupProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => SavingsProvider()),
        ChangeNotifierProvider(create: (_) => MeetingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => GuarantorProvider()),
        ChangeNotifierProvider(create: (_) => RepaymentProvider()),
      ],
      child: Consumer2<AuthProvider, GroupProvider>(
        builder: (context, authProvider, groupProvider, _) {
          // Determine home screen based on auth, profile, and group selection status
          Widget home;
          if (!authProvider.isAuthenticated) {
            home = LoginScreen();
          } else if (authProvider.userProfile == null ||
              authProvider.userProfile!.idNumber == null ||
              authProvider.userProfile!.dateOfBirth == null ||
              authProvider.userProfile!.address == null) {
            home = CompleteProfileScreen();
          } else if (!groupProvider.hasSelectedGroup) {
            home = GroupSelectionScreen();
          } else {
            home = MyHomePage();
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'E-Village Banking',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrangeAccent),
              useMaterial3: true,
            ),
            home: home,
          );
        },
      ),
    );
  }
}

