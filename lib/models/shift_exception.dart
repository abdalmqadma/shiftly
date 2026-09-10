class ShiftException {
  const ShiftException({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    required this.alarmBeforeMinutes,
  });

  final int id;
  final String title;
  final DateTime start;
  final DateTime end;
  final int alarmBeforeMinutes;

  DateTime get alarmTime => start.subtract(Duration(minutes: alarmBeforeMinutes));

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'alarmBeforeMinutes': alarmBeforeMinutes,
      };

  factory ShiftException.fromJson(Map<String, dynamic> json) => ShiftException(
        id: json['id'] as int,
        title: json['title'] as String,
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
        alarmBeforeMinutes: json['alarmBeforeMinutes'] as int,
      );
}
