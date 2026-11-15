import 'package:intl/intl.dart';

class DailyEarningItem {
  final String day;
  final int amount; // in whole Rupees

  const DailyEarningItem({required this.day, required this.amount});
}

class EarningsSummary {
  final int totalEarnings; // in Rupees
  final int tripEarnings;  // in Rupees
  final int incentives;    // in Rupees
  final int totalTrips;
  final String onlineTime;
  final int payoutWalletBalancePaisa;
  final int mainWalletBalancePaisa;
  final List<DailyEarningItem> last7Days;

  const EarningsSummary({
    required this.totalEarnings,
    required this.tripEarnings,
    required this.incentives,
    required this.totalTrips,
    required this.onlineTime,
    required this.payoutWalletBalancePaisa,
    required this.mainWalletBalancePaisa,
    required this.last7Days,
  });

  String get formattedTotal => '₹$totalEarnings';
  String get formattedTrips => '₹$tripEarnings';
  String get formattedIncentives => '₹$incentives';
  String get formattedPayoutWallet => '₹${(payoutWalletBalancePaisa / 100).toStringAsFixed(2)}';
  String get formattedMainWallet => '₹${(mainWalletBalancePaisa / 100).toStringAsFixed(2)}';

  factory EarningsSummary.empty() {
    return const EarningsSummary(
      totalEarnings: 0,
      tripEarnings: 0,
      incentives: 0,
      totalTrips: 0,
      onlineTime: '0 h 0 m',
      payoutWalletBalancePaisa: 0,
      mainWalletBalancePaisa: 0,
      last7Days: [
        DailyEarningItem(day: 'Mon', amount: 0),
        DailyEarningItem(day: 'Tue', amount: 0),
        DailyEarningItem(day: 'Wed', amount: 0),
        DailyEarningItem(day: 'Thu', amount: 0),
        DailyEarningItem(day: 'Fri', amount: 0),
        DailyEarningItem(day: 'Sat', amount: 0),
        DailyEarningItem(day: 'Sun', amount: 0),
      ],
    );
  }

  /// Parses real earnings and dual-wallet balance directly from API response payloads.
  factory EarningsSummary.fromApi({
    required dynamic walletResponse,
    required List<dynamic> transactions,
    required String filterType, // 'today', 'week', 'month'
  }) {
    int payoutBalance = 0;
    int mainBalance = 0;

    if (walletResponse is Map) {
      final wallet = walletResponse['wallet'] is Map
          ? walletResponse['wallet'] as Map<String, dynamic>
          : walletResponse as Map<String, dynamic>;

      payoutBalance = (wallet['payoutBalance'] as num?)?.toInt() ??
          (wallet['payoutWalletBalance'] as num?)?.toInt() ??
          0;

      mainBalance = (wallet['mainBalance'] as num?)?.toInt() ??
          (wallet['mainWalletBalance'] as num?)?.toInt() ??
          0;
    }

    int totalAmountPaisa = 0;
    int tripEarningsPaisa = 0;
    int incentivesPaisa = 0;
    int tripCount = 0;

    // Daily buckets for chart
    final now = DateTime.now();
    final List<DailyEarningItem> chartItems = [];

    if (filterType == 'month') {
      // 4 week buckets: W1, W2, W3, W4
      final weekSums = [0, 0, 0, 0];
      for (final raw in transactions) {
        if (raw is! Map) continue;
        final tx = raw as Map<String, dynamic>;
        final direction = tx['direction']?.toString();
        if (direction != 'CREDIT') continue;

        final amount = (tx['amount'] as num?)?.toInt() ?? 0;
        totalAmountPaisa += amount;

        final meta = tx['metadata'] is Map ? (tx['metadata'] as Map<String, dynamic>) : null;
        final tip = (meta?['tip'] as num?)?.toInt() ?? (meta?['incentive'] as num?)?.toInt() ?? 0;
        final fee = (meta?['deliveryFee'] as num?)?.toInt() ?? (amount - tip);
        tripEarningsPaisa += fee;
        incentivesPaisa += tip;
        tripCount++;

        final createdStr = tx['createdAt']?.toString();
        if (createdStr != null) {
          final dt = DateTime.tryParse(createdStr)?.toLocal();
          if (dt != null) {
            final day = dt.day;
            final weekIdx = (day <= 7) ? 0 : (day <= 14) ? 1 : (day <= 21) ? 2 : 3;
            weekSums[weekIdx] += (amount / 100).round();
          }
        }
      }

      chartItems.addAll([
        DailyEarningItem(day: 'W1', amount: weekSums[0]),
        DailyEarningItem(day: 'W2', amount: weekSums[1]),
        DailyEarningItem(day: 'W3', amount: weekSums[2]),
        DailyEarningItem(day: 'W4', amount: weekSums[3]),
      ]);
    } else {
      // 7 days ending with today
      final Map<String, int> daySums = {};
      final List<DateTime> last7DaysList = [];
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        last7DaysList.add(d);
        final key = DateFormat('yyyy-MM-dd').format(d);
        daySums[key] = 0;
      }

      for (final raw in transactions) {
        if (raw is! Map) continue;
        final tx = raw as Map<String, dynamic>;
        final direction = tx['direction']?.toString();
        if (direction != 'CREDIT') continue;

        final amount = (tx['amount'] as num?)?.toInt() ?? 0;
        totalAmountPaisa += amount;

        final meta = tx['metadata'] is Map ? (tx['metadata'] as Map<String, dynamic>) : null;
        final tip = (meta?['tip'] as num?)?.toInt() ?? (meta?['incentive'] as num?)?.toInt() ?? 0;
        final fee = (meta?['deliveryFee'] as num?)?.toInt() ?? (amount - tip);
        tripEarningsPaisa += fee;
        incentivesPaisa += tip;
        tripCount++;

        final createdStr = tx['createdAt']?.toString();
        if (createdStr != null) {
          final dt = DateTime.tryParse(createdStr)?.toLocal();
          if (dt != null) {
            final key = DateFormat('yyyy-MM-dd').format(dt);
            if (daySums.containsKey(key)) {
              daySums[key] = (daySums[key] ?? 0) + (amount / 100).round();
            }
          }
        }
      }

      for (final d in last7DaysList) {
        final key = DateFormat('yyyy-MM-dd').format(d);
        final dayLabel = DateFormat('E').format(d); // e.g. Mon, Tue
        chartItems.add(DailyEarningItem(day: dayLabel, amount: daySums[key] ?? 0));
      }
    }

    // If no transactions yet but today filter, total is 0
    final totalRupees = (totalAmountPaisa / 100).round();
    final tripsRupees = (tripEarningsPaisa / 100).round();
    final incRupees = (incentivesPaisa / 100).round();

    return EarningsSummary(
      totalEarnings: totalRupees,
      tripEarnings: tripsRupees,
      incentives: incRupees,
      totalTrips: tripCount,
      onlineTime: tripCount > 0 ? '${tripCount * 45 ~/ 60} h ${(tripCount * 45) % 60} m' : '0 h 0 m',
      payoutWalletBalancePaisa: payoutBalance,
      mainWalletBalancePaisa: mainBalance,
      last7Days: chartItems,
    );
  }

  factory EarningsSummary.sampleToday() {
    return const EarningsSummary(
      totalEarnings: 1240,
      tripEarnings: 1000,
      incentives: 240,
      totalTrips: 5,
      onlineTime: '4 h 20 m',
      payoutWalletBalancePaisa: 124000,
      mainWalletBalancePaisa: 50000,
      last7Days: [
        DailyEarningItem(day: 'Mon', amount: 850),
        DailyEarningItem(day: 'Tue', amount: 920),
        DailyEarningItem(day: 'Wed', amount: 1100),
        DailyEarningItem(day: 'Thu', amount: 780),
        DailyEarningItem(day: 'Fri', amount: 1400),
        DailyEarningItem(day: 'Sat', amount: 1650),
        DailyEarningItem(day: 'Sun', amount: 1240),
      ],
    );
  }

  factory EarningsSummary.sampleWeek() {
    return const EarningsSummary(
      totalEarnings: 7940,
      tripEarnings: 6500,
      incentives: 1440,
      totalTrips: 34,
      onlineTime: '28 h 45 m',
      payoutWalletBalancePaisa: 794000,
      mainWalletBalancePaisa: 120000,
      last7Days: [
        DailyEarningItem(day: 'Mon', amount: 850),
        DailyEarningItem(day: 'Tue', amount: 920),
        DailyEarningItem(day: 'Wed', amount: 1100),
        DailyEarningItem(day: 'Thu', amount: 780),
        DailyEarningItem(day: 'Fri', amount: 1400),
        DailyEarningItem(day: 'Sat', amount: 1650),
        DailyEarningItem(day: 'Sun', amount: 1240),
      ],
    );
  }

  factory EarningsSummary.sampleMonth() {
    return const EarningsSummary(
      totalEarnings: 32450,
      tripEarnings: 26800,
      incentives: 5650,
      totalTrips: 142,
      onlineTime: '118 h 10 m',
      payoutWalletBalancePaisa: 3245000,
      mainWalletBalancePaisa: 350000,
      last7Days: [
        DailyEarningItem(day: 'W1', amount: 7800),
        DailyEarningItem(day: 'W2', amount: 8200),
        DailyEarningItem(day: 'W3', amount: 8510),
        DailyEarningItem(day: 'W4', amount: 7940),
      ],
    );
  }
}
