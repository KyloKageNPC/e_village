class SavingsAccount {
  final String id;
  final String groupId;
  final String userId;
  final double balance;
  final double totalContributions;
  final double totalWithdrawals;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingsAccount({
    required this.id,
    required this.groupId,
    required this.userId,
    this.balance = 0.0,
    this.totalContributions = 0.0,
    this.totalWithdrawals = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavingsAccount.fromJson(Map<String, dynamic> json) {
    return SavingsAccount(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      totalContributions: (json['total_contributions'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawals: (json['total_withdrawals'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'balance': balance,
      'total_contributions': totalContributions,
      'total_withdrawals': totalWithdrawals,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SavingsAccount copyWith({
    String? id,
    String? groupId,
    String? userId,
    double? balance,
    double? totalContributions,
    double? totalWithdrawals,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsAccount(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalContributions: totalContributions ?? this.totalContributions,
      totalWithdrawals: totalWithdrawals ?? this.totalWithdrawals,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
