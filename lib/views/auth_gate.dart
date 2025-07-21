import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart'; // Ensure this path is correct for your LoginScreen
import 'daily_logging_screen.dart'; // Ensure this path is correct for your DailyLoggingScreen

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use context.watch<AuthController>() to ensure this widget rebuilds
    // when AuthController calls notifyListeners().
    final authController = context.watch<AuthController>();

    // Critical Debug Print:
    debugPrint("AuthGate build: isAuthenticated = ${authController.isAuthenticated}, UserID: ${authController.userId}");

    if (authController.isAuthenticated) {
      debugPrint("AuthGate: User is Authenticated. Navigating to DailyLoggingScreen.");
      return const DailyLoggingScreen(); // Or your main app screen
    } else {
      debugPrint("AuthGate: User is NOT Authenticated. Navigating to LoginScreen.");
      return const LoginScreen(); // Or your login screen
    }
  }
}