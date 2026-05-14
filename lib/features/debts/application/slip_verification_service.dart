import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';

import '../domain/settlement_payment_info.dart';

class SlipVerificationException implements Exception {
  const SlipVerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SlipVerificationService {
  SlipVerificationService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  Future<String> readQrPayload(String imagePath) async {
    final scanner = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.qrCode],
    );
    try {
      final capture = await scanner.analyzeImage(imagePath);
      final payload = capture?.barcodes
          .map((barcode) => barcode.rawValue?.trim())
          .whereType<String>()
          .where((value) => value.isNotEmpty)
          .firstOrNull;
      if (payload == null) {
        throw const SlipVerificationException(
          'No QR code found in this receipt.',
        );
      }
      return payload;
    } finally {
      await scanner.dispose();
    }
  }

  Future<SettlementPaymentInfo> verifyBankSlip({
    required String payload,
    required double expectedAmount,
    String? remark,
  }) async {
    final apiKey = dotenv.env['THUNDER_API_KEY']?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw const SlipVerificationException(
        'Slip verification API key is missing.',
      );
    }

    final response = await _client.post(
      Uri.parse('https://api.thunder.in.th/v2/verify/bank'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'payload': payload,
        if (remark != null && remark.trim().isNotEmpty) 'remark': remark.trim(),
        'matchAmount': expectedAmount,
        'checkDuplicate': true,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = body['error'] as Map<String, dynamic>?;
      throw SlipVerificationException(
        error?['message'] as String? ?? 'Slip verification failed.',
      );
    }

    final data = body['data'] as Map<String, dynamic>;
    final rawSlip = data['rawSlip'] as Map<String, dynamic>;
    final isAmountMatched = data['isAmountMatched'] as bool? ?? true;
    if (!isAmountMatched) {
      throw const SlipVerificationException(
        'The transfer amount does not match this settlement.',
      );
    }
    if (data['isDuplicate'] == true) {
      throw const SlipVerificationException(
        'This transfer slip has already been used.',
      );
    }

    final amount = (rawSlip['amount'] as Map<String, dynamic>?)?['amount'];
    final receiver = rawSlip['receiver'] as Map<String, dynamic>?;
    final bank = receiver?['bank'] as Map<String, dynamic>?;
    final date = rawSlip['date'] as String?;

    return SettlementPaymentInfo.verifiedTransfer(
      amountInSlip: (amount as num?)?.toDouble() ?? expectedAmount,
      transactionRef: rawSlip['transRef'] as String?,
      slipDate: date == null ? null : DateTime.tryParse(date),
      bankShortName: bank?['short'] as String?,
    );
  }
}
