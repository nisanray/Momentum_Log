import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import 'signup_screen.dart';
import '../widgets/app_logo.dart';
import '../main.dart'; // For theme colors

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  // Use a GlobalKey for the Form if you want to use Form validation
  // final _formKey = GlobalKey<FormState>();

  Future<void> _loginUser() async {
    // if (_formKey.currentState?.validate() ?? false) { // If using Form validation
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = ''; });

    // Access AuthController once, listen: false as it's for an action
    final authController = Provider.of<AuthController>(context, listen: false);
    final error = await authController.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return; // Check mounted again after async operation
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMessage = error);
    }
    // AuthGate will handle navigation if login is successful
    // }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppLogo(size: 70), // Consistent logo size
              const SizedBox(height: 24),
              Text(
                "Welcome Back",
                style: theme.textTheme.navLargeTitleTextStyle.copyWith(fontSize: 28, color: kTextColorLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Log in to continue your momentum.",
                style: theme.textTheme.textStyle.copyWith(color: kSecondaryTextColorLight, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40), // More space before form
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                style: theme.textTheme.textStyle,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                    color: kTextFieldBackgroundLight, // Use themed text field background
                    borderRadius: BorderRadius.circular(12)),
                prefix: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(CupertinoIcons.mail_solid, color: kSubtleTextColorLight, size: 20)),
              ),
              const SizedBox(height: 18),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                style: theme.textTheme.textStyle,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                    color: kTextFieldBackgroundLight,
                    borderRadius: BorderRadius.circular(12)),
                prefix: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(CupertinoIcons.lock_fill, color: kSubtleTextColorLight, size: 20)),
                onSubmitted: _isLoading ? null : (_) => _loginUser(),
              ),
              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    _errorMessage,
                    style: theme.textTheme.textStyle.copyWith(color: CupertinoColors.systemRed, fontSize: 14, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 28),
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator(radius: 16))
                  : CupertinoButton(
                color: kAppPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(12),
                onPressed: _loginUser,
                child: Text('Sign In', style: theme.textTheme.textStyle.copyWith(color: CupertinoColors.white, fontWeight: FontWeight.w600, fontSize: 17)),
              ),
              const SizedBox(height: 24), // More spacing
              CupertinoButton(
                onPressed: _isLoading ? null : () {
                  Navigator.of(context).push(CupertinoPageRoute(builder: (_) => SignUpScreen()));
                },
                child: Text.rich(
                  TextSpan(
                      text: "Don't have an account? ",
                      style: theme.textTheme.textStyle.copyWith(color: kSecondaryTextColorLight, fontSize: 15),
                      children: [
                        TextSpan(text: 'Sign Up', style: TextStyle(color: kAppPrimaryColor, fontWeight: FontWeight.w600))
                      ]
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}