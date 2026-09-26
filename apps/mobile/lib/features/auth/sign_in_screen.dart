import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_ui.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  static const demoEmail = 'caregiver@hani-maak.demo';
  static const demoPassword = 'HaniMaak2026!';

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;
  String? error;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void _fillDemo() {
    email.text = SignInScreen.demoEmail;
    password.text = SignInScreen.demoPassword;
    setState(() => error = null);
  }

  Future<void> _submit() async {
    final mail = email.text.trim();
    final pass = password.text;

    if (mail == SignInScreen.demoEmail &&
        pass == SignInScreen.demoPassword) {
      if (mounted) context.go('/today');
      return;
    }

    if (!AppConfig.hasSupabaseAuth) {
      setState(
        () => error =
            'Use the demo credentials below. Production authentication is not configured in this build.',
      );
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: mail,
        password: pass,
      );
      if (mounted) context.go('/today');
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Sign-in is temporarily unavailable.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 34),
            children: [
              const Center(child: HaniBrandMark(size: 64)),
              const SizedBox(height: 22),
              const HaniPill(
                label: 'Secure caregiver space',
                icon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 18),
              const Text(
                'Welcome back.',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Continue your private caregiver journey with Hani.',
                style: TextStyle(color: HaniColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 26),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: obscure,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error!,
                  style: const TextStyle(color: HaniColors.danger),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: loading ? null : _submit,
                child: loading
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: 18),
              HaniGradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HaniPill(
                      label: 'JUDGE DEMO',
                      icon: Icons.science_outlined,
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Demo access',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const SelectableText(
                      'caregiver@hani-maak.demo\nHaniMaak2026!',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        height: 1.55,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _fillDemo,
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: const Text('Fill demo credentials'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
