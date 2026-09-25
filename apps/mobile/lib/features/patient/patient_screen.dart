import 'package:flutter/material.dart';

class PatientScreen extends StatelessWidget {
  const PatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: const [
        Text('Fatma', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        SizedBox(height: 4),
        Text('Shared care information'),
        SizedBox(height: 20),
        Card(child: ListTile(title: Text('Today'), subtitle: Text('Medication, routines and responsibilities'), trailing: Icon(Icons.chevron_right))),
        SizedBox(height: 10),
        Card(child: ListTile(title: Text('Timeline'), subtitle: Text('Approved incidents, appointments and instructions'), trailing: Icon(Icons.chevron_right))),
        SizedBox(height: 10),
        Card(child: ListTile(title: Text('Professional instructions'), subtitle: Text('Verified guidance only'), trailing: Icon(Icons.chevron_right))),
      ],
    );
  }
}
