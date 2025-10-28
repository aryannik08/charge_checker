import 'package:get_storage/get_storage.dart';

class StorageService {
  static const String _boxName = 'app_storage';
  static const String keyIsDark = 'is_dark';
  static const String keyThemeMode = 'theme_mode';

  final GetStorage _box = GetStorage(_boxName);

  Future<void> writeString(String key, String value) async {
    await _box.write(key, value);
  }

  String? readString(String key) {
    return _box.read<String>(key);
  }


  bool get isDark => _box.read<bool>(keyIsDark) ?? false;

  set isDark(bool value) => _box.write(keyIsDark, value);

  String get themeMode => _box.read<String>(keyThemeMode) ?? 'system';

  set themeMode(String value) => _box.write(keyThemeMode, value);
}
