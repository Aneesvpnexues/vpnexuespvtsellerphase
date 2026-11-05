import 'package:flutter/material.dart';

import 'help_article_screen.dart';

/// Article "How do I verify my account?" - Zeplin "Android Compact - 218".
class VerifyAccountHelpScreen extends StatelessWidget {
  const VerifyAccountHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpArticleScreen(
      header: 'Account & verification',
      title: 'How do I verify my account?',
      intro:
          'Verify your identity once to unlock payouts and build trust with '
          'buyers.',
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: 'Open Verification',
          body:
              'Go to Profile, then tap Verification to start or continue your '
              'KYC.',
        ),
        HelpArticleSection(
          title: 'Upload your documents',
          body:
              'Add a clear photo of your Aadhaar card and PAN card. Names '
              'must match your profile.',
        ),
        HelpArticleSection(
          title: 'Wait for review',
          body: 'Verification is usually completed within 24 to 48 hours.',
        ),
      ],
    );
  }
}

/// Article "Why was my verification rejected?" - Zeplin "Android Compact - 219".
class VerificationRejectedHelpScreen extends StatelessWidget {
  const VerificationRejectedHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpArticleScreen(
      header: 'Account & verification',
      title: 'Why was my verification rejected?',
      intro:
          'A rejection usually means a document is unclear, expired or does '
          'not match your details.',
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: 'Check the reason',
          body: 'Open Verification to see which document needs attention.',
        ),
        HelpArticleSection(
          title: 'Upload it again',
          body:
              'Use a well-lit photo, keep all corners visible and avoid '
              'glare or blur.',
        ),
        HelpArticleSection(
          title: 'Still rejected?',
          body:
              'Contact support with your registered phone number so we can '
              'review it.',
        ),
      ],
    );
  }
}

/// Article "How do I update my business details?" - Zeplin
/// "Android Compact - 220".
class UpdateBusinessDetailsHelpScreen extends StatelessWidget {
  const UpdateBusinessDetailsHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HelpArticleScreen(
      header: 'Account & verification',
      title: 'How do I update my business details?',
      intro:
          'Keep your business and farm details current so orders and payouts '
          'are not affected.',
      sections: <HelpArticleSection>[
        HelpArticleSection(
          title: 'Open Business & Farm',
          body: 'Go to Profile and tap Business & Farm to edit your details.',
        ),
        HelpArticleSection(
          title: 'Update the details',
          body:
              'Change the business name, address or farm size and tap Save '
              'changes.',
        ),
        HelpArticleSection(
          title: 'Re-verification',
          body:
              'Some changes need a fresh check. We will notify you if '
              'documents are required.',
        ),
      ],
    );
  }
}
