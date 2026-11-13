import 'package:flutter/material.dart';

import '../data/api_error.dart';
import '../data/seller_profile_store.dart';
import '../data/supabase_product_api.dart';
import '../l10n/app_strings.dart';
import '../services/auth_flow.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/design_canvas.dart';
import '../widgets/page_header.dart';
import '../widgets/label_text.dart';
import 'bank_detaile.dart';

/// Bank Details — Zeplin "Android Compact - 162"
/// (project 6a8d49709e27bd8b35213d35, screen 6ad1af83accbf212263edabb).
///
/// Built against a 412x917 artboard. Shows the account(s) saved in Supabase
/// (`seller_bank_details`): the primary account in the card, extra accounts
/// as tappable "Set primary" rows, and a working "Add another bank account"
/// button. When signed out (design replica / tests) the Zeplin mock content
/// is shown instead; a signed-in seller never sees the mock — while the
/// fetch runs the card shows a spinner, and a failed fetch falls back to
/// the honest empty state instead of fake account data.
class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  static const double designWidth = 412;
  static const double designHeight = 917;
  static const double trimTop = 49;

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  List<Map<String, dynamic>> _accounts = const [];
  int _activeIndex = 0;
  bool _loaded = false;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _signedIn = _sessionIds().isNotEmpty;
    _loadBankAccounts();
  }

  static List<String> _sessionIds() => <String>{
        AuthFlow.instance.firebaseUid ?? '',
        SellerProfileStore.instance.userId,
      }.where((String id) => id.trim().isNotEmpty).toList();

  Future<void> _loadBankAccounts() async {
    final List<String> ids = _sessionIds();
    // Signed out — the design replica mock below is intentional.
    if (ids.isEmpty) return;
    try {
      final List<Map<String, dynamic>> rows =
          await SupabaseProductApi().getBankDetailsForUsers(ids);
      if (!mounted) return;

      final SellerProfileStore store = SellerProfileStore.instance;
      store.setBankAccounts(rows);
      setState(() {
        _accounts = rows;
        _activeIndex = rows.isEmpty ? 0 : store.activeBankIndex;
        _loaded = true;
      });
    } catch (_) {
      // A signed-in load failure must never show the fake design account as
      // if it were the seller's own saved data — show the empty state
      // instead (reopening the page retries the fetch).
      if (!mounted) return;
      setState(() {
        _accounts = const [];
        _loaded = true;
      });
    }
  }

  Future<void> _addAccount() async {
    final bool? added = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => const BankDetaileScreen(addMode: true),
      ),
    );
    if (added != true || !mounted) return;
    await _loadBankAccounts();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppStrings.trOf(context, 'Bank account added successfully'))),
      );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _setPrimary(int index) async {
    if (index == _activeIndex) return;
    final int previous = _activeIndex;
    setState(() => _activeIndex = index);

    final SellerProfileStore store = SellerProfileStore.instance;
    store.setActiveBankIndex(index);

    final String id =
        (_accounts[index]['id'] ?? '').toString().trim();
    if (id.isEmpty) return;
    try {
      final SupabaseProductApi api = SupabaseProductApi();
      if (store.userId.isNotEmpty) api.userId = store.userId;
      await api.updateActiveBankAccountId(id);
    } on ApiException catch (error) {
      // Persistence failed — put the badge back and say why, instead of
      // pretending the primary account was saved.
      if (mounted) {
        setState(() => _activeIndex = previous);
        store.setActiveBankIndex(previous);
      }
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _activeIndex = previous);
      store.setActiveBankIndex(previous);
      _showError(
        AppStrings.trOf(context, 'Could not update the primary account. Please try again.'),
      );
    }
  }

  Future<void> _showAllAccountsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AllAccountsSheet(),
    );
    if (mounted) await _loadBankAccounts();
  }

  String _field(Map<String, dynamic>? row, String key, String fallback) {
    final String value =
        row == null ? '' : (row[key] ?? '').toString().trim();
    return value.isEmpty ? fallback : value;
  }

  String _accountTail(Map<String, dynamic>? row, String fallback) {
    final String number = row == null
        ? ''
        : (row['account_number'] ?? '').toString().replaceAll(' ', '');
    if (number.length < 4) return fallback;
    return number.substring(number.length - 4);
  }

  @override
  Widget build(BuildContext context) {
    // Zeplin mock content only for the signed-out design replica; a
    // signed-in seller sees a spinner while the fetch runs and real data
    // (or the empty state) afterwards.
    final bool mock = !_loaded && !_signedIn;
    final bool loading = !_loaded && _signedIn;
    final Map<String, dynamic>? active =
        _accounts.isEmpty ? null : _accounts[_activeIndex];
    final List<int> otherIndexes = <int>[
      for (int i = 0; i < _accounts.length; i++)
        if (i != _activeIndex) i,
    ];
    final double extra = otherIndexes.length * 64.0;

    final String bankName = mock
        ? 'State Bank of India'
        : _field(active, 'bank_name', AppStrings.trOf(context, 'No bank account yet'));
    final String tail = mock ? '3421' : _accountTail(active, '----');
    final String holder = mock
        ? 'Ramesh Kumar'
        : _field(active, 'account_houlder_name', '-');
    final String ifsc =
        mock ? 'SBINOOO1234' : _field(active, 'IFSC_code', '-');

    return Scaffold(
      backgroundColor: AppColors.homeBg,
      body: SafeArea(
        bottom: false,
        child: DesignCanvas(
          designWidth: BankDetailsScreen.designWidth,
          designHeight: BankDetailsScreen.designHeight,
          trimTop: BankDetailsScreen.trimTop,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: 73,
                child: PageHeader(title: AppStrings.trOf(context, 'Bank Details')),
              ),
              Positioned(
                left: 25,
                top: 127,
                child: loading
                    ? const _BankCardLoading()
                    : _BankCard(
                        bankName: bankName,
                        accountTail: tail,
                        holderName: holder,
                        ifsc: ifsc,
                      ),
              ),
              for (int i = 0; i < otherIndexes.length; i++)
                Positioned(
                  left: 25,
                  top: 308 + i * 64.0,
                  child: _OtherAccountRow(
                    bankName: _field(
                      _accounts[otherIndexes[i]],
                      'bank_name',
                      AppStrings.trOf(context, 'Bank account'),
                    ),
                    accountTail: _accountTail(
                      _accounts[otherIndexes[i]],
                      '----',
                    ),
                    onTap: () => _setPrimary(otherIndexes[i]),
                  ),
                ),
              Positioned(
                left: 25,
                top: 316 + extra,
                child: _UpiCard(onTap: _showAllAccountsSheet),
              ),
              Positioned(
                left: 25,
                top: 456 + extra,
                child: _AddAccountRow(onTap: _addAccount),
              ),
              Positioned(
                left: 87,
                top: 523 + extra,
                width: 238,
                height: 40,
                child: Text(
                  AppStrings.trOf(context, 'Withdrawals go to your primary account \nwithin 1 working day'),
                  style: AppTextStyles.bankNote,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same footprint and gradient as [_BankCard] shown while a signed-in
/// seller's accounts are still loading — the fake design account must not
/// flash in their place.
class _BankCardLoading extends StatelessWidget {
  const _BankCardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 173,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.orderCardDark, AppColors.bankCardEnd],
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({
    required this.bankName,
    required this.accountTail,
    required this.holderName,
    required this.ifsc,
  });

  final String bankName;
  final String accountTail;
  final String holderName;
  final String ifsc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 362,
      height: 173,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(24)),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.orderCardDark, AppColors.bankCardEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, 7),
            blurRadius: 15,
          ),
          BoxShadow(
            color: Color(0x17000000),
            offset: Offset(0, 27),
            blurRadius: 27,
          ),
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 60),
            blurRadius: 36,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 21,
              child: LabelText(
                bankName,
                AppTextStyles.bankName,
                width: 240,
                height: 13,
              ),
            ),
            const Positioned(left: 278, top: 17, child: _PrimaryPill()),
            const Positioned(left: 20, top: 75.7, child: _CardDots()),
            const Positioned(left: 110, top: 75.7, child: _CardDots()),
            Positioned(
              left: 203,
              top: 67,
              child: LabelText(
                accountTail,
                AppTextStyles.bankNumber,
                width: 49,
              ),
            ),
            Positioned(
              left: 20,
              top: 115,
              child: LabelText(
                AppStrings.trOf(context, 'Account holder'),
                AppTextStyles.bankLabel,
                width: 90,
              ),
            ),
            Positioned(
              left: 20,
              top: 133,
              child: LabelText(
                holderName,
                AppTextStyles.bankValue,
                width: 200,
              ),
            ),
            Positioned(
              left: 318,
              top: 115,
              child: LabelText(AppStrings.trOf(context, 'IFSC'), AppTextStyles.bankLabel, width: 28),
            ),
            Positioned(
              left: 245,
              top: 133,
              child: LabelText(ifsc, AppTextStyles.bankValue, width: 101),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryPill extends StatelessWidget {
  const _PrimaryPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 21,
      decoration: const BoxDecoration(
        color: AppColors.orderDark,
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 11,
            top: 7,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.limeLight,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 22,
            top: -2,
            child: LabelText(
              AppStrings.trOf(context, 'Primary'),
              AppTextStyles.profilePillText,
              width: 48,
              height: 20,
            ),
          ),
        ],
      ),
    );
  }
}

/// Four white dots used to mask the middle digits of the account number.
class _CardDots extends StatelessWidget {
  const _CardDots();

  static const double _dot = 10.032;
  static const double _gap = 21.031 - _dot;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 4 * _dot + 3 * _gap,
      height: _dot,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 4; i++)
            Container(
              width: _dot,
              height: _dot,
              margin: EdgeInsets.only(right: i == 3 ? 0 : _gap),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

/// A secondary bank account row shown when the seller has more than one
/// account. Tapping it makes it the primary (card) account.
class _OtherAccountRow extends StatelessWidget {
  const _OtherAccountRow({
    required this.bankName,
    required this.accountTail,
    required this.onTap,
  });

  final String bankName;
  final String accountTail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 362,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              offset: Offset(0, 2),
              blurRadius: 6,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 16,
              top: 8,
              child: SizedBox(
                width: 210,
                child: Text(
                  bankName,
                  style: AppTextStyles.profileMenuTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 31,
              child: SizedBox(
                width: 140,
                child: Text(
                  '•••• $accountTail',
                  style: AppTextStyles.profileMenuSub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Positioned(
              right: 14,
              top: 17,
              child: Container(
                width: 86,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.orderTile,
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  border: Border.fromBorderSide(
                    BorderSide(color: Color(0x12000000)),
                  ),
                ),
                child: Text(
                  AppStrings.trOf(context, 'Set primary'),
                  style: AppTextStyles.kycPillText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpiCard extends StatelessWidget {
  const _UpiCard({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 362,
        height: 113,
        decoration: const BoxDecoration(
          color: AppColors.profileCardBg,
          borderRadius: BorderRadius.all(Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1AB8B8B8),
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
            BoxShadow(
              color: Color(0x17B8B8B8),
              offset: Offset(0, 6),
              blurRadius: 6,
            ),
            BoxShadow(
              color: Color(0x0DB8B8B8),
              offset: Offset(0, 13),
              blurRadius: 8,
            ),
            BoxShadow(
              color: Color(0x03B8B8B8),
              offset: Offset(0, 23),
              blurRadius: 9,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 22,
              top: 13,
              child: LabelText(AppStrings.trOf(context, 'UPI'), AppTextStyles.orderCardTitle, width: 36),
            ),
            const Positioned(left: 21, top: 56, child: _UpiTile()),
            Positioned(
              left: 66,
              top: 53,
              child: LabelText(
                'ramesh@upi',
                AppTextStyles.profileMenuTitle,
                width: 75,
              ),
            ),
            Positioned(
              left: 67,
              top: 68,
              child: LabelText(
                AppStrings.trOf(context, 'Linked to this account'),
                AppTextStyles.bankUpiSub,
                width: 107,
              ),
            ),
            Positioned(left: 283, top: 63, child: _ActivePill()),
          ],
        ),
      ),
    );
  }
}

class _UpiTile extends StatelessWidget {
  const _UpiTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.orderTile,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: const Image(
        image: AssetImage('assets/bank/ic_upi.png'),
        width: 16,
        height: 16,
      ),
    );
  }
}

class _ActivePill extends StatelessWidget {
  const _ActivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 63,
      height: 19,
      decoration: const BoxDecoration(
        color: AppColors.orderTile,
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 9.4,
            top: 7.06,
            child: Container(
              width: 3.879,
              height: 3.879,
              decoration: const BoxDecoration(
                color: AppColors.kycVerifiedText,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 16.9,
            top: -3,
            child: LabelText(
              AppStrings.trOf(context, 'Active'),
              AppTextStyles.kycPillText,
              width: 37,
              height: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAccountRow extends StatelessWidget {
  const _AddAccountRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 362,
        height: 53,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(26)),
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 78,
              top: 21,
              child: Image(
                image: AssetImage('assets/bank/ic_plus.png'),
                width: 11,
                height: 11,
              ),
            ),
            Positioned(
              left: 99,
              top: 14,
              child: LabelText(
                AppStrings.trOf(context, 'Add another bank account'),
                AppTextStyles.bankAdd,
                width: 185,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet opened by tapping the UPI card: shows every saved bank
/// account with full details, lets the seller pick the primary account and
/// add more accounts.
class _AllAccountsSheet extends StatefulWidget {
  const _AllAccountsSheet();

  @override
  State<_AllAccountsSheet> createState() => _AllAccountsSheetState();
}

class _AllAccountsSheetState extends State<_AllAccountsSheet> {
  List<Map<String, dynamic>> _accounts = const [];
  int _activeIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final List<String> ids = <String>{
        AuthFlow.instance.firebaseUid ?? '',
        SellerProfileStore.instance.userId,
      }.where((String id) => id.trim().isNotEmpty).toList();

      if (ids.isEmpty) {
        // Signed out — mirror the design mock shown on the screen.
        setState(() {
          _accounts = <Map<String, dynamic>>[
            <String, dynamic>{
              'bank_name': 'State Bank of India',
              'account_number': '3421',
              'account_houlder_name': 'Ramesh Kumar',
              'IFSC_code': 'SBINOOO1234',
            },
          ];
          _activeIndex = 0;
          _loading = false;
        });
        return;
      }

      final List<Map<String, dynamic>> rows =
          await SupabaseProductApi().getBankDetailsForUsers(ids);
      if (!mounted) return;

      final SellerProfileStore store = SellerProfileStore.instance;
      store.setBankAccounts(rows);
      setState(() {
        _accounts = rows;
        _activeIndex = rows.isEmpty ? 0 : store.activeBankIndex;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setPrimary(int index) async {
    if (index == _activeIndex) return;
    final int previous = _activeIndex;
    setState(() => _activeIndex = index);

    final SellerProfileStore store = SellerProfileStore.instance;
    store.setActiveBankIndex(index);

    final String id = (_accounts[index]['id'] ?? '').toString().trim();
    if (id.isEmpty) return;
    try {
      final SupabaseProductApi api = SupabaseProductApi();
      if (store.userId.isNotEmpty) api.userId = store.userId;
      await api.updateActiveBankAccountId(id);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _activeIndex = previous);
        store.setActiveBankIndex(previous);
      }
      _showError(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _activeIndex = previous);
      store.setActiveBankIndex(previous);
      _showError(
        AppStrings.trOf(context, 'Could not update the primary account. Please try again.'),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addAccount() async {
    final bool? added = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => const BankDetaileScreen(addMode: true),
      ),
    );
    if (added == true && mounted) await _load();
  }

  String _field(Map<String, dynamic> row, String key) =>
      (row[key] ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x33000000),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(AppStrings.trOf(context, 'All bank accounts'), style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(
            AppStrings.trOf(context, 'Your saved bank details'),
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                AppStrings.trOf(context, 'No bank account yet'),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _accounts.length,
                itemBuilder: (BuildContext context, int index) =>
                    _accountTile(index),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 53,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _addAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.orderTile,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(AppStrings.trOf(context, 'Add bank account')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountTile(int index) {
    final Map<String, dynamic> row = _accounts[index];
    final bool primary = index == _activeIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _setPrimary(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.profileCardBg,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(
            color: primary ? AppColors.pillBorder : const Color(0x14000000),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _field(row, 'bank_name').isEmpty
                        ? AppStrings.trOf(context, 'Bank account')
                        : _field(row, 'bank_name'),
                    style: AppTextStyles.profileMenuTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (primary)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.chipBg,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Text(
                      AppStrings.trOf(context, 'Primary'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.iconDark,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _detailRow(AppStrings.trOf(context, 'Account number'), _field(row, 'account_number')),
            _detailRow(AppStrings.trOf(context, 'Account holder'), _field(row, 'account_houlder_name')),
            _detailRow(AppStrings.trOf(context, 'IFSC'), _field(row, 'IFSC_code')),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: AppTextStyles.orderRowLabel),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: AppTextStyles.orderRowValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
