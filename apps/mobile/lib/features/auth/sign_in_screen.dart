import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!AppConfig.hasSupabaseAuth) {
      setState(() => error = 'Authentication is not configured in this build.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
      if (mounted) context.go('/today');
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'Sign-in is temporarily unavailable.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        children: [
          const Text('Welcome back', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SizedBox(height: 6),
          const Text('Sign in to your caregiver space.', style: TextStyle(color: HaniColors.muted)),
          const SizedBox(height: 28),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(color: Colors.redAccent)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: loading ? null : _submit,
            child: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sign in'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/today'),
            child: const Text('Continue with demo instead'),
          ),
        ],
      ),
    );
  }
}
