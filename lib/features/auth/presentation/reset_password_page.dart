import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';
import 'login_page.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  var _obscurePassword = true;
  var _obscureConfirm = true;
  var _loading = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  _PasswordStrength get _strength => _passwordStrength(_passwordController.text);

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'New password',
      subtitle: 'Choose a strong password to keep your account safe.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // New password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'New password',
                prefixIcon: const Icon(LucideIcons.lockKeyhole),
                suffixIcon: IconButton(
                  tooltip: _obscurePassword ? 'Show' : 'Hide',
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(_obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Enter your new password';
                if (value.length < 6) return 'At least 6 characters required';
                return null;
              },
            ),
            const SizedBox(height: 10),
            // Strength indicator
            if (_passwordController.text.isNotEmpty) _StrengthBar(strength: _strength),
            const SizedBox(height: 14),
            // Confirm password field
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: const Icon(LucideIcons.lockKeyhole),
                suffixIcon: IconButton(
                  tooltip: _obscureConfirm ? 'Show' : 'Hide',
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icon(_obscureConfirm ? LucideIcons.eye : LucideIcons.eyeOff),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Confirm your password';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.check),
              label: const Text('Update password'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated — you are now logged in.')),
      );
      context.go('/logs');
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ─── Password strength ────────────────────────────────────────────────────────

enum _PasswordStrength { weak, fair, good, strong }

_PasswordStrength _passwordStrength(String password) {
  if (password.length < 6) return _PasswordStrength.weak;
  var score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
  return switch (score) {
    0 => _PasswordStrength.weak,
    1 => _PasswordStrength.fair,
    2 || 3 => _PasswordStrength.good,
    _ => _PasswordStrength.strong,
  };
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.strength});
  final _PasswordStrength strength;

  static const _labels = {
    _PasswordStrength.weak: 'Weak',
    _PasswordStrength.fair: 'Fair',
    _PasswordStrength.good: 'Good',
    _PasswordStrength.strong: 'Strong',
  };

  static const _colors = {
    _PasswordStrength.weak: Color(0xFFEF4444),
    _PasswordStrength.fair: Color(0xFFF97316),
    _PasswordStrength.good: Color(0xFFEAB308),
    _PasswordStrength.strong: MoniTheme.primaryGreen,
  };

  static const _segments = {
    _PasswordStrength.weak: 1,
    _PasswordStrength.fair: 2,
    _PasswordStrength.good: 3,
    _PasswordStrength.strong: 4,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[strength]!;
    final filled = _segments[strength]!;
    final label = _labels[strength]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: List.generate(4, (i) {
            final active = i < filled;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: active ? color : MoniTheme.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
