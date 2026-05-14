import 'package:flutter/foundation.dart';

enum SettlementPaymentMethod { cash, transfer }

@immutable
class SettlementPaymentInfo {
  const SettlementPaymentInfo({
    required this.method,
    this.verified = false,
    this.amountInSlip,
    this.transactionRef,
    this.slipDate,
    this.bankShortName,
  });

  const SettlementPaymentInfo.cash()
    : this(method: SettlementPaymentMethod.cash);

  const SettlementPaymentInfo.verifiedTransfer({
    required double amountInSlip,
    String? transactionRef,
    DateTime? slipDate,
    String? bankShortName,
  }) : this(
         method: SettlementPaymentMethod.transfer,
         verified: true,
         amountInSlip: amountInSlip,
         transactionRef: transactionRef,
         slipDate: slipDate,
         bankShortName: bankShortName,
       );

  factory SettlementPaymentInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const SettlementPaymentInfo.cash();
    }
    return SettlementPaymentInfo(
      method: json['method'] == 'transfer'
          ? SettlementPaymentMethod.transfer
          : SettlementPaymentMethod.cash,
      verified: json['verified'] as bool? ?? false,
      amountInSlip: (json['amount_in_slip'] as num?)?.toDouble(),
      transactionRef: json['transaction_ref'] as String?,
      slipDate: json['slip_date'] != null
          ? DateTime.tryParse(json['slip_date'] as String)
          : null,
      bankShortName: json['bank'] as String?,
    );
  }

  final SettlementPaymentMethod method;
  final bool verified;
  final double? amountInSlip;
  final String? transactionRef;
  final DateTime? slipDate;
  final String? bankShortName;

  bool get isTransfer => method == SettlementPaymentMethod.transfer;

  Map<String, dynamic> toJson() {
    return {
      'method': method == SettlementPaymentMethod.transfer
          ? 'transfer'
          : 'cash',
      'verified': verified,
      if (amountInSlip != null) 'amount_in_slip': amountInSlip,
      if (transactionRef != null) 'transaction_ref': transactionRef,
      if (slipDate != null) 'slip_date': slipDate!.toIso8601String(),
      if (bankShortName != null) 'bank': bankShortName,
    };
  }
}
