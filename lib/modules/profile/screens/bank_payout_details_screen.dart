import 'package:adm_rider/core/api/api_service.dart';
import 'package:adm_rider/core/config/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BankPayoutDetailsScreen extends ConsumerStatefulWidget {
  const BankPayoutDetailsScreen({super.key});

  @override
  ConsumerState<BankPayoutDetailsScreen> createState() =>
      _BankPayoutDetailsScreenState();
}

class _BankPayoutDetailsScreenState
    extends ConsumerState<BankPayoutDetailsScreen> {
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  final _nameController = TextEditingController();
  final _upiController = TextEditingController();
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadPayoutAccount();
  }

  @override
  void dispose() {
    _bankAccountController.dispose();
    _ifscController.dispose();
    _nameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _loadPayoutAccount() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.getRiderWallet();
      final data = res.data;
      if (data is Map) {
        final payout = data['payoutAccount'] is Map
            ? data['payoutAccount'] as Map<String, dynamic>
            : (data['response'] is Map && data['response']['payoutAccount'] is Map
                ? data['response']['payoutAccount'] as Map<String, dynamic>
                : null);

        if (payout != null && mounted) {
          _bankAccountController.text = payout['bankAccountNumber']?.toString() ?? '';
          _ifscController.text = payout['ifscCode']?.toString() ?? '';
          _nameController.text = payout['bankAccountName']?.toString() ?? '';
          _upiController.text = payout['upiId']?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading payout account: $e');
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _savePayoutDetails() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.updatePayoutAccount(
        bankAccountNumber: _bankAccountController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        bankAccountName: _nameController.text.trim(),
        upiId: _upiController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payout details updated successfully!'),
            backgroundColor: Brand.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Brand.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Bank & Payout Details',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isFetching
          ? const Center(
              child: CircularProgressIndicator(color: Brand.red),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UPI Destination',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _upiController,
                          decoration: InputDecoration(
                            labelText: 'UPI ID (VPA)',
                            hintText: 'e.g. mobile@upi',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Bank Account Destination',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Account Holder Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _bankAccountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Bank Account Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _ifscController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'IFSC Code',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _savePayoutDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Brand.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Payout Account',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
