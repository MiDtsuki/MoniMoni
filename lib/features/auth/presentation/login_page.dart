import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/providers/session_providers.dart';
import '../../debts/application/debt_controller.dart';
import '../../debts/application/friends_controller.dart';
import '../../profile/application/profile_settings_controller.dart';
import '../../transactions/application/transaction_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;
  var _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Track money, debts, and spending from one calm dashboard.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(LucideIcons.mail),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(LucideIcons.lockKeyhole),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                  ),
                ),
              ),
              validator: _validatePassword,
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.logIn),
              label: const Text('Log in'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _continueAsGuest,
              icon: const Icon(LucideIcons.wifiOff),
              label: const Text('Continue as guest'),
            ),
            const SizedBox(height: 20),
            _AuthSwitchRow(
              text: 'New to Moni?',
              action: 'Create an account',
              onPressed: () => context.go('/signup'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) =>
          _ForgotPasswordDialog(prefillEmail: _emailController.text.trim()),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      _invalidateAccountProviders();
      if (mounted) context.go('/logs');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Could not sign in.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    await guestSession.enter();
    _invalidateAccountProviders();
    if (mounted) context.go('/logs');
  }

  void _invalidateAccountProviders() {
    ref
      ..invalidate(currentUserProvider)
      ..invalidate(transactionControllerProvider)
      ..invalidate(debtControllerProvider)
      ..invalidate(friendsControllerProvider)
      ..invalidate(profileSettingsProvider);
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  const _CompactBrand(),
                  const SizedBox(height: 22),
                  _AuthFormCard(title: title, subtitle: subtitle, child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactBrand extends StatelessWidget {
  const _CompactBrand();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: _BrandMark(inverted: false),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.inverted});

  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final color = inverted ? Colors.white : MoniTheme.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: inverted ? const Color(0x1FFFFFFF) : MoniTheme.softGreen,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: inverted ? const Color(0x33FFFFFF) : MoniTheme.line,
            ),
          ),
          child: Icon(
            LucideIcons.walletCards,
            color: inverted ? Colors.white : MoniTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Moni',
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _AuthFormCard extends StatelessWidget {
  const _AuthFormCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}

class _AuthSwitchRow extends StatelessWidget {
  const _AuthSwitchRow({
    required this.text,
    required this.action,
    required this.onPressed,
  });

  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          text,
          style: const TextStyle(
            color: MoniTheme.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.prefillEmail});

  final String prefillEmail;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailCtrl;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.prefillEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MoniTheme.softGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.keyRound,
              color: MoniTheme.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text('Reset password'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "We'll send a password reset link to your email.",
            style: TextStyle(color: MoniTheme.muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(LucideIcons.mail),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _submit,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.mail, size: 16),
                  label: const Text('Send email'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final emailError = _validateEmail(email);
    if (emailError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emailError)));
      return;
    }
    setState(() => _loading = true);
    // Capture the messenger and navigator before the dialog pops, so the
    // snackbar lands on the page underneath instead of being torn down with
    // the dialog (which is what made "sent" feel like nothing happened).
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final auth = FirebaseAuth.instance;
    try {
      // Lock the locale so Firebase always renders the English reset
      // template — avoids the "no email arrives" case caused by a
      // broken/empty localized template inherited from the device locale.
      await auth.setLanguageCode('en');
      // Explicit ActionCodeSettings forces Firebase to use the hosted
      // web app as the reset landing page instead of whatever continue
      // URL is cached on the project. The host moni-624c6.web.app is
      // auto-authorized for Firebase Auth, so this works without any
      // console configuration.
      await auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://moni-624c6.web.app/login',
          handleCodeInApp: false,
        ),
      );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 6),
          content: Text(
            'If that email is registered, a reset link is on the way. '
            'Check your inbox and spam folder.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'sendPasswordResetEmail failed: code=${e.code} message=${e.message}',
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(_friendlyResetError(e))));
    } catch (e) {
      debugPrint('sendPasswordResetEmail error: $e');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

String _friendlyResetError(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'That email address is not valid.';
    case 'user-not-found':
      return 'No account is registered with that email.';
    case 'too-many-requests':
      return 'Too many attempts. Try again in a few minutes.';
    case 'network-request-failed':
      return 'No internet connection. Check your network and try again.';
    case 'missing-android-pkg-name':
    case 'missing-continue-uri':
    case 'missing-ios-bundle-id':
    case 'invalid-continue-uri':
    case 'unauthorized-continue-uri':
      return 'Could not send the reset email (Firebase action URL is not configured).';
    default:
      return e.message ?? 'Could not send reset email.';
  }
}

String? _validateEmail(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) {
    return 'Enter your email';
  }
  if (!trimmed.contains('@') || !trimmed.contains('.')) {
    return 'Enter a valid email';
  }
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Enter your password';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}
