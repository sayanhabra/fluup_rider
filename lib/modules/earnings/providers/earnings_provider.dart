import 'dart:io';
import 'package:adm_rider/core/api/api_service.dart';
import 'package:adm_rider/modules/earnings/models/earnings_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum EarningsFilter { today, week, month }

class EarningsState {
  final EarningsFilter filter;
  final EarningsSummary summary;
  final bool isLoading;
  final String? message;

  const EarningsState({
    this.filter = EarningsFilter.today,
    required this.summary,
    this.isLoading = false,
    this.message,
  });

  EarningsState copyWith({
    EarningsFilter? filter,
    EarningsSummary? summary,
    bool? isLoading,
    String? message,
  }) {
    return EarningsState(
      filter: filter ?? this.filter,
      summary: summary ?? this.summary,
      isLoading: isLoading ?? this.isLoading,
      message: message,
    );
  }
}

class EarningsNotifier extends Notifier<EarningsState> {
  late final ApiService _apiService;

  @override
  EarningsState build() {
    _apiService = ref.read(apiServiceProvider);
    if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
      Future.microtask(() => loadEarnings(EarningsFilter.today));
    }
    return EarningsState(
      filter: EarningsFilter.today,
      summary: EarningsSummary.empty(),
      isLoading: !(!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')),
    );
  }

  Future<void> loadEarnings(EarningsFilter filter) async {
    state = state.copyWith(filter: filter, isLoading: true, message: null);

    try {
      // 1. Fetch live rider wallet (dual balance & payout account)
      final walletRes = await _apiService.getRiderWallet();
      final walletData = walletRes.data;

      // 2. Compute date range according to filter
      final now = DateTime.now();
      DateTime startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final filterStr = switch (filter) {
        EarningsFilter.today => () {
            startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
            return 'today';
          }(),
        EarningsFilter.week => () {
            startDate = DateTime(now.year, now.month, now.day, 0, 0, 0)
                .subtract(const Duration(days: 6));
            return 'week';
          }(),
        EarningsFilter.month => () {
            startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
            return 'month';
          }(),
      };

      // 3. Fetch live transactions from backend ledger
      final txRes = await _apiService.getRiderTransactions(
        limit: 100,
        startDate: startDate.toUtc().toIso8601String(),
        endDate: endDate.toUtc().toIso8601String(),
      );

      List<dynamic> transactions = [];
      final txData = txRes.data;
      if (txData is Map) {
        final list = txData['data'] ?? txData['items'] ?? txData['transactions'];
        if (list is List) {
          transactions = list;
        }
      } else if (txData is List) {
        transactions = txData;
      }

      // 4. Construct strictly from real API response
      final liveSummary = EarningsSummary.fromApi(
        walletResponse: walletData,
        transactions: transactions,
        filterType: filterStr,
      );

      state = state.copyWith(
        summary: liveSummary,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('⚠️ Error loading earnings from API: $e');
      state = state.copyWith(
        isLoading: false,
        message: 'Could not load earnings data',
      );
    }
  }

  void setFilter(EarningsFilter filter) {
    loadEarnings(filter);
  }

  Future<void> refresh() async {
    await loadEarnings(state.filter);
  }

  Future<bool> requestWithdrawal({
    required int amountPaisa,
    required String method,
    String? upiId,
    String? bankAccount,
    String? ifsc,
  }) async {
    state = state.copyWith(isLoading: true, message: null);
    try {
      await _apiService.withdrawWallet(
        amount: amountPaisa,
        payoutMethod: method,
        upiId: upiId,
        bankAccountNumber: bankAccount,
        ifscCode: ifsc,
      );
      state = state.copyWith(
        isLoading: false,
        message: 'Withdrawal request submitted successfully',
      );
      // Refresh wallet & transactions
      await refresh();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        message: 'Withdrawal failed: $e',
      );
      return false;
    }
  }
}

final earningsProvider =
    NotifierProvider<EarningsNotifier, EarningsState>(
  () => EarningsNotifier(),
);
