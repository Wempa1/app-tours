import 'package:flutter/foundation.dart';

@immutable
class PaymentMethod {
  final String id; // uuid
  final String brand; // ej: 'Visa', 'MasterCard'
  final String last4; // '4242'
  final int expMonth; // 1..12
  final int expYear;  // ej: 2030
  final bool isDefault;
  final String? label; // alias opcional (ej: "Tarjeta personal")
  final DateTime? createdAt;

  const PaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
    this.label,
    this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> j) => PaymentMethod(
        id: j['id'] as String,
        brand: j['brand'] as String? ?? 'Card',
        last4: j['last4'] as String? ?? '',
        expMonth: (j['exp_month'] as num?)?.toInt() ?? 1,
        expYear: (j['exp_year'] as num?)?.toInt() ?? 2030,
        isDefault: (j['is_default'] as bool?) ?? false,
        label: j['label'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'last4': last4,
        'exp_month': expMonth,
        'exp_year': expYear,
        'is_default': isDefault,
        'label': label,
        'created_at': createdAt?.toIso8601String(),
      };
}
