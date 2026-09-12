# ControlaTodo

**Organiza tus pagos. Nunca olvides un vencimiento.**

MVP funcional de ControlaTodo construido con Flutter + Firebase: control de
pagos, facturas, suscripciones, vencimientos, renovaciones, mantenimientos y
recordatorios recurrentes.

## 1. Stack técnico

- Flutter (canal stable) / Dart >= 3.3
- Firebase: Authentication, Cloud Firestore, Cloud Messaging (preparado), Storage (preparado)
- Gestión de estado: `provider`
- Navegación: `go_router`
- Notificaciones locales: `flutter_local_notifications` + `timezone`
- Gráficos: `fl_chart`
- Calendario: `table_calendar`

## 2. Estructura del proyecto

```
lib/
  main.dart
  app/
    app.dart          -> MultiProvider + MaterialApp.router
    routes.dart        -> GoRouter y redirección por sesión
    theme.dart          -> Tema claro / oscuro Material 3
  core/
    constants/          -> Colores, categorías, enums, límites de plan
    utils/               -> Formateo de moneda/fecha, validaciones, reglas de negocio
    services/            -> NotificationService (notificaciones locales)
    widgets/             -> Widgets reutilizables (botones, tarjetas, estados)
  models/                -> Payment, PaymentHistoryEntry, UserModel, AppSettingsModel
  repositories/           -> Acceso a FirebaseAuth / Firestore
  providers/              -> AuthProvider, PaymentProvider, SettingsProvider
  features/
    auth/                 -> splash, welcome, login, register, forgot password
    home/                 -> HomeShell (navegación inferior)
    dashboard/             -> Resumen mensual y próximos vencimientos
    payments/               -> Lista, formulario y detalle de pagos
    calendar/               -> Calendario de vencimientos
    statistics/              -> Totales, gráficos por categoría, "Tu análisis"
    profile/                 -> Mi cuenta, configuración, datos demo
    premium/                 -> Pantalla ControlaTodo Premium
firestore.rules
```

Cada `payment` en Firestore sigue este modelo (`users/{uid}/payments/{id}`):

```
id, name, category, amount, currency, dueDate, isRecurring, frequency,
reminderDays, status, notes, createdAt, updatedAt, isDemo
```

Y su historial en `users/{uid}/payments/{id}/history/{historyId}`:

```
amount, currency, paidAt, status
```

La configuración del usuario vive en `users/{uid}/settings/config`
(`currency`, `notificationsEnabled`, `themeMode`), y el plan (`free` /
`premium`) en el propio documento `users/{uid}`.

## 3. Dependencias (pubspec.yaml)

Ya incluidas en este proyecto. Resumen:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_messaging: ^15.1.3
  provider: ^6.1.2
  go_router: ^14.2.7
  intl: ^0.19.0
  table_calendar: ^3.1.2
  fl_chart: ^0.69.0
  flutter_local_notifications: ^17.2.3
  timezone: ^0.9.4
  uuid: ^4.5.1
  shared_preferences: ^2.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

Instalar dependencias:

```bash
flutter pub get
```

`flutter pub get` resolverá automáticamente la versión estable más reciente
compatible con cada restricción `^`. Si en tu máquina existe una versión de
Flutter/Dart antigua, ejecuta `flutter upgrade` antes de continuar.

## 4. Crear el proyecto Flutter y colocar este código

Este repositorio contiene el código de `lib/`, `pubspec.yaml`,
`analysis_options.yaml` y `firestore.rules`, pero **no** las carpetas
`android/` e `ios/` generadas por herramientas (son cientos de archivos de
plantilla específicos de tu versión exacta de Flutter/Gradle/Xcode). Para
generarlas:

```bash
flutter create --org com.tuempresa --project-name controlatodo .
```

Ejecuta este comando **en la carpeta raíz de este proyecto** (donde está
`pubspec.yaml`). Flutter creará `android/`, `ios/`, `web/`, etc. sin tocar tu
carpeta `lib/` ni tu `pubspec.yaml` existentes (si te pregunta por
sobrescribir `pubspec.yaml`, `analysis_options.yaml` o `lib/main.dart`,
responde que no).

## 5. Configuración de Firebase

**No inventes ni copies `google-services.json` de un ejemplo**: ese archivo
lo genera la propia consola de Firebase con las credenciales reales de tu
proyecto y debe descargarse desde ahí.

1. Ve a [https://console.firebase.google.com](https://console.firebase.google.com) y crea un proyecto (por ejemplo, "ControlaTodo").
2. Dentro del proyecto, agrega una app **Android**:
   - Nombre del paquete: el mismo `applicationId` que uses en `android/app/build.gradle` (por ejemplo `com.tuempresa.controlatodo`).
   - Descarga el archivo **`google-services.json`** y colócalo en `android/app/google-services.json`.
3. (Cuando prepares iOS) agrega una app **iOS** con el mismo Bundle ID, descarga **`GoogleService-Info.plist`** y colócalo en `ios/Runner/GoogleService-Info.plist` con Xcode (arrastrándolo al proyecto, marcando "Copy items if needed").
4. En **Authentication → Sign-in method**, habilita **Correo electrónico/contraseña**.
5. En **Firestore Database**, crea la base de datos (modo producción) y publica el contenido de `firestore.rules` (Firestore → Reglas → pega el contenido del archivo → Publicar).
6. (Opcional, para más adelante) En **Cloud Messaging** no se requiere configuración adicional para dejar la arquitectura preparada; cuando actives push reales, solo necesitarás agregar el manejo de `firebase_messaging` en `main.dart` sobre la base ya existente en `NotificationService`.

### Configuración de Android (build.gradle)

En `android/settings.gradle` (o `android/build.gradle` según la plantilla de tu versión de Flutter) agrega el plugin de Google Services:

```gradle
plugins {
    // ...plugins existentes de Flutter...
    id "com.google.gms.google-services" version "4.4.2" apply false
}
```

En `android/app/build.gradle`:

```gradle
plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"
}

android {
    namespace = "com.tuempresa.controlatodo"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.tuempresa.controlatodo"
        minSdk = 23
        targetSdk = 34
        versionCode = flutterVersionCode.toInteger()
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
        coreLibraryDesugaringEnabled true
    }
}

dependencies {
    coreLibraryDesugaringEnabled true
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
}
```

`minSdk = 23` es obligatorio porque las versiones actuales de Firebase Auth
lo requieren. `coreLibraryDesugaringEnabled` es obligatorio para que
`flutter_local_notifications` compile correctamente.

### Permisos (android/app/src/main/AndroidManifest.xml)

Agrega estos permisos dentro de `<manifest>` (antes de `<application>`):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

## 6. Cómo ejecutar el proyecto

```bash
flutter pub get
flutter devices          # ver el emulador/dispositivo disponible
flutter run
```

Con la app corriendo:

1. Toca **"Comenzar"** → **Crear cuenta** (nombre, correo, contraseña).
2. Inicia sesión.
3. En **Mi cuenta → Cargar datos de prueba** para ver el Dashboard, Calendario y Estadísticas con datos de ejemplo (Internet, Electricidad, Netflix, Spotify, Seguro del vehículo, Cambio de aceite).

## 7. Cómo probarlo

```bash
flutter analyze     # análisis estático
flutter test         # pruebas unitarias/widget (agrega tus propios tests en test/)
```

Prueba manual sugerida: registro, cierre e inicio de sesión, agregar un pago
no recurrente y uno recurrente, marcarlo como pagado (verifica que se cree
el historial y, si es recurrente, que la fecha avance), editar, eliminar,
filtrar/ordenar en "Mis pagos", ver el día correspondiente en "Calendario" y
confirmar que "Estadísticas" refleje los totales.

## 8. Generar APK (Android)

```bash
flutter build apk --release
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk`.

## 9. Generar AAB para Google Play

```bash
flutter build appbundle --release
```

El archivo queda en `build/app/outputs/bundle/release/app-release.aab`.

Antes de publicar en Google Play, configura la firma de la app (keystore)
en `android/key.properties` y `android/app/build.gradle` según la [guía
oficial de Flutter para firmar la app](https://docs.flutter.dev/deployment/android).

## 10. Planes y monetización

La estructura de planes ya está lista (`lib/core/constants/plan_limits.dart`,
`UserModel.plan`, límite de 10 pagos en `PaymentProvider.canAddMore`) y la
pantalla `ControlaTodo Premium` muestra los precios sugeridos ($2.99/mes,
$29.99/año). El botón "Actualizar a Premium" todavía **no** cobra nada real:
solo muestra un aviso de "próximamente", tal como se pidió, para integrar
después Google Play Billing / Apple In-App Purchases sin rediseñar la app.

## 11. Preparado para el futuro (no implementado todavía)

- **IA "Analizar mis gastos"**: la pantalla de Estadísticas ya calcula y
  muestra insights reales (recurrentes, gasto del mes, categoría con mayor
  gasto) con lógica local; conectar un modelo de IA solo requiere reemplazar
  esa sección por una llamada a un servicio externo.
- **OCR de facturas**: el botón "Escanear factura" en el Dashboard ya existe
  y muestra "Función Premium próximamente"; conectar OCR real implica
  reemplazar ese `onPressed` por la captura de cámara + servicio de OCR.
- **Firebase Cloud Messaging**: `NotificationService` ya centraliza cómo se
  muestran las notificaciones; un mensaje push entrante solo necesita llamar
  a los mismos métodos.

## 12. Notas de seguridad

- `firestore.rules` deniega todo acceso por defecto y solo permite a un
  usuario leer/escribir dentro de `users/{su propio uid}` y sus
  subcolecciones. Publica este archivo en Firebase antes de usar la app con
  datos reales.
- Los mensajes de error mostrados al usuario son siempre genéricos y
  amigables (`AppException`); nunca se exponen stack traces ni códigos
  técnicos de Firebase.
