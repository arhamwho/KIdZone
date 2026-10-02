import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user_role.dart';
import '../../models/wallet_model.dart';
import '../../services/family_session.dart';
import '../../services/wallet_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/firestore_codec.dart';
import '../../utils/validators.dart';
import '../../widgets/child_picker.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_views.dart';

/// Send Money and Set Allowance, side by side at the same height.
///
/// Width follows each label so "Set Allowance" stays on one line without
/// shrinking the type on a normal phone.
class PocketMoneyActions extends StatelessWidget {
  const PocketMoneyActions({
    super.key,
    required this.onSend,
    required this.onSetAllowance,
  });

  static const double height = 52;

  final VoidCallback onSend;
  final VoidCallback onSetAllowance;

  double _labelWidth(BuildContext context, String label, TextStyle? style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    return painter.width;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? labelStyle = Theme.of(context).textTheme.labelLarge;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = AppSpacing.sm;
        final double sendText = _labelWidth(context, 'Send Money', labelStyle);
        final double allowanceText = _labelWidth(
          context,
          'Set Allowance',
          labelStyle,
        );
        final double inner = math.max(0, constraints.maxWidth - gap);
        final double textSum = math.max(1, sendText + allowanceText);
        final double sendSlot = inner * sendText / textSum;
        final double allowanceSlot = inner - sendSlot;

        double horizontalPad = AppSpacing.xs;
        for (final double candidate in <double>[
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
        ]) {
          final bool sendFits = sendText + candidate * 2 <= sendSlot + 0.5;
          final bool allowanceFits =
              allowanceText + candidate * 2 <= allowanceSlot + 0.5;
          if (sendFits && allowanceFits) {
            horizontalPad = candidate;
            break;
          }
        }

        ButtonStyle styleOf({required bool filled}) {
          final ButtonStyle base = filled
              ? FilledButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                  textStyle: labelStyle,
                )
              : OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                  textStyle: labelStyle,
                );
          return base.copyWith(
            minimumSize: const WidgetStatePropertyAll<Size>(Size(0, height)),
            maximumSize: const WidgetStatePropertyAll<Size>(
              Size(double.infinity, height),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        }

        Widget label(String text) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, maxLines: 1, softWrap: false),
          );
        }

        return Row(
          children: <Widget>[
            Expanded(
              flex: math.max(1, sendText.round()),
              child: SizedBox(
                height: height,
                child: FilledButton(
                  style: styleOf(filled: true),
                  onPressed: onSend,
                  child: label('Send Money'),
                ),
              ),
            ),
            const SizedBox(width: gap),
            Expanded(
              flex: math.max(1, allowanceText.round()),
              child: SizedBox(
                height: height,
                child: OutlinedButton(
                  style: styleOf(filled: false),
                  onPressed: onSetAllowance,
                  child: label('Set Allowance'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PocketMoneyScreen extends StatefulWidget {
  const PocketMoneyScreen({super.key});

  @override
  State<PocketMoneyScreen> createState() => _PocketMoneyScreenState();
}

class _PocketMoneyScreenState extends State<PocketMoneyScreen> {
  String? _primedChildId;

  Future<void> _primeParentWallet(FamilyScope scope) async {
    final String? childId = scope.selectedChild?.uid;
    if (childId == null) return;
    if (_primedChildId == childId) return;
    _primedChildId = childId;
    try {
      await WalletService.instance.ensureWallet(
        familyId: scope.familyId,
        childId: childId,
      );
      await WalletService.instance.applyDueAllowance(
        familyId: scope.familyId,
        childId: childId,
        parentId: scope.user.uid,
      );
    } catch (_) {
      _primedChildId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
      builder: (BuildContext context, FamilyScope scope) {
        final bool isParent = scope.user.role == UserRole.parent;
        final String? childId = isParent
            ? scope.selectedChild?.uid
            : scope.user.uid;
        if (isParent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _primeParentWallet(scope);
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            AppTopBar(title: isParent ? 'Pocket Money' : 'My Money'),
            if (isParent)
              ChildPicker(
                children: scope.children,
                selectedId: scope.selectedChild?.uid,
                onSelected: FamilySession.instance.selectChild,
              ),
            if (isParent) const SizedBox(height: AppSpacing.md),
            Expanded(
              child: childId == null
                  ? const MessageView(
                      'Add a child to manage pocket money.',
                      icon: Icons.account_balance_wallet_outlined,
                    )
                  : _WalletBody(
                      familyId: scope.familyId,
                      childId: childId,
                      parentId: isParent ? scope.user.uid : null,
                      isParent: isParent,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _WalletBody extends StatelessWidget {
  const _WalletBody({
    required this.familyId,
    required this.childId,
    required this.isParent,
    this.parentId,
  });

  final String familyId;
  final String childId;
  final String? parentId;
  final bool isParent;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<WalletModel>(
      stream: WalletService.instance.watchWallet(
        familyId: familyId,
        childId: childId,
      ),
      builder: (BuildContext context, AsyncSnapshot<WalletModel> walletSnap) {
        if (walletSnap.hasError) {
          return const MessageView('Unable to load this wallet.');
        }
        final WalletModel wallet =
            walletSnap.data ?? WalletModel.empty(childId);
        return StreamBuilder<List<WalletTransactionModel>>(
          stream: WalletService.instance.watchTransactions(
            familyId: familyId,
            childId: childId,
          ),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<WalletTransactionModel>> txSnap,
              ) {
                if (txSnap.hasError) {
                  return const MessageView('Unable to load transactions.');
                }
                final List<WalletTransactionModel> items =
                    txSnap.data ?? const <WalletTransactionModel>[];
                return ListView(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.navClearance,
                  ),
                  children: <Widget>[
                    KidCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            isParent ? 'Current Balance' : 'My Money',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            formatRupees(wallet.balance),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            isParent ? 'Allowance' : 'Next Allowance',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            wallet.nextAllowanceLabel,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                    if (isParent && parentId != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      PocketMoneyActions(
                        onSend: () => _openSendSheet(
                          context,
                          familyId: familyId,
                          childId: childId,
                          parentId: parentId!,
                        ),
                        onSetAllowance: () => _openAllowanceSheet(
                          context,
                          familyId: familyId,
                          childId: childId,
                          parentId: parentId!,
                          wallet: wallet,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      isParent ? 'Recent Transactions' : 'Transaction History',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (items.isEmpty)
                      const KidCard(child: Text('No transactions yet.'))
                    else
                      for (final WalletTransactionModel item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: KidCard(
                            child: Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        formatRupees(item.amount),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                      Text(
                                        item.note.isEmpty
                                            ? item.type.label
                                            : item.note,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      if (item.createdAt != null)
                                        Text(
                                          formatRelative(item.createdAt!),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  item.type.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                );
              },
        );
      },
    );
  }

  void _openSendSheet(
    BuildContext context, {
    required String familyId,
    required String childId,
    required String parentId,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SendMoneySheet(
        familyId: familyId,
        childId: childId,
        parentId: parentId,
      ),
    );
  }

  void _openAllowanceSheet(
    BuildContext context, {
    required String familyId,
    required String childId,
    required String parentId,
    required WalletModel wallet,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AllowanceSheet(
        familyId: familyId,
        childId: childId,
        parentId: parentId,
        wallet: wallet,
      ),
    );
  }
}

class _SendMoneySheet extends StatefulWidget {
  const _SendMoneySheet({
    required this.familyId,
    required this.childId,
    required this.parentId,
  });

  final String familyId;
  final String childId;
  final String parentId;

  @override
  State<_SendMoneySheet> createState() => _SendMoneySheetState();
}

class _SendMoneySheetState extends State<_SendMoneySheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await WalletService.instance.sendMoney(
        familyId: widget.familyId,
        childId: widget.childId,
        parentId: widget.parentId,
        amount: int.parse(_amount.text.trim()),
        note: _note.text.trim().isEmpty ? 'Pocket Money' : _note.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('Send Money', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                ),
                validator: Validators.money,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _note,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Note / reason'),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _busy ? 'Sending…' : 'Send',
                expand: true,
                compact: true,
                onPressed: _busy ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllowanceSheet extends StatefulWidget {
  const _AllowanceSheet({
    required this.familyId,
    required this.childId,
    required this.parentId,
    required this.wallet,
  });

  final String familyId;
  final String childId;
  final String parentId;
  final WalletModel wallet;

  @override
  State<_AllowanceSheet> createState() => _AllowanceSheetState();
}

class _AllowanceSheetState extends State<_AllowanceSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late AllowanceFrequency _frequency;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
      text: widget.wallet.allowanceAmount > 0
          ? '${widget.wallet.allowanceAmount}'
          : '',
    );
    _frequency = widget.wallet.allowanceFrequency;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await WalletService.instance.setAllowance(
        familyId: widget.familyId,
        childId: widget.childId,
        parentId: widget.parentId,
        amount: int.parse(_amount.text.trim()),
        frequency: _frequency,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Set Allowance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Recurring amount (₹)',
                  prefixText: '₹ ',
                ),
                validator: (String? value) =>
                    Validators.money(value, min: 0, max: 100000),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<AllowanceFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Frequency'),
                items: <DropdownMenuItem<AllowanceFrequency>>[
                  for (final AllowanceFrequency item
                      in AllowanceFrequency.values)
                    DropdownMenuItem<AllowanceFrequency>(
                      value: item,
                      child: Text(item.label),
                    ),
                ],
                onChanged: (AllowanceFrequency? value) {
                  if (value != null) setState(() => _frequency = value);
                },
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _busy ? 'Saving…' : 'Save allowance',
                expand: true,
                compact: true,
                onPressed: _busy ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
