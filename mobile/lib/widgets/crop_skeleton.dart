import 'package:flutter/material.dart';

class CropSkeleton extends StatelessWidget {
  const CropSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    Widget bar({double h = 12, double w = 120}) => Container(
      height: h, width: w,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Card(
      elevation: 0.5,
      child: Row(
        children: [
          Container(width: 110, height: 100, color: Colors.grey.shade200),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(h: 14, w: 180),
                  const SizedBox(height: 8),
                  bar(w: 140),
                  const SizedBox(height: 6),
                  bar(w: 100),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
