import 'package:flutter/material.dart';

import 'screens/location_screen.dart';

/// Preview entrypoint: `flutter run -d chrome -t lib/main_location_preview.dart`
///
/// Boots straight into the Zeplin 51 "Choose your location" screen (STEP 01)
/// so the location → confirm (Zeplin 261) → seller-type flow can be reviewed
/// in a browser without the Firebase/Supabase onboarding session.
void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Inter'),
      home: const Step01LocationScreen(),
    ),
  );
}
