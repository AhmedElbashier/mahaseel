import 'dart:async';
import 'package:flutter/material.dart';

class SearchBarSmall extends StatefulWidget {
  final String? initialText;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onTapFilters;
  const SearchBarSmall({super.key, this.initialText, required this.onSubmitted, required this.onTapFilters});

  @override
  State<SearchBarSmall> createState() => _SearchBarSmallState();
}

class _SearchBarSmallState extends State<SearchBarSmall> {
  late final TextEditingController _c = TextEditingController(text: widget.initialText ?? '');
  Timer? _deb;
  @override
  void dispose() {
    _deb?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _c,
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSubmitted,
              onChanged: (txt) {
                setState(() {});
                _deb?.cancel();
                _deb = Timer(const Duration(milliseconds: 350), () {
                  widget.onSubmitted(txt.trim());
                });
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن المحاصيل أو الأماكن',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: (_c.text.isNotEmpty)
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _deb?.cancel();
                          _c.clear();
                          widget.onSubmitted('');
                          setState(() {});
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Filters',
          icon: const Icon(Icons.tune_rounded),
          onPressed: widget.onTapFilters,
        ),
      ],
    );
  }
}

