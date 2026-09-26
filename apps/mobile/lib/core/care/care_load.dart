double haniTaskLoadScore(
  Map<String, dynamic> task, {
  DateTime? now,
}) {
  final base = (task['effort_weight'] as num?)?.toDouble() ?? 1;
  final difficulty = task['difficulty']?.toString().toLowerCase();
  final difficultyMultiplier = switch (difficulty) {
    'heavy' => 1.45,
    'moderate' => 1.15,
    'light' => .9,
    _ => 1.0,
  };

  var score = base * difficultyMultiplier;

  if (task['overnight'] == true) {
    score += 1.25;
  }

  final due = DateTime.tryParse(task['due_at']?.toString() ?? '');
  if (due != null) {
    final current = now ?? DateTime.now();
    final remaining = due.difference(current);
    if (remaining.isNegative) {
      score += .75;
    } else if (remaining.inHours <= 24) {
      score += .4;
    }
  }

  return score;
}

String haniLoadBand(double score) {
  if (score >= 6.5) return 'heavy';
  if (score >= 2.5) return 'moderate';
  return 'light';
}
