abstract final class AppConfig {
  static const apiBase = String.fromEnvironment(
    'HANI_API_BASE',
    defaultValue: 'https://hani-maak.vercel.app',
  );

  static const demoCaregiverId =
      '10000000-0000-0000-0000-000000000001';
  static const demoPatientId =
      '30000000-0000-0000-0000-000000000001';
}
