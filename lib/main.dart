import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/elite_app.dart';
import 'firebase_options.dart';
import 'services/ads_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? firebaseError;

  await AdsService.initialize();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    firebaseError = error;
  }

  runApp(EliteApp(firebaseError: firebaseError));
}
