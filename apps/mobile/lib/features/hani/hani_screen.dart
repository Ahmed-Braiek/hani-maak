import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HaniScreen extends StatefulWidget {
  const HaniScreen({super.key});

  @override
  State<HaniScreen> createState() => _HaniScreenState();
}

class _HaniScreenState extends State<HaniScreen> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hani', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('Here with you · private', style: TextStyle(fontSize: 12, color: HaniColors.muted)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                _HaniBubble(
                  text: 'Mariem, I’m here. What’s happening with Fatma right now?',
                ),
                SizedBox(height: 12),
                _ContextChip(),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type or speak naturally…',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(17),
                    ),
                    onPressed: () {},
                    child: const Icon(Icons.mic_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HaniBubble extends StatelessWidget {
  const _HaniBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EEEC)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, height: 1.45)),
      ),
    );
  }
}

class _ContextChip extends StatelessWidget {
  const _ContextChip();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: Icon(Icons.lock_outline, size: 17),
        label: Text('Hani remembers Fatma’s care context'),
      ),
    );
  }
}
