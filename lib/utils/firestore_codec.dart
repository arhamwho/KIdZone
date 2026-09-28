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
  return (b.hour * 60 + b.minute) - (a.hour * 60 + a.minute);
}
