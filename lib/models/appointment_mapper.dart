// lib/models/appointment_mapper.dart
import 'package:flutter/foundation.dart';
import 'appointment.dart';
import 'doctor.dart';
import 'package:vietqr_core/vietqr_core.dart';
// ...existing code...

/// Ánh xạ JSON từ backend (Appointments table) sang model FE `Appointment`.
Appointment mapAppointmentFromBackend(Map<String, dynamic> j) {
  debugPrint('[APPT][RAW] $j');
  // Parse doctor từ dữ liệu backend
  final doctorBankStr = j['doctorBank']?.toString() ?? '';
  final doctorBank = SupportedBank.values.firstWhere(
    (b) => b.name == doctorBankStr,
    orElse: () => SupportedBank.vietcombank,
  );
  // Lấy số tài khoản từ doctorBankAccount hoặc bankAccount (ưu tiên trường nào có giá trị)
  String accRaw = (j['doctorBankAccount'] ?? '').toString();
  if (accRaw.isEmpty && j['bankAccount'] != null) accRaw = j['bankAccount'].toString();
  String rawAccount = accRaw.replaceAll(RegExp(r'[^0-9]'), '').trim();
  if (rawAccount.length > 19) {
    rawAccount = rawAccount.substring(0, 19);
  }
  debugPrint('[BANK_ACCOUNT] doctorBankAccount: $rawAccount');

  // Safe int parsing for amount/fee
  int parseInt(dynamic value, [int fallback = 0]) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? fallback;
    }
    return fallback;
  }

  final doctorFee = parseInt(j['doctorFee'], 0);
  final amount = parseInt(j['amount'], doctorFee);

  final doctor = Doctor(
    id: '${j['doctorId']}',
    name: j['doctorName'] ?? 'Bác sĩ',
    specialty: j['doctorSpecialty'] ?? 'N/A',
    fee: doctorFee,
    bank: doctorBank,
    account: rawAccount,
    city: j['doctorCity'] ?? '',
  );

  // Parse time
  DateTime time;
  final rawTime = j['appointmentTime'];
  debugPrint('[APPT] rawTime from backend: $rawTime');
  if (rawTime == null) {
    debugPrint('[APPT] appointmentTime is null, fallback to DateTime.now()');
    time = DateTime.now();
  } else {
    try {
      time = DateTime.parse(rawTime.toString()).toLocal(); // BE trả UTC
      debugPrint('[APPT] Parsed appointmentTime: $time');
    } catch (e) {
      debugPrint('[APPT] Parse error: $e, fallback to DateTime.now()');
      time = DateTime.now();
    }
  }

  // Đảm bảo id luôn là số nguyên, không phải string rỗng/null
  int safeId;
  final rawId = j['id'];
  if (rawId == null) {
    safeId = -1;
  } else if (rawId is int) {
    safeId = rawId;
  } else if (rawId is String) {
    safeId = int.tryParse(rawId) ?? -1;
  } else {
    safeId = -1;
  }

  // Validate status and paymentStatus
  final validStatuses = ['PENDING', 'CANCELLED', 'COMPLETED', 'CONFIRMED', 'REJECTED', 'NO_SHOW'];
  final rawStatus = j['a_status'] ?? j['status'];
  final status = validStatuses.contains(rawStatus) ? rawStatus : 'PENDING';
  final paymentStatus = (j['paymentStatus'] ?? j['a_paymentStatus'] ?? 'UNPAID') as String;

  // Debug log for mapped data
  debugPrint('[APPT][MAPPED] id: $safeId, status: $status, paymentStatus: $paymentStatus');

  return Appointment(
    id: safeId.toString(), // FE dùng String id, nhưng luôn là số nguyên
    doctor: doctor,
    time: time,
    patientNote: (j['note'] ?? '') as String,
    amount: amount,
    status: status,
    paymentStatus: paymentStatus,
    paymentRef: j['paymentRef']?.toString(),
  );
}
