import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/database/objectbox/objectbox_store.dart';


final objectBoxProvider = Provider<ObjectBoxStore>((ref) {
  throw UnimplementedError('Override in main()');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  final obStore = await ObjectBoxStore.create();

  runApp(
      ProviderScope(
          overrides: [
            objectBoxProvider.overrideWithValue(obStore),
          ],
      child: PixMindApp()));
}