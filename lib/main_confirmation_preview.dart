import 'package:flutter/material.dart';
import 'screens/order_confirmation_screen.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Inter'),
      home: const OrderConfirmationScreen(),
    ),
  );
}