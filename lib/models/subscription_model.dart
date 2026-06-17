import '../core/constants.dart';

enum SubStatus { inactive, trialing, active, pastDue, canceled, unpaid;
  String get value => switch (this) {
        SubStatus.pastDue => 'past_due',
        _ => name,
      };
  static SubStatus parse(String v) {
    return switch (v) {
      'trialing' => SubStatus.trialing,
      'active' => SubStatus.active,
      'past_due' => SubStatus.pastDue,
      'canceled' => SubStatus.canceled,
      'unpaid' => SubStatus.unpaid,
      _ => SubStatus.inactive,
    };
  }
}

class Subscription {
  final String userId;
  final Plan plan;
  final SubStatus status;
  final DateTime? trialEnd;
  final DateTime? currentPeriodEnd;

  const Subscription({
    required this.userId,
    this.plan = Plan.free,
    this.status = SubStatus.inactive,
    this.trialEnd,
    this.currentPeriodEnd,
  });

  bool get isPro => plan == Plan.pro && (status == SubStatus.active || status == SubStatus.trialing);

  factory Subscription.fromMap(Map<String, dynamic> m) => Subscription(
        userId: m['user_id'] as String,
        plan: (m['plan'] as String?) == 'pro' ? Plan.pro : Plan.free,
        status: SubStatus.parse((m['status'] as String?) ?? 'inactive'),
        trialEnd: m['trial_end'] != null ? DateTime.tryParse(m['trial_end'].toString()) : null,
        currentPeriodEnd:
            m['current_period_end'] != null ? DateTime.tryParse(m['current_period_end'].toString()) : null,
      );

  static Subscription guestFree(String userId) => Subscription(userId: userId);
}
