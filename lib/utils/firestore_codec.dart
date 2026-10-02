import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

DateTime? readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

Object writeDate({required bool isCreate, DateTime? existing}) {
  if (isCreate || existing == null) return FieldValue.serverTimestamp();
  return Timestamp.fromDate(existing);
}

String dateKey(DateTime date) {
  final DateTime local = DateTime(date.year, date.month, date.day);
  final String month = local.month.toString().padLeft(2, '0');
  final String day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatClock(TimeOfDay time) {
  final String hour = time.hour.toString().padLeft(2, '0');
  final String minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay? parseClock(String? value) {
  if (value == null || !value.contains(':')) return null;
  final List<String> parts = value.split(':');
  final int? hour = int.tryParse(parts[0]);
  final int? minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

int minutesBetween(String start, String end) {
  final TimeOfDay? a = parseClock(start);
  final TimeOfDay? b = parseClock(end);
  if (a == null || b == null) return 0;
  return (b.hour * 60 + b.minute) - (a.hour * 60 + b.minute);
}

String formatMinutes(int minutes) {
  final int safe = minutes < 0 ? 0 : minutes;
  if (safe < 60) return '${safe}m';
  final int hours = safe ~/ 60;
  final int rest = safe % 60;
  if (rest == 0) return '${hours}h';
  return '${hours}h ${rest}m';
}

String formatHoursMinutes(int minutes) {
  final int safe = minutes < 0 ? 0 : minutes;
  final int hours = safe ~/ 60;
  final int rest = safe % 60;
  if (hours == 0) return '$rest min';
  if (rest == 0) return '$hours hrs';
  return '$hours hrs $rest min';
}

String formatRelative(DateTime time) {
  final Duration delta = DateTime.now().difference(time);
  if (delta.inMinutes < 1) return 'just now';
  if (delta.inHours < 1) return '${delta.inMinutes} min ago';
  if (delta.inDays < 1) return '${delta.inHours} hr ago';
  return '${delta.inDays}d ago';
}

String formatCoordinate(double value, {int digits = 6}) {
  if (!value.isFinite) return '—';
  return value.toStringAsFixed(digits);
}

String formatAccuracy(double meters) {
  if (!meters.isFinite || meters <= 0) return '—';
  if (meters < 10) return '±${meters.toStringAsFixed(1)} m';
  return '±${meters.round()} m';
}

String formatRupees(int amount) {
  final bool negative = amount < 0;
  final String digits = amount.abs().toString();
  final StringBuffer grouped = StringBuffer();
  if (digits.length <= 3) {
    grouped.write(digits);
  } else {
    final String lastThree = digits.substring(digits.length - 3);
    String rest = digits.substring(0, digits.length - 3);
    final List<String> parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped
      ..write(parts.join(','))
      ..write(',')
      ..write(lastThree);
  }
  return '${negative ? '-' : ''}₹$grouped';
}

String formatStamp(DateTime time) {
  if (time.year < 2000) return '—';
  final String day = time.day.toString().padLeft(2, '0');
  final String month = time.month.toString().padLeft(2, '0');
  final String hour = time.hour.toString().padLeft(2, '0');
  final String minute = time.minute.toString().padLeft(2, '0');
  return '$day/$month/${time.year}  $hour:$minute';
}
