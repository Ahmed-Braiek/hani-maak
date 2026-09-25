import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class WellbeingScreen extends StatelessWidget {
  const WellbeingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: const [
        Text('Me', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text('Your space. Private by default.', style: TextStyle(color: HaniColors.muted)),
        SizedBox(height: 20),
        Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How are you holding up?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('I’m okay')),
                    Chip(label: Text('Tired')),
                    Chip(label: Text('Overwhelmed')),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12),
        Card(
          child: ListTile(
            title: Text('Your recent pattern'),
            subtitle: Text('The last few days seem heavier than usual.'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      ],
    );
  }
}
