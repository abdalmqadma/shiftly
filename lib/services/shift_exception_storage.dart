import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shift_exception.dart';

class ShiftExceptionStorage {
  const ShiftExceptionStorage._();

  static const _key = 'shift_exceptions_v1';

  static Future<List<ShiftException>> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final source = preferences.getString(_key);
      if (source == null) return const [];
      final decoded = jsonDecode(source) as List<dynamic>;
      final items = decoded
          .map((item) =>
              ShiftException.fromJson(item as Map<String, dynamic>))
          .toList();
      items.sort((a, b) => a.start.compareTo(b.start));
      return items;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> save(List<ShiftException> exceptions) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(exceptions.map((item) => item.toJson()).toList()),
    );
  }
}
