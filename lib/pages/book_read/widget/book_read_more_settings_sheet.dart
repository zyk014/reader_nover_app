import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../util/color_utils.dart';
import '../controllers/book_read_ui_refresh_controller.dart';
import '../logic.dart';
import '../state.dart';
import 'book_read_tts_settings_sheet.dart';
import 'content_filter_settings_page.dart';

class BookReadMoreSettingsSheet extends StatelessWidget {
  const BookReadMoreSettingsSheet(
      {super.key, required this.logic, required this.state});

  final BookReadLogic logic;
  final BookReadState state;

  static void show(
      BuildContext context, BookReadLogic logic, BookReadState state) {
    Get.dialog(
      Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          widthFactor: 1,
          child: BookReadMoreSettingsSheet(logic: logic, state: state),
        ),
      ),
      barrierColor: Colors.black54,
      useSafeArea: false,
    );
  }

  @override
  Widget build(BuildContext context) => GetBuilder<BookReadLogic>(
        init: logic,
        global: false,
        id: BookReadUiRefreshController.overlayUpdateId,
        builder: (_) {
          final textColor =
              ColorUtils.getContrastTextColor(state.backgroundColor);
          return Material(
            color: state.backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _slider('语速', state.ttsRate, 0.1, 1.0, logic.updateTtsRate,
                      textColor),
                  _slider('音量', state.ttsVolume, 0.0, 1.0,
                      logic.updateTtsVolume, textColor),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.record_voice_over_outlined,
                        color: textColor),
                    title: Text('系统发音人', style: TextStyle(color: textColor)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        BookReadTtsSettingsSheet.show(context, logic, state),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.filter_alt_outlined, color: textColor),
                    title: Text('内容净化', style: TextStyle(color: textColor)),
                    subtitle: Text('正则过滤广告/推广内容', style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.back();
                      Get.to(() => const ContentFilterSettingsPage());
                    },
                  ),
                ]),
              ),
            ),
          );
        },
      );

  Widget _slider(String label, double value, double min, double max,
      ValueChanged<double> onChanged, Color color) {
    return Row(children: [
      SizedBox(width: 44, child: Text(label, style: TextStyle(color: color))),
      Expanded(
          child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged)),
      SizedBox(
          width: 36,
          child:
              Text(value.toStringAsFixed(1), style: TextStyle(color: color))),
    ]);
  }
}
