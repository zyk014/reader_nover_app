import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/l10n/generated/l10n.dart';
import '../../../util/color_utils.dart';
import '../state.dart';

enum BookReadParagraphAction { cancel, tts, highlight, underline, note, block }

class BookReadParagraphActionResult {
  const BookReadParagraphActionResult({required this.action});

  final BookReadParagraphAction action;
  bool get start => action == BookReadParagraphAction.tts;
}

class BookReadParagraphActionSheet extends StatelessWidget {
  const BookReadParagraphActionSheet({
    super.key,
    required this.state,
    required this.previewText,
  });

  final BookReadState state;
  final String previewText;

  static Future<BookReadParagraphActionResult?> show(
    BuildContext context, {
    required BookReadState state,
    required String previewText,
  }) =>
      Get.dialog<BookReadParagraphActionResult>(
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: 1,
            child: BookReadParagraphActionSheet(
              state: state,
              previewText: previewText,
            ),
          ),
        ),
        barrierColor: Colors.black26,
        useSafeArea: false,
      );

  @override
  Widget build(BuildContext context) {
    final textColor = ColorUtils.getContrastTextColor(state.backgroundColor);
    return Material(
      color: state.backgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('"$previewText"',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _action(context, Icons.block_outlined, '屏蔽此内容',
                  BookReadParagraphAction.block),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String label,
      BookReadParagraphAction action) {
    return OutlinedButton.icon(
      onPressed: () =>
          Get.back(result: BookReadParagraphActionResult(action: action)),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
