import 'package:flutter/material.dart';

/// Anti-bot honeypot field widget.
/// Legitimate users cannot see, focus, or interact with this field (leaving it blank).
/// Automated bot scripts, auto-fillers, and crawlers populate form inputs, triggering backend rejection.
class BotTrapField extends StatelessWidget {
  final TextEditingController? controller;

  const BotTrapField({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: true,
      child: IgnorePointer(
        ignoring: true,
        child: Opacity(
          opacity: 0.0,
          child: SizedBox(
            width: 0.0,
            height: 0.0,
            child: TextField(
              controller: controller,
              readOnly: false,
              focusNode: FocusNode(skipTraversal: true),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: 'botTrap',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
