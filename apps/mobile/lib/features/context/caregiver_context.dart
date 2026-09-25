class CaregiverContext {
  const CaregiverContext({
    required this.caregiver,
    required this.patient,
    required this.relationship,
    required this.medications,
    required this.instructions,
    required this.incidents,
    required this.tasks,
    required this.wellbeing,
    required this.careCircle,
    required this.professionals,
    required this.notifications,
    required this.notificationPreferences,
    required this.questionnaires,
  });

  final Map<String, dynamic> caregiver;
  final Map<String, dynamic> patient;
  final Map<String, dynamic> relationship;
  final List<Map<String, dynamic>> medications;
  final List<Map<String, dynamic>> instructions;
  final List<Map<String, dynamic>> incidents;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> wellbeing;
  final Map<String, dynamic>? careCircle;
  final List<Map<String, dynamic>> professionals;
  final List<Map<String, dynamic>> notifications;
  final Map<String, dynamic> notificationPreferences;
  final List<Map<String, dynamic>> questionnaires;

  factory CaregiverContext.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> maps(dynamic value) => (value as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    Map<String, dynamic> map(dynamic value) =>
        value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

    return CaregiverContext(
      caregiver: map(json['caregiver']),
      patient: map(json['patient']),
      relationship: map(json['relationship']),
      medications: maps(json['medications']),
      instructions: maps(json['professionalInstructions']),
      incidents: maps(json['recentIncidents']),
      tasks: maps(json['careTasks']),
      wellbeing: maps(json['privateWellbeing']),
      careCircle: json['careCircle'] is Map
          ? Map<String, dynamic>.from(json['careCircle'] as Map)
          : null,
      professionals: maps(json['professionalRoutes']),
      notifications: maps(json['notifications']),
      notificationPreferences: map(json['notificationPreferences']),
      questionnaires: maps(json['questionnaires']),
    );
  }

  String get caregiverName =>
      caregiver['full_name']?.toString().trim().isNotEmpty == true
          ? caregiver['full_name'].toString()
          : 'Caregiver';

  String get patientName =>
      patient['preferred_name']?.toString().trim().isNotEmpty == true
          ? patient['preferred_name'].toString()
          : patient['display_name']?.toString() ?? 'Patient';

  String get stage => patient['alzheimer_stage']?.toString() ?? 'Not specified';

  List<Map<String, dynamic>> get privateIncidents => incidents
      .where((item) => item['visibility'] == 'private_draft')
      .toList();

  List<Map<String, dynamic>> get sharedIncidents => incidents
      .where((item) => item['visibility'] == 'shared_care_timeline')
      .toList();

  List<Map<String, dynamic>> get openTasks => tasks
      .where((item) => !{'completed', 'cancelled'}.contains(item['status']))
      .toList();

  List<Map<String, dynamic>> get careCircleMembers {
    final raw = careCircle?['members'];
    return (raw as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
