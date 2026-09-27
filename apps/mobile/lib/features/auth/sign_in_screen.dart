import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_brand_logo.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  static const demoEmail = 'caregiver@hani-maak.demo';
  static const demoPassword = 'HaniMaak2026!';

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool loading = false;
  bool obscure = true;
  bool signUp = false;
  String? error;
  String? message;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  String tr({
    required String tn,
    required String ar,
    required String en,
    required String fr,
  }) =>
      haniText(ref.read(appSettingsProvider).language,
          tn: tn, ar: ar, en: en, fr: fr);

  Future<void> _submit() async {
    final mail = email.text.trim();
    final pass = password.text;

    if (mail.isEmpty || pass.length < 6) {
      setState(() {
        error = tr(
          tn: 'اكتب إيميل صحيح وكلمة سر فيها 6 حروف على الأقل.',
          ar: 'أدخل بريدًا صحيحًا وكلمة مرور من 6 أحرف على الأقل.',
          en: 'Enter a valid email and a password with at least 6 characters.',
          fr: 'Saisissez un e-mail valide et un mot de passe d’au moins 6 caractères.',
        );
      });
      return;
    }

    if (!signUp &&
        mail == SignInScreen.demoEmail &&
        pass == SignInScreen.demoPassword) {
      if (mounted) context.go('/today');
      return;
    }

    if (!AppConfig.hasSupabaseAuth) {
      setState(() {
        error = tr(
          tn: 'استعمل حساب الديمو. الدخول الحقيقي موش مفعّل في النسخة هاذي.',
          ar: 'استخدم حساب العرض. المصادقة الحقيقية غير مفعلة في هذا الإصدار.',
          en: 'Use the demo account. Production authentication is not configured in this build.',
          fr: 'Utilisez le compte démo. L’authentification de production n’est pas configurée.',
        );
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
      message = null;
    });

    try {
      if (signUp) {
        final result = await Supabase.instance.client.auth.signUp(
          email: mail,
          password: pass,
        );
        if (!mounted) return;
        if (result.session != null) {
          context.go('/today');
        } else {
          setState(() {
            message = tr(
              tn: 'تسجّلت. ثبّت الإيميل متاعك وبعد ادخل.',
              ar: 'تم إنشاء الحساب. أكد بريدك الإلكتروني ثم سجل الدخول.',
              en: 'Account created. Confirm your email, then sign in.',
              fr: 'Compte créé. Confirmez votre e-mail puis connectez-vous.',
            );
            signUp = false;
          });
        }
      } else {
        await Supabase.instance.client.auth.signInWithPassword(
          email: mail,
          password: pass,
        );
        if (mounted) context.go('/today');
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          error = tr(
            tn: 'الخدمة موش متاحة توّة. عاود جرّب.',
            ar: 'الخدمة غير متاحة مؤقتًا. حاول مجددًا.',
            en: 'Authentication is temporarily unavailable. Try again.',
            fr: 'L’authentification est temporairement indisponible. Réessayez.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _useDemo() {
    email.text = SignInScreen.demoEmail;
    password.text = SignInScreen.demoPassword;
    setState(() {
      signUp = false;
      error = null;
      message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    String t(String tn, String ar, String en, String fr) =>
        haniText(settings.language, tn: tn, ar: ar, en: en, fr: fr);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
              children: [
                Row(
                  children: [
                    const HaniBrandLogo(
                      variant: HaniBrandVariant.horizontal,
                      height: 52,
                    ),
                    const Spacer(),
                    PopupMenuButton<HaniLanguage>(
                      tooltip: t('اللغة', 'اللغة', 'Language', 'Langue'),
                      initialValue: settings.language,
                      onSelected:
                          ref.read(appSettingsProvider.notifier).setLanguage,
                      itemBuilder: (_) => HaniLanguage.values
                          .map((language) => PopupMenuItem(
                                value: language,
                                child: Text(language.label),
                              ))
                          .toList(),
                      child: const Icon(Icons.language_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 44),
                Text(
                  signUp
                      ? t('اعمل حساب جديد', 'إنشاء حساب جديد',
                          'Create your account', 'Créer votre compte')
                      : t('ادخل لهاني معاك', 'تسجيل الدخول إلى هاني معك',
                          'Sign in to Hani Maak', 'Se connecter à Hani Maak'),
                  style: const TextStyle(
                    fontSize: 32,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 28),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.login_rounded),
                      label: Text(t('دخول', 'تسجيل الدخول', 'Sign In', 'Connexion')),
                    ),
                    ButtonSegment(
                      value: true,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(t('حساب جديد', 'إنشاء حساب', 'Sign Up', 'Créer un compte')),
                    ),
                  ],
                  selected: {signUp},
                  onSelectionChanged: loading
                      ? null
                      : (value) => setState(() {
                            signUp = value.first;
                            error = null;
                            message = null;
                          }),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: t('الإيميل', 'البريد الإلكتروني', 'Email', 'E-mail'),
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: obscure,
                  autofillHints: signUp
                      ? const [AutofillHints.newPassword]
                      : const [AutofillHints.password],
                  onSubmitted: (_) => loading ? null : _submit(),
                  decoration: InputDecoration(
                    labelText: t('كلمة السر', 'كلمة المرور', 'Password', 'Mot de passe'),
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
                  Text(error!, style: const TextStyle(color: HaniColors.danger)),
                ],
                if (message != null) ...[
                  const SizedBox(height: 12),
                  Text(message!, style: const TextStyle(color: HaniColors.primary)),
                ],
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: loading ? null : _submit,
                  icon: Icon(signUp
                      ? Icons.person_add_alt_1_rounded
                      : Icons.login_rounded),
                  label: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(signUp
                          ? t('اعمل الحساب', 'إنشاء الحساب', 'Create account', 'Créer le compte')
                          : t('ادخل', 'تسجيل الدخول', 'Sign in', 'Se connecter')),
                ),
                if (!signUp) ...[
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: _useDemo,
                    icon: const Icon(Icons.science_outlined),
                    label: Text(t(
                      'استعمل حساب الديمو',
                      'استخدم حساب العرض',
                      'Use demo account',
                      'Utiliser le compte démo',
                    )),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
