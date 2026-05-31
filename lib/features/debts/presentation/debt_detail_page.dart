import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../profile/application/profile_settings_controller.dart';
import '../../../core/widgets/app_page.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/moni_card.dart';
import '../application/debt_controller.dart';
import '../application/friends_controller.dart';
import '../application/slip_verification_service.dart';
import '../domain/debt_model.dart';
import '../domain/settlement_payment_info.dart';
import 'widgets/debt_tile.dart';

class DebtDetailPage extends ConsumerStatefulWidget {
  const DebtDetailPage({required this.friendId, super.key});

  final String friendId;

  @override
  ConsumerState<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends ConsumerState<DebtDetailPage> {
  bool _settling = false;
  bool _settleAllSent = false;
  final _slipVerificationService = SlipVerificationService();
  final Set<String> _settlingDebtIds = {};
  final Set<String> _sentSettlementDebtIds = {};

  Future<SettlementPaymentInfo?> _choosePaymentInfo({
    required double amount,
    required String remark,
  }) {
    return showModalBottomSheet<SettlementPaymentInfo>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _SettlementPaymentSheet(
        amount: amount,
        remark: remark,
        verificationService: _slipVerificationService,
        symbol: ref.read(currencySymbolProvider),
      ),
    );
  }

  Future<void> _settleAll(String friendId, double amount) async {
    final friendName =
        ref
            .read(friendsControllerProvider)
            .friends
            .where((f) => f.id == friendId)
            .firstOrNull
            ?.name ??
        friendId;
    final paymentInfo = await _choosePaymentInfo(
      amount: amount,
      remark: 'Settle all debts with $friendName',
    );
    if (paymentInfo == null) return;

    setState(() => _settling = true);
    try {
      await ref
          .read(debtControllerProvider.notifier)
          .createSettleAllRequest(friendId, paymentInfo: paymentInfo);
      if (mounted) {
        setState(() => _settleAllSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settlement request sent — check your inbox.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _settling = false);
    }
  }

  Future<void> _settleOne(DebtModel debt) async {
    final paymentInfo = await _choosePaymentInfo(
      amount: debt.amount,
      remark: 'Debt settlement ${debt.id}',
    );
    if (paymentInfo == null) return;

    final debtId = debt.id;
    setState(() => _settlingDebtIds.add(debtId));
    try {
      await ref
          .read(debtControllerProvider.notifier)
          .createSettlementRequest(debtId, paymentInfo: paymentInfo);
      if (mounted) {
        setState(() => _sentSettlementDebtIds.add(debtId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settlement request sent — check your inbox.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _settlingDebtIds.remove(debtId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final friend = ref
        .watch(friendsControllerProvider)
        .friends
        .where((item) => item.id == widget.friendId)
        .firstOrNull;

    if (friend == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/debts');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final debtState = ref.watch(debtControllerProvider);
    final debts = debtsForFriend(debtState, widget.friendId);
    final lent = lentToFriend(debts);
    final borrowed = borrowedFromFriend(debts);
    final net = lent - borrowed;
    final activeDebts = debts.where((d) => d.status == DebtStatus.active);
    final activeTotal = activeDebts.fold<double>(
      0,
      (sum, debt) => sum + debt.amount,
    );
    final symbol = ref.watch(currencySymbolProvider);

    return Scaffold(
      body: AppPage(
        title: friend.name,
        subtitle: friend.username,
        onRefresh: () async {
          await Future.wait([
            ref.read(debtControllerProvider.notifier).refresh(),
            ref.read(friendsControllerProvider.notifier).refresh(),
          ]);
        },
        action: TextButton(
          onPressed: () => context.go('/debts'),
          child: const Text('Close'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth > 760
                    ? (constraints.maxWidth - 24) / 3
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricCard(
                      label: 'Lent to friend',
                      value: lent,
                      width: width,
                      symbol: symbol,
                    ),
                    _MetricCard(
                      label: 'Borrowed from friend',
                      value: borrowed,
                      width: width,
                      symbol: symbol,
                    ),
                    _MetricCard(
                      label: 'Final net amount',
                      value: net,
                      width: width,
                      symbol: symbol,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: activeDebts.isEmpty || _settling || _settleAllSent
                    ? null
                    : () => _settleAll(widget.friendId, activeTotal),
                child: _settling
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_settleAllSent ? 'Request sent' : 'Settle All'),
              ),
            ),
            const SizedBox(height: 24),
            Text('History', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (debts.isEmpty)
              const EmptyState(
                title: 'No history yet',
                message:
                    'Borrow or lend money with this friend to build a shared history.',
                icon: LucideIcons.handCoins,
              )
            else
              Column(
                children: [
                  for (final debt in debts) ...[
                    DebtTransactionCard(
                      debt: debt,
                      settling: _settlingDebtIds.contains(debt.id),
                      onSettle:
                          _sentSettlementDebtIds.contains(debt.id) ||
                              _settleAllSent
                          ? null
                          : () => _settleOne(debt),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SettlementPaymentSheet extends StatefulWidget {
  const _SettlementPaymentSheet({
    required this.amount,
    required this.remark,
    required this.verificationService,
    required this.symbol,
  });

  final double amount;
  final String remark;
  final SlipVerificationService verificationService;
  final String symbol;

  @override
  State<_SettlementPaymentSheet> createState() =>
      _SettlementPaymentSheetState();
}

class _SettlementPaymentSheetState extends State<_SettlementPaymentSheet> {
  final _picker = ImagePicker();
  var _method = SettlementPaymentMethod.cash;
  var _verifying = false;
  SettlementPaymentInfo? _verifiedTransfer;
  String? _error;

  Future<void> _pickAndVerifyReceipt() async {
    setState(() {
      _verifying = true;
      _error = null;
      _verifiedTransfer = null;
    });

    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (image == null) {
        return;
      }

      final payload = await widget.verificationService.readQrPayload(
        image.path,
      );
      final verified = await widget.verificationService.verifyBankSlip(
        payload: payload,
        expectedAmount: widget.amount,
        remark: widget.remark,
      );

      if (mounted) {
        setState(() => _verifiedTransfer = verified);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _verifying = false);
      }
    }
  }

  void _confirm() {
    if (_method == SettlementPaymentMethod.cash) {
      Navigator.of(context).pop(const SettlementPaymentInfo.cash());
      return;
    }
    final verified = _verifiedTransfer;
    if (verified != null) {
      Navigator.of(context).pop(verified);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm =
        _method == SettlementPaymentMethod.cash || _verifiedTransfer != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Settle payment',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Amount ${CurrencyFormatter.compact(widget.amount, widget.symbol)}',
            ),
            const SizedBox(height: 16),
            SegmentedButton<SettlementPaymentMethod>(
              segments: const [
                ButtonSegment(
                  value: SettlementPaymentMethod.cash,
                  icon: Icon(LucideIcons.banknote),
                  label: Text('Cash'),
                ),
                ButtonSegment(
                  value: SettlementPaymentMethod.transfer,
                  icon: Icon(LucideIcons.receiptText),
                  label: Text('Transfer'),
                ),
              ],
              selected: {_method},
              onSelectionChanged: (value) {
                setState(() {
                  _method = value.first;
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_method == SettlementPaymentMethod.cash)
              const _PaymentInfoPanel(
                icon: LucideIcons.badgeCheck,
                title: 'Cash settlement',
                message:
                    'A normal settlement request will be sent to your friend.',
              )
            else ...[
              _PaymentInfoPanel(
                icon: _verifiedTransfer == null
                    ? LucideIcons.upload
                    : LucideIcons.badgeCheck,
                title: _verifiedTransfer == null
                    ? 'Upload transfer receipt'
                    : 'Transfer verified',
                message: _verifiedTransfer == null
                    ? 'Choose a QR slip image. Moni reads only the QR payload and does not store the image.'
                    : 'The transfer slip was verified and the settlement request can be sent.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _verifying ? null : _pickAndVerifyReceipt,
                icon: _verifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.imageUp),
                label: Text(
                  _verifiedTransfer == null
                      ? 'Choose receipt image'
                      : 'Choose another receipt',
                ),
              ),
              if (_verifiedTransfer != null) ...[
                const SizedBox(height: 10),
                _VerifiedTransferSummary(
                  info: _verifiedTransfer!,
                  symbol: widget.symbol,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFB3261E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: canConfirm ? _confirm : null,
              child: const Text('Confirm settlement'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentInfoPanel extends StatelessWidget {
  const _PaymentInfoPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE7E0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2F855A)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerifiedTransferSummary extends StatelessWidget {
  const _VerifiedTransferSummary({required this.info, required this.symbol});

  final SettlementPaymentInfo info;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          label: Text(
            CurrencyFormatter.compact(info.amountInSlip ?? 0, symbol),
          ),
        ),
        if (info.bankShortName != null) Chip(label: Text(info.bankShortName!)),
        if (info.transactionRef != null)
          Chip(label: Text('Ref ${info.transactionRef!}')),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.width,
    required this.symbol,
  });

  final String label;
  final double value;
  final double width;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: MoniCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.compact(value, symbol),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
