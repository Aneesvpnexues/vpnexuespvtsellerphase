import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/welcome_seller_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  runApp(const SellerApp());
}

class SellerApp extends StatelessWidget {
  const SellerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Seller App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Inter'),
      home: const WelcomeSellerScreen(),
    );
  }
}
