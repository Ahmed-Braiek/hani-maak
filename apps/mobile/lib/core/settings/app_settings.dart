import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HaniLanguage { tounsi, english, french }

extension HaniLanguageX on HaniLanguage {
  String get code => switch (this) {
        HaniLanguage.tounsi => 'ar',
        HaniLanguage.english => 'en',
        HaniLanguage.french => 'fr',
      };

  String get label => switch (this) {
        HaniLanguage.tounsi => 'تونسي',
        HaniLanguage.english => 'English',
        HaniLanguage.french => 'Français',
      };
}

class AppSettings {
  const AppSettings({
    this.language = HaniLanguage.tounsi,
    this.notificationsEnabled = true,
    this.incidentFollowups = true,
    this.wellbeingReminders = true,
    this.careCircleRequests = true,
    this.appointments = true,
    this.quietHours = true,
    this.showHaniWidget = true,
    this.showPatientWidget = true,
    this.showCareLoadWidget = true,
    this.showWellbeingWidget = true,
  });

  final HaniLanguage language;
  final bool notificationsEnabled;
  final bool incidentFollowups;
  final bool wellbeingReminders;
  final bool careCircleRequests;
  final bool appointments;
  final bool quietHours;
  final bool showHaniWidget;
  final bool showPatientWidget;
  final bool showCareLoadWidget;
  final bool showWellbeingWidget;

  AppSettings copyWith({
    HaniLanguage? language,
    bool? notificationsEnabled,
    bool? incidentFollowups,
    bool? wellbeingReminders,
    bool? careCircleRequests,
    bool? appointments,
    bool? quietHours,
    bool? showHaniWidget,
    bool? showPatientWidget,
    bool? showCareLoadWidget,
    bool? showWellbeingWidget,
  }) {
    return AppSettings(
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      incidentFollowups: incidentFollowups ?? this.incidentFollowups,
      wellbeingReminders: wellbeingReminders ?? this.wellbeingReminders,
      careCircleRequests: careCircleRequests ?? this.careCircleRequests,
      appointments: appointments ?? this.appointments,
      quietHours: quietHours ?? this.quietHours,
      showHaniWidget: showHaniWidget ?? this.showHaniWidget,
      showPatientWidget: showPatientWidget ?? this.showPatientWidget,
      showCareLoadWidget: showCareLoadWidget ?? this.showCareLoadWidget,
      showWellbeingWidget: showWellbeingWidget ?? this.showWellbeingWidget,
    );
  }
}

class AppSettingsController extends StateNotifier<AppSettings> {
  AppSettingsController() : super(const AppSettings());

  void setLanguage(HaniLanguage language) =>
      state = state.copyWith(language: language);

  void setNotifications(bool value) =>
      state = state.copyWith(notificationsEnabled: value);

  void setIncidentFollowups(bool value) =>
      state = state.copyWith(incidentFollowups: value);

  void setWellbeingReminders(bool value) =>
      state = state.copyWith(wellbeingReminders: value);

  void setCareCircleRequests(bool value) =>
      state = state.copyWith(careCircleRequests: value);

  void setAppointments(bool value) =>
      state = state.copyWith(appointments: value);

  void setQuietHours(bool value) =>
      state = state.copyWith(quietHours: value);

  void setHaniWidget(bool value) =>
      state = state.copyWith(showHaniWidget: value);

  void setPatientWidget(bool value) =>
      state = state.copyWith(showPatientWidget: value);

  void setCareLoadWidget(bool value) =>
      state = state.copyWith(showCareLoadWidget: value);

  void setWellbeingWidget(bool value) =>
      state = state.copyWith(showWellbeingWidget: value);
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsController, AppSettings>(
  (ref) => AppSettingsController(),
);

class AppCopy {
  AppCopy(this.language);
  final HaniLanguage language;

  String t(String key) {
    final values = _copy[key];
    if (values == null) return key;
    return values[language] ?? values[HaniLanguage.english] ?? key;
  }

  static final Map<String, Map<HaniLanguage, String>> _copy = {
    'today': {
      HaniLanguage.tounsi: 'اليوم',
      HaniLanguage.english: 'Today',
      HaniLanguage.french: 'Aujourd’hui',
    },
    'patient': {
      HaniLanguage.tounsi: 'المريض',
      HaniLanguage.english: 'Patient',
      HaniLanguage.french: 'Patient',
    },
    'circle': {
      HaniLanguage.tounsi: 'دائرة العائلة',
      HaniLanguage.english: 'Care Circle',
      HaniLanguage.french: 'Cercle de soins',
    },
    'me': {
      HaniLanguage.tounsi: 'أنا',
      HaniLanguage.english: 'Me',
      HaniLanguage.french: 'Moi',
    },
    'hani': {
      HaniLanguage.tounsi: 'هاني',
      HaniLanguage.english: 'Hani',
      HaniLanguage.french: 'Hani',
    },
    'notifications': {
      HaniLanguage.tounsi: 'الإشعارات',
      HaniLanguage.english: 'Notifications',
      HaniLanguage.french: 'Notifications',
    },
    'settings': {
      HaniLanguage.tounsi: 'الإعدادات',
      HaniLanguage.english: 'Settings',
      HaniLanguage.french: 'Paramètres',
    },
    'widgets': {
      HaniLanguage.tounsi: 'واجهة اليوم',
      HaniLanguage.english: 'Today widgets',
      HaniLanguage.french: 'Widgets du jour',
    },
    'language': {
      HaniLanguage.tounsi: 'اللغة',
      HaniLanguage.english: 'Language',
      HaniLanguage.french: 'Langue',
    },
    'private': {
      HaniLanguage.tounsi: 'خاص بيك',
      HaniLanguage.english: 'Private by default',
      HaniLanguage.french: 'Privé par défaut',
    },
    'talkHani': {
      HaniLanguage.tounsi: 'احكي مع هاني',
      HaniLanguage.english: 'Talk to Hani',
      HaniLanguage.french: 'Parler à Hani',
    },
    'liveVoice': {
      HaniLanguage.tounsi: 'مكالمة مباشرة',
      HaniLanguage.english: 'Live voice',
      HaniLanguage.french: 'Voix en direct',
    },
    'retry': {
      HaniLanguage.tounsi: 'عاود جرّب',
      HaniLanguage.english: 'Retry',
      HaniLanguage.french: 'Réessayer',
    },
    'professionalSupport': {
      HaniLanguage.tounsi: 'مساعدة مختص',
      HaniLanguage.english: 'Professional support',
      HaniLanguage.french: 'Aide professionnelle',
    },
    'signIn': {
      HaniLanguage.tounsi: 'ادخل لحسابك',
      HaniLanguage.english: 'Sign in',
      HaniLanguage.french: 'Se connecter',
    },
    'startDemo': {
      HaniLanguage.tounsi: 'جرّب النسخة التجريبية',
      HaniLanguage.english: 'Explore caregiver demo',
      HaniLanguage.french: 'Explorer la démo aidant',
    },
    'welcomeTitle': {
      HaniLanguage.tounsi: 'الرعاية صعيبة. هاني معاك.',
      HaniLanguage.english: 'Care is hard. Hani is with you.',
      HaniLanguage.french: 'Prendre soin est difficile. Hani est avec vous.',
    },
    'welcomeBody': {
      HaniLanguage.tounsi: 'مساعد ذكي للمرافقين: يفهم السياق، يسمعلك، وينظّم معاك الرعاية خطوة بخطوة.',
      HaniLanguage.english: 'A context-aware companion for caregivers — support in the moment, coordination when it matters.',
      HaniLanguage.french: 'Un compagnon contextuel pour les aidants — soutien immédiat et coordination quand il le faut.',
    },
  };
}
