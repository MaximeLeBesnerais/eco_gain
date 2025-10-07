import 'package:shared_preferences/shared_preferences.dart';

class CurrencyHelper {
  static Future<String> getCurrencySymbol() async {
    final prefs = await SharedPreferences.getInstance();
    final useCustom = prefs.getBool('use_custom_currency') ?? false;
    if (useCustom) {
      final custom = prefs.getString('custom_currency') ?? '';
      if (custom.isNotEmpty) return custom;
    }
    return prefs.getString('selected_currency') ?? '\$';
  }

  static Future<void> saveCurrencySymbol(String symbol, bool isCustom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_custom_currency', isCustom);
    if (isCustom) {
      await prefs.setString('custom_currency', symbol);
    } else {
      await prefs.setString('selected_currency', symbol);
    }
  }
}
