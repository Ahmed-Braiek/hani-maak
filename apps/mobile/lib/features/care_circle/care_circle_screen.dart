import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CareCircleScreen extends StatelessWidget {
  const CareCircleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: const [
        Text('Care Circle', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text('Coordinate care without keeping score.', style: TextStyle(color: HaniColors.muted)),
        SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: CircleAvatar(child: Text('S')),
            title: Text('Sami'),
            subtitle: Text('Secondary caregiver'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
        SizedBox(height: 12),
        Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tomorrow', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('Evening care looks heavy. Hani can help you ask Sami to cover one responsibility.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
