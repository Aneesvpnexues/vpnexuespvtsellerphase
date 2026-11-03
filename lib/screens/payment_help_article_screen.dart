import 'package:flutter/material.dart';

import 'help_article_screen.dart';

/// Article "When will I get paid?" - Zeplin "Android Compact - 214".
class PayoutTimingHelpScreen extends StatelessWidget {
  const PayoutTimingHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpArticleScreen(
      header: 'Payments & wallet',
      title: 'When will I get paid?',
      intro:
          'Payouts are released after an order is delivered and the return '
          'window closes.',
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: 'Payout schedule',
          body:
              'Delivered orders settle in 3 to 5 working days, excluding '
              'Sundays and bank holidays.',
        ),
        HelpArticleSection(
          title: 'Check your balance',
          body:
              'Open Wallet & Transactions to see available and pending '
              'amounts.',
        ),
        HelpArticleSection(
          title: 'Payout on hold',
          body:
              'A hold clears automatically once the order is completed or a '
              'dispute is resolved.',
        ),
      ],
    );
  }
}

/// Article "How do I withdraw money?" - Zeplin "Android Compact - 215".
class WithdrawMoneyHelpScreen extends StatelessWidget {
  const WithdrawMoneyHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpArticleScreen(
      header: 'Payments & wallet',
      title: 'How do I withdraw money?',
      intro:
          'Move your available balance to the bank account saved in your '
          'profile.',
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: 'Check the balance',
          body:
              'Open Wallet & Transactions. Only the available balance can be '
              'withdrawn.',
        ),
        HelpArticleSection(
          title: 'Start a withdrawal',
          body: 'Tap Withdraw, enter the amount and choose your bank account.',
        ),
        HelpArticleSection(
          title: 'Confirm the transfer',
          body:
              'Withdrawals usually reach your bank within 1 to 2 working '
              'days.',
        ),
      ],
    );
  }
}

/// Article "Why is my withdrawal pending?" - Zeplin "Android Compact - 216".
class WithdrawalPendingHelpScreen extends StatelessWidget {
  const WithdrawalPendingHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpArticleScreen(
      header: 'Payments & wallet',
      title: 'Why is my withdrawal pending?',
      intro:
          'A withdrawal can stay pending if your bank details are incomplete '
          'or the transfer is under review.',
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: 'Check your bank details',
          body:
              'Open Bank Details and make sure the account number and IFSC '
              'are correct.',
        ),
        HelpArticleSection(
          title: 'Wait for the transfer',
          body:
              'Bank transfers can take 1 to 2 working days after the request '
              'is approved.',
        ),
        HelpArticleSection(
          title: 'Still pending?',
          body:
              'Contact support with the withdrawal date and amount so we can '
              'trace it.',
        ),
      ],
    );
  }
}
