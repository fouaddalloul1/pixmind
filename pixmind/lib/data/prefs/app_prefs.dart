import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  AppPrefs._();
  static final AppPrefs instance = AppPrefs._();

  static const _keyFirstLaunch  = 'first_launch';
  static const _keyGridColumns  = 'grid_columns';
  static const _keyThemeMode    = 'theme_mode'; // 'light' | 'dark' | 'system'

  Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  Future<bool> get isFirstLaunch async =>
      (await _p).getBool(_keyFirstLaunch) ?? true;

  Future<void> markLaunched() async =>
      (await _p).setBool(_keyFirstLaunch, false);

  // ── Grid Columns ──────────────────────────────
  Future<int> get gridColumns async =>
      (await _p).getInt(_keyGridColumns) ?? 3;

  Future<void> setGridColumns(int n) async =>
      (await _p).setInt(_keyGridColumns, n);

  Future<String> get themeMode async =>
      (await _p).getString(_keyThemeMode) ?? 'system';

  Future<void> setThemeMode(String mode) async =>
      (await _p).setString(_keyThemeMode, mode);
}
