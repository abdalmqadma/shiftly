import 'package:flutter/services.dart';

class RingtoneChoice {
  const RingtoneChoice({required this.name, this.path});
  final String name;
  final String? path;

  static const systemDefault =
      RingtoneChoice(name: 'نغمة المنبّه الافتراضية');
}

class RingtoneService {
  const RingtoneService._();
  static const _channel =
      MethodChannel('com.abdalmqadma.shiftly/ringtone');

  static Future<RingtoneChoice?> pickSystemRingtone() async {
    final value =
        await _channel.invokeMapMethod<String, String>('pickSystemRingtone');
    if (value == null || value['path'] == null) return null;
    return RingtoneChoice(
      name: value['name'] ?? 'نغمة من الهاتف',
      path: value['path'],
    );
  }

  static Future<RingtoneChoice?> pickMediaTone() async {
    final value =
        await _channel.invokeMapMethod<String, String>('pickMediaTone');
    if (value == null || value['path'] == null) return null;
    return RingtoneChoice(
      name: value['name'] ?? 'نغمة مخصصة',
      path: value['path'],
    );
  }
}
