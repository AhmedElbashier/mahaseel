import 'package:flutter/material.dart';

class MenuHeader extends StatelessWidget {
  final String name;
  final String joinedText;
  final bool verified;

  const MenuHeader({
    super.key,
    required this.name,
    required this.joinedText,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(blurRadius: 10, spreadRadius: -8, offset: Offset(0, 6))],
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 26, backgroundImage: AssetImage('assets/avatar_placeholder.png')),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                  if (verified) const SizedBox(width: 6),
                  if (verified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.verified, size: 14, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('مستخدم موثَّق', style: TextStyle(fontSize: 10, color: Colors.blue)),
                      ]),
                    ),
                ]),
                const SizedBox(height: 4),
                Text(joinedText, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
