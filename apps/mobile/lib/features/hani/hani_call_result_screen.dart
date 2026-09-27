import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notification_service.dart';
import '../../core/settings/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/hani_brand_logo.dart';
import 'models/hani_emotion_analysis.dart';

class HaniCallResultScreen extends ConsumerStatefulWidget {
  const HaniCallResultScreen({
    super.key,
    required this.conversationId,
  });

  final String conversationId;

  @override
  ConsumerState<HaniCallResultScreen> createState() =>
      _HaniCallResultScreenState();
}

class _HaniCallResultScreenState
    extends ConsumerState<HaniCallResultScreen> {
  final HaniEmotionApi _api = HaniEmotionApi();
  HaniEmotionAnalysis? _analysis;
  Object? _error;
  Timer? _timer;
  int _pollCount = 0;
  bool _timedOut = false;
  bool _readyNotificationSent = false;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _api.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _timer?.cancel();
      _pollCount = 0;
      _timedOut = false;
      if (mounted) {
        setState(() {
          _error = null;
        });
      }
    }

    try {
      final result = await _api.fetch(widget.conversationId);
      if (!mounted) return;
      setState(() {
        _analysis = result;
        _error = null;
      });

      if (result.status == 'completed' && !_readyNotificationSent) {
        _readyNotificationSent = true;
        final language = ref.read(appSettingsProvider).language;
        unawaited(
          HaniNotificationService.instance
              .showPostCall(
                conversationId: widget.conversationId,
                language: language,
                analysisReady: true,
              )
              .catchError((_) {}),
        );
      }

      if (result.status == 'processing' || result.status == 'not_started') {
        _pollCount += 1;
        if (_pollCount >= 20) {
          setState(() => _timedOut = true);
          return;
        }
        final delay = _pollCount < 8
            ? const Duration(milliseconds: 900)
            : const Duration(milliseconds: 1600);
        _timer?.cancel();
        _timer = Timer(delay, _load);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
      _pollCount += 1;
      if (_pollCount >= 8) {
        setState(() => _timedOut = true);
        return;
      }
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 2), _load);
    }
  }

  String tr(
    HaniLanguage language, {
    required String tn,
    required String ar,
    required String en,
    required String fr,
  }) =>
      haniText(language, tn: tn, ar: ar, en: en, fr: fr);

  String _stageLabel(HaniLanguage language) {
    if (_pollCount <= 2) {
      return tr(
        language,
        tn: 'نحضّر الصوت',
        ar: 'تحضير الصوت',
        en: 'Preparing audio',
        fr: 'Préparation de l’audio',
      );
    }
    if (_pollCount <= 9) {
      return tr(
        language,
        tn: 'نحلّل نبرة الصوت',
        ar: 'تحليل الإشارات الصوتية',
        en: 'Analyzing',
        fr: 'Analyse en cours',
      );
    }
    return tr(
      language,
      tn: 'نحفظ النتيجة',
      ar: 'حفظ النتيجة',
      en: 'Saving result',
      fr: 'Enregistrement du résultat',
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appSettingsProvider).language;
    final analysis = _analysis;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),
      appBar: AppBar(
        title: const HaniBrandLogo(
          height: 38,
          variant: HaniBrandVariant.horizontal,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          Text(
            tr(
              language,
              tn: 'المكالمة كمّلت',
              ar: 'انتهت المكالمة',
              en: 'Call completed',
              fr: 'Appel terminé',
            ),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr(
              language,
              tn: 'هاني يحلّل كان صوت المستخدم، من غير صوت هاني.',
              ar: 'يحلّل هاني صوت المستخدم فقط، دون صوت المساعد.',
              en: 'Hani analyzes patient-side voice only, never Hani’s generated voice.',
              fr: 'Hani analyse uniquement la voix côté patient, jamais la voix générée de Hani.',
            ),
            style: const TextStyle(
              color: HaniColors.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          if (_timedOut)
            _StatusCard(
              icon: Icons.timer_off_outlined,
              title: tr(
                language,
                tn: 'التحليل طول أكثر من العادة',
                ar: 'استغرق التحليل وقتًا أطول من المعتاد',
                en: 'Analysis is taking longer than expected',
                fr: 'L’analyse prend plus de temps que prévu',
              ),
              body: tr(
                language,
                tn: 'المكالمة محفوظة. تنجم تعاود التثبّت من غير ما تعاود المكالمة.',
                ar: 'المكالمة محفوظة. يمكنك إعادة التحقق دون إعادة المكالمة.',
                en: 'The call is saved. Retry the result check without repeating the call.',
                fr: 'L’appel est enregistré. Réessayez la vérification sans refaire l’appel.',
              ),
              actionLabel: tr(
                language,
                tn: 'عاود جرّب',
                ar: 'حاول مجددًا',
                en: 'Retry',
                fr: 'Réessayer',
              ),
              onAction: () => _load(reset: true),
            )
          else if (_error != null && analysis == null)
            _StatusCard(
              icon: Icons.sync_problem_rounded,
              title: tr(
                language,
                tn: 'التحليل موش متاح توّة',
                ar: 'التحليل غير متاح مؤقتًا',
                en: 'Analysis is temporarily unavailable',
                fr: 'Analyse temporairement indisponible',
              ),
              body: tr(
                language,
                tn: 'المكالمة كمّلت عادي. عاود جرّب التثبّت.',
                ar: 'تمت المكالمة بشكل طبيعي. حاول التحقق مجددًا.',
                en: 'The Hani call completed normally. Retry the result check.',
                fr: 'L’appel Hani s’est terminé normalement. Réessayez la vérification.',
              ),
              actionLabel: tr(
                language,
                tn: 'عاود جرّب',
                ar: 'حاول مجددًا',
                en: 'Retry',
                fr: 'Réessayer',
              ),
              onAction: () => _load(reset: true),
            )
          else if (analysis == null ||
              analysis.status == 'processing' ||
              analysis.status == 'not_started')
            _StatusCard(
              icon: Icons.graphic_eq_rounded,
              title: _stageLabel(language),
              body: tr(
                language,
                tn: 'الخدمة تخدم بعد المكالمة وما تعطّلش هاني المباشر.',
                ar: 'تعمل الخدمة بعد المكالمة ولا تؤثر على المحادثة المباشرة.',
                en: 'Post-call processing runs separately and never blocks live Hani.',
                fr: 'Le traitement post-appel est séparé et ne bloque jamais Hani en direct.',
              ),
              loading: true,
            )
          else if (analysis.status == 'insufficient_audio')
            _StatusCard(
              icon: Icons.hearing_disabled_rounded,
              title: tr(
                language,
                tn: 'الصوت موش كافي',
                ar: 'الكلام غير كافٍ',
                en: 'Not enough speech',
                fr: 'Parole insuffisante',
              ),
              body: tr(
                language,
                tn: 'ما كانش فما كلام كافي باش نعطيوا تقدير موثوق.',
                ar: 'لم يتوفر كلام كافٍ لتقدير الإشارات الصوتية بشكل موثوق.',
                en: 'There was not enough patient speech for a reliable vocal estimate.',
                fr: 'Il n’y avait pas assez de parole pour une estimation vocale fiable.',
              ),
            )
          else if (analysis.status == 'failed')
            _StatusCard(
              icon: Icons.info_outline_rounded,
              title: tr(
                language,
                tn: 'التحليل الصوتي ما كملش',
                ar: 'تعذر إكمال التحليل الصوتي',
                en: 'Vocal analysis unavailable',
                fr: 'Analyse vocale indisponible',
              ),
              body: analysis.failureMessage?.isNotEmpty == true
                  ? analysis.failureMessage!
                  : tr(
                      language,
                      tn: 'المكالمة محفوظة حتى كان التحليل ما كملش.',
                      ar: 'المكالمة محفوظة حتى لو تعذر التحليل.',
                      en: 'The call remains saved even though this supplementary analysis failed.',
                      fr: 'L’appel reste enregistré même si cette analyse complémentaire a échoué.',
                    ),
              actionLabel: tr(
                language,
                tn: 'عاود التثبّت',
                ar: 'إعادة التحقق',
                en: 'Retry',
                fr: 'Réessayer',
              ),
              onAction: () => _load(reset: true),
            )
          else
            _CompletedAnalysis(analysis: analysis, language: language),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: HaniColors.line),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, color: HaniColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tr(
                      language,
                      tn: 'تقدير المشاعر الصوتية احتمالي وماهوش تشخيص طبي ولا نفسي.',
                      ar: 'تقدير المشاعر الصوتية احتمالي وليس تشخيصًا طبيًا أو نفسيًا.',
                      en: 'Vocal emotion estimates are probabilistic and are not a medical or psychiatric diagnosis.',
                      fr: 'Les estimations d’émotion vocale sont probabilistes et ne constituent pas un diagnostic médical ou psychiatrique.',
                    ),
                    style: const TextStyle(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedAnalysis extends StatelessWidget {
  const _CompletedAnalysis({
    required this.analysis,
    required this.language,
  });

  final HaniEmotionAnalysis analysis;
  final HaniLanguage language;

  String t(String tn, String ar, String en, String fr) =>
      haniText(language, tn: tn, ar: ar, en: en, fr: fr);

  @override
  Widget build(BuildContext context) {
    final dominant = analysis.dominantEmotion ?? 'unknown';
    final confidence = analysis.confidence ?? 0;
    final isTextFallback =
        analysis.model?.startsWith('gemini_text_emotion_fallback:') == true;
    final sorted = analysis.distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusCard(
          icon: isTextFallback
              ? Icons.auto_awesome_rounded
              : Icons.multiline_chart_rounded,
          title: isTextFallback
              ? t(
                  'تحليل احتياطي سريع من كلام المستخدم',
                  'تحليل احتياطي سريع من نص المستخدم',
                  'Fast emotion fallback from transcript',
                  'Analyse émotionnelle de secours à partir du texte',
                )
              : t(
                  'المشاعر في نبرة الصوت',
                  'المشاعر المكتشفة في الصوت',
                  'Detected vocal emotion',
                  'Émotion vocale détectée',
                ),
          body: '${_label(dominant)} · ${_percent(confidence)}',
        ),
        if (isTextFallback) ...[
          const SizedBox(height: 10),
          Text(
            t(
              'مودال الصوت طول أكثر من 10 ثواني، لذلك هاني استعمل تحليل Gemini على كلام المستخدم باش يعطي نتيجة سريعة.',
              'استغرق نموذج الصوت أكثر من 10 ثوانٍ، لذلك استخدم هاني تحليل Gemini للنص لتقديم نتيجة سريعة.',
              'The vocal model exceeded 10 seconds, so Hani used Gemini on the patient transcript as a fast fallback.',
              'Le modèle vocal a dépassé 10 secondes. Hani a donc utilisé Gemini sur la transcription du patient comme solution de secours rapide.',
            ),
            style: const TextStyle(
              color: HaniColors.muted,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          analysis.summary?.trim().isNotEmpty == true
              ? analysis.summary!.trim()
              : _summary(dominant),
          style: const TextStyle(
            color: HaniColors.muted,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          t(
            'توزيع الإشارات',
            'توزيع الإشارات الصوتية',
            'Vocal emotional signals',
            'Signaux émotionnels vocaux',
          ),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        ...sorted.take(8).map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    _label(entry.key),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: LinearProgressIndicator(
                    value: entry.value.clamp(0, 1),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 42,
                  child: Text(
                    _percent(entry.value),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (analysis.timeline.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            t(
              'التغيّر أثناء المكالمة',
              'تطور الإشارات أثناء المكالمة',
              'Emotion throughout the call',
              'Évolution pendant l’appel',
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...analysis.timeline.map(
            (segment) => Card(
              child: ListTile(
                leading: const Icon(Icons.graphic_eq_rounded),
                title: Text(_label(segment.dominantEmotion)),
                subtitle: Text(
                  '${_time(segment.startMs)}–${_time(segment.endMs)} · ${_percent(segment.confidence)}',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _summary(String emotion) {
    final label = _label(emotion);
    return t(
      'النبرة الغالبة في المكالمة: $label. النتيجة تقريبية.',
      'النبرة الغالبة في المكالمة: $label. النتيجة تقديرية.',
      analysis.model?.startsWith('gemini_text_emotion_fallback:') == true
          ? 'Predominantly $label emotional signal in the patient transcript. This fallback is an estimate, not a diagnosis.'
          : 'Predominantly $label vocal tone during this call. This is an estimate, not a diagnosis.',
      analysis.model?.startsWith('gemini_text_emotion_fallback:') == true
          ? 'Signal émotionnel principalement $label dans la transcription du patient. Cette solution de secours est une estimation, pas un diagnostic.'
          : 'Tonalité vocale principalement $label pendant cet appel. Il s’agit d’une estimation, pas d’un diagnostic.',
    );
  }

  static String _percent(double value) => '${(value * 100).round()}%';

  static String _time(int ms) {
    final seconds = (ms / 1000).round();
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  String _label(String value) {
    return switch (value) {
      'angry' => t('غضب', 'غاضب', 'Angry', 'Colère'),
      'disgusted' => t('نفور', 'اشمئزاز', 'Disgusted', 'Dégoût'),
      'fearful' => t('خوف', 'خائف', 'Fearful', 'Peur'),
      'happy' => t('فرح', 'سعيد', 'Happy', 'Joie'),
      'neutral' => t('عادي', 'محايد', 'Neutral', 'Neutre'),
      'other' => t('آخر', 'آخر', 'Other', 'Autre'),
      'sad' => t('حزن', 'حزين', 'Sad', 'Tristesse'),
      'surprised' => t('مفاجأة', 'مندهش', 'Surprised', 'Surprise'),
      _ => t('موش واضح', 'غير مؤكد', 'Uncertain', 'Incertain'),
    };
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.title,
    required this.body,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: HaniColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HaniColors.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(body, style: const TextStyle(height: 1.4)),
                if (loading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
