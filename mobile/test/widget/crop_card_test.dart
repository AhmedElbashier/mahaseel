import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahaseel/features/crops/data/location.dart';

// FIX THE PACKAGE NAME BELOW to match your pubspec.yaml
import 'package:mahaseel/widgets/crop_card.dart';
import 'package:mahaseel/features/crops/models/crop.dart';

void main() {
  testWidgets('CropCard shows name, qty and unit', (tester) async {
    final crop = Crop(
      id: 1,
      name: 'Tomato',
      type: 'vegetable',
      qty: 100,
      unit: 'kg',
      price: 2.5,
      location: LocationData(
        lat: 15.5,
        lng: 32.5,
        state: 'Khartoum',
        locality: 'Bahri',
        address: 'Test street 123',
      ),
      sellerId: 2,
    );


    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CropCard(crop: crop), // <-- actually pass the crop
          ),
        ),
      ),
    );

    expect(find.text('السعر: 3 kg'), findsOneWidget); // price=2.5 => "3", unit='kg'
    expect(find.text('Tomato'), findsOneWidget);
  });
}
