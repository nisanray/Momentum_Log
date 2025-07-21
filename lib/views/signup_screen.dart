import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../widgets/app_logo.dart';
import '../main.dart'; // For theme colors

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _signUpUser() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = ''; });

    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty) {
      if (mounted) setState(() => _errorMessage = 'Please enter your full name.');
      setState(() => _isLoading = false); return;
    }
    if (email.isEmpty) {
      if (mounted) setState(() => _errorMessage = 'Please enter your email address.');
      setState(() => _isLoading = false); return;
    }
    if (password.isEmpty) {
      if (mounted) setState(() => _errorMessage = 'Please enter a password.');
      setState(() => _isLoading = false); return;
    }
    if (password.length < 6) {
      if (mounted) setState(() => _errorMessage = 'Password must be at least 6 characters.');
      setState(() => _isLoading = false); return;
    }
    if (password != confirmPassword) {
      if (mounted) setState(() => _errorMessage = 'Passwords do not match.');
      setState(() => _isLoading = false); return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    final error = await authController.signUp(name, email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      // AuthGate will handle navigation after successful sign up and auth state change
      // Pop back to login or directly to main screen if AuthGate handles it fast enough
      if (Navigator.canPop(context)) Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() => _errorMessage = error);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return CupertinoPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Create Account'),
        previousPageTitle: 'Sign In',
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppLogo(size: 60),
              const SizedBox(height: 20),
              Text(
                "Join Momentum Log",
                style: theme.textTheme.navLargeTitleTextStyle.copyWith(fontSize: 26, color: kTextColorLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Let's get you started on your journey.",
                style: theme.textTheme.textStyle.copyWith(color: kSecondaryTextColorLight, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Full Name',
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                style: theme.textTheme.textStyle,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                    color: kTextFieldBackgroundLight,
                    borderRadius: BorderRadius.circular(12)),
                prefix: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(CupertinoIcons.person_alt_circle_fill, color: kSubtleTextColorLight, size: 20)),
              ),
              const SizedBox(height: 18),
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'Email Address',
                keyboardType: TextInputType.emailAddress,
                autocorrect: false, textInputAction: TextInputAction.next,
                style: theme.textTheme.textStyle,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                    color: kTextFieldBackgroundLight,
                    borderRadius: BorderRadius.circular(12)),
                prefix: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(CupertinoIcons.mail_solid, color: kSubtleTextColorLight, size: 20)),
              ),
              const SizedBox(height: 18),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'Password (min. 6 characters)',
                obscureText: true, textInputAction: TextInputAction.next,
                style: theme.textTheme.textStyle,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                    color: kTextFieldBackgroundLight,
                    borderRadius: BorderRadius.circular(12)),
                prefix: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(CupertinoIcons.lock_fill, color: kSubtleTextColorLight, size: 20)),
              ),
              const SizedBox(height: 18),
              CupertinoTextField(
                controller: _confirmPasswordController,
                placeholder: 'Confirm Password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                style: theme.textTheme.textStyle,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                    color: kTextFieldBackgroundLight,
                    borderRadius: BorderRadius.circular(12)),
                prefix: const Padding(padding: EdgeInsets.only(left: 16), child: Icon(CupertinoIcons.lock_shield_fill, color: kSubtleTextColorLight, size: 20)),
                onSubmitted: _isLoading ? null : (_) => _signUpUser(),
              ),
              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(_errorMessage, style: theme.textTheme.textStyle.copyWith(color: CupertinoColors.systemRed, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                ),
              const SizedBox(height: 28),
              _isLoading
                  ? const Center(child: CupertinoActivityIndicator(radius: 16))
                  : CupertinoButton(
                color: kAppPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(12),
                onPressed: _signUpUser,
                child: Text('Create Account', style: theme.textTheme.textStyle.copyWith(color: CupertinoColors.white, fontWeight: FontWeight.w600, fontSize: 17)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}