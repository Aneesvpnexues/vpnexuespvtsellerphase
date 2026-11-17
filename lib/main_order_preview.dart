import 'package:flutter/material.dart';

import 'screens/order_details_screen.dart';
import 'screens/order_pickup_code_screen.dart';

/// Temporary QA entrypoint: `flutter build web -t lib/main_order_preview.dart`
///
/// Renders both rewritten Order Details screens side by side (Zeplin 135 on
/// the left, Zeplin 141 on the right) at design scale so one headless Chrome
/// screenshot can be compared against the Zeplin PNGs.
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Inter'),
      home: const Row(
        children: [
          SizedBox(width: 412, child: OrderDetailsScreen(order: OrderDetail.sample)),
          SizedBox(width: 412, child: OrderPickupCodeScreen()),
        ],
      ),
    ),
  );
}
