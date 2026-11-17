import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/enums/feedback_type.dart';
import 'package:period_tracker/exceptions/feedback_exception.dart';
import 'package:period_tracker/services/feedback_service.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/app_sheet.dart';
import 'package:period_tracker/widgets/large_title_scaffold.dart';
import 'package:period_tracker/widgets/primary_button.dart';
import 'package:period_tracker/widgets/segmented_control.dart';

/// Optional context passed when opening the feedback page from an error screen.
class FeedbackArgs {
  final FeedbackType type;
  final String? errorCode;
  final Object? error;
  final Object? sharedFileContent; // String or decoded JSON
  const FeedbackArgs({this.type = FeedbackType.feedback, this.errorCode, this.error, this.sharedFileContent});
}

class FeedbackPage extends StatefulWidget {
  final FeedbackArgs args;
  const FeedbackPage({super.key, this.args = const FeedbackArgs()});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  late FeedbackType _type = widget.args.type;
  final TextEditingController _message = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _message.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _message.dispose();
    _contact.dispose();
    super.dispose();
  }

  bool get _canSend => !_sending && (_message.text.trim().isNotEmpty || widget.args.errorCode != null);

  String get _hint => switch (_type) {
    FeedbackType.feedback => 'Tell me what you think about the app.',
    FeedbackType.featureRequest => 'What would you like to see in the app?',
    FeedbackType.bugReport => 'What went wrong? What did you expect to happen?',
  };

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      await FeedbackService.send(
        _type,
        _message.text.trim(),
        contact: _contact.text.trim(),
        errorCode: widget.args.errorCode,
        error: widget.args.error,
        sharedFileContent: widget.args.sharedFileContent,
      );
      if (!mounted) return;
      await showInfo(context: context, title: 'Thank you!', message: 'Your ${_type.label.toLowerCase()} was sent.');
      if (!mounted) return;
      context.pop();
    } on FeedbackException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showInfo(
        context: context,
        title: 'Could not send',
        message: switch (e.errorCode) {
          kNetworkErrorCode => 'Check your internet connection and try again.',
          kFeedbackNotConfiguredErrorCode => 'Sending is not set up in this build of the app.',
          _ => 'Something went wrong while sending. Please try again later.',
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      showInfo(context: context, title: 'Could not send', message: 'Something went wrong while sending. Please try again later.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LargeTitleScaffold(
      title: 'Feedback',
      largeTitle: false,
      bottom: PrimaryButton(label: _sending ? 'Sending…' : 'Send', onPressed: _canSend ? _send : null),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              SegmentedControl<FeedbackType>(
                options: [for (final FeedbackType t in FeedbackType.values) SegmentOption(value: t, label: t.label.split(' ').first)],
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(_type.label, style: context.text.titleSmall?.copyWith(color: c.labelSecondary)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _message,
                enabled: !_sending,
                minLines: 6,
                maxLines: 12,
                maxLength: 3000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(hintText: _hint),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contact,
                enabled: !_sending,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Email (optional, if you want a reply)'),
              ),
              if (_type.includesAppData)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                  child: Text(
                    'Your app version, device info and app data are sent along to help diagnose issues.',
                    style: context.text.bodySmall?.copyWith(color: c.labelSecondary),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}
