import 'package:flutter/material.dart';
import '../../crops/data/crops_repo.dart';
import '../data/crop_filters.dart';

class CropFilterSheet extends StatefulWidget {
  final CropFilters initial;
  const CropFilterSheet({super.key, required this.initial});

  @override
  State<CropFilterSheet> createState() => _CropFilterSheetState();
}

class _CropFilterSheetState extends State<CropFilterSheet> {
  late String? _type = widget.initial.type;
  late String? _state = widget.initial.state;
  late double _min = widget.initial.minPrice ?? 0;
  late double _max = widget.initial.maxPrice ?? 1000;
  late SortOption _sort = widget.initial.sort;

  // For now, static lists. Later you can fetch from backend if you want.
  final _types = const ['grain', 'vegetable', 'fruit'];
  final _states = const ['Khartoum', 'Gezira', 'Sennar', 'Kassala'];

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16,
        top: 16,
        bottom: mq.viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Type
            DropdownButtonFormField<String>(
              value: _type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any')),
                ..._types.map((t) => DropdownMenuItem(value: t, child: Text(t))),
              ],
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 12),

            // State
            DropdownButtonFormField<String>(
              value: _state,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'State', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Any')),
                ..._states.map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (v) => setState(() => _state = v),
            ),
            const SizedBox(height: 12),

            // Price range (RangeSlider)
            const Text('Price range (SDG or your unit)'),
            RangeSlider(
              values: RangeValues(_min, _max),
              min: 0,
              max: 10000, // adjust to your market range
              divisions: 100,
              labels: RangeLabels(_min.toStringAsFixed(0), _max.toStringAsFixed(0)),
              onChanged: (v) => setState(() {
                _min = v.start;
                _max = v.end;
              }),
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Min', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    initialValue: _min.toStringAsFixed(0),
                    onChanged: (v) => _min = double.tryParse(v) ?? _min,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Max', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    initialValue: _max.toStringAsFixed(0),
                    onChanged: (v) => _max = double.tryParse(v) ?? _max,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sort
            const Text('Sort by'),
            RadioListTile<SortOption>(
              title: const Text('Newest'),
              value: SortOption.newest,
              groupValue: _sort,
              onChanged: (v) => setState(() => _sort = v!),
            ),
            RadioListTile<SortOption>(
              title: const Text('Price (Low → High)'),
              value: SortOption.priceAsc,
              groupValue: _sort,
              onChanged: (v) => setState(() => _sort = v!),
            ),
            RadioListTile<SortOption>(
              title: const Text('Price (High → Low)'),
              value: SortOption.priceDesc,
              groupValue: _sort,
              onChanged: (v) => setState(() => _sort = v!),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _type = null;
                      _state = null;
                      _min = 0;
                      _max = 1000;
                      _sort = SortOption.newest;
                    });
                  },
                  child: const Text('Reset'),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Apply'),
                  onPressed: () {
                    final result = CropFilters(
                      type: _type,
                      state: _state,
                      minPrice: _min,
                      maxPrice: _max,
                      sort: _sort,
                    );
                    Navigator.of(context).pop(result);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
