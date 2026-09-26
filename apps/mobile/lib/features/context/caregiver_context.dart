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
    required this.timeline,
    required this.appointments,
    required this.medicationSchedules,
    required this.medicationEvents,
    required this.careDocuments,
    required this.memoryItems,
    required this.activitySessions,
    required this.summaryDeliveries,
    required this.supportSignals,
    required this.taskRequests,
    required this.patterns,
    required this.followUp,
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
  final List<Map<String, dynamic>> timeline;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> medicationSchedules;
  final List<Map<String, dynamic>> medicationEvents;
  final List<Map<String, dynamic>> careDocuments;
  final List<Map<String, dynamic>> memoryItems;
  final List<Map<String, dynamic>> activitySessions;
  final List<Map<String, dynamic>> summaryDeliveries;
  final List<Map<String, dynamic>> supportSignals;
  final List<Map<String, dynamic>> taskRequests;
  final List<Map<String, dynamic>> patterns;
  final Map<String, dynamic>? followUp;

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
      timeline: maps(json['timeline']),
      appointments: maps(json['appointments']),
      medicationSchedules: maps(json['medicationSchedules']),
      medicationEvents: maps(json['medicationEvents']),
      careDocuments: maps(json['careDocuments']),
      memoryItems: maps(json['memoryItems']),
      activitySessions: maps(json['activitySessions']),
      summaryDeliveries: maps(json['summaryDeliveries']),
      supportSignals: maps(json['supportSignals']),
      taskRequests: maps(json['taskRequests']),
      patterns: maps(json['patterns']),
      followUp: json['followUp'] is Map
          ? Map<String, dynamic>.from(json['followUp'] as Map)
          : null,
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

  List<Map<String, dynamic>> get incomingTaskRequests {
    final id = caregiver['id']?.toString();
    return taskRequests
        .where((item) =>
            item['recipient_profile_id']?.toString() == id &&
            item['status'] == 'pending')
        .toList();
  }

  List<Map<String, dynamic>> get outgoingTaskRequests {
    final id = caregiver['id']?.toString();
    return taskRequests
        .where((item) => item['requester_profile_id']?.toString() == id)
        .toList();
  }
}
