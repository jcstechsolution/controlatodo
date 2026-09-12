import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Los valores de conexión de Firebase se toman de los archivos nativos
  // (android/app/google-services.json e ios/Runner/GoogleService-Info.plist),
  // generados desde la consola de Firebase. Ver README.md, sección Firebase.
  await Firebase.initializeApp();

  await initializeDateFormatting('es_ES');
  await NotificationService.instance.init();

  runApp(const ControlaTodoApp());
}
