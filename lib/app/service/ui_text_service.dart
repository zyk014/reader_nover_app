import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// UI 文字自定义服务 — 用户可自定义 App 界面的文字标签
class UITextService {
  static const _prefKey = 'ui_text_overrides';

  /// 所有可自定义的界面文字（key -> 默认值）
  static const Map<String, String> defaults = {
    // 底部导航栏
    'tab_bookshelf': '书架',
    'tab_bookstore': '书城',
    'tab_booksource': '书源',
    'tab_setting': '设置',
    // 页面标题
    'title_bookstore': '书城',
    'title_content_filter': '内容净化',
    'title_source_manage': '书源管理',
    // 阅读界面底部按钮
    'reader_prev_chapter': '上一章',
    'reader_next_chapter': '下一章',
    'reader_directory': '目录',
    'reader_settings': '设置',
    'reader_more_settings': '更多设置',
    // 书源菜单
    'menu_import': '导入书源',
    'menu_url_import': '网址导入',
    'menu_qr_import': '扫码导入',
    'menu_auto_check': '检测清理无效书源',
    'menu_export': '导出书源',
    'menu_check_config': '校验设置',
    'menu_group_manage': '分组管理',
    'menu_refresh': '刷新书源',
    // 内容净化
    'filter_title': '内容净化',
    'filter_enable': '启用内容净化',
    'filter_block_button': '屏蔽此内容',
    // 书架
    'shelf_empty_title': '书架还是空的',
    'shelf_empty_sub': '搜索网络书籍、逛逛书城，或导入本地 txt',
  };

  static Map<String, String> _overrides = {};

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        _overrides = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {
        _overrides = {};
      }
    }
  }

  /// 获取文字：优先用自定义值，没有就用默认值
  static String t(String key) {
    return _overrides[key] ?? defaults[key] ?? key;
  }

  /// 获取当前所有文字（自定义+默认合并）
  static Map<String, String> getAll() {
    return {...defaults, ..._overrides};
  }

  /// 设置自定义文字
  static Future<void> set(String key, String value) async {
    if (value.trim().isEmpty || value.trim() == defaults[key]) {
      _overrides.remove(key);
    } else {
      _overrides[key] = value.trim();
    }
    await _save();
  }

  /// 重置为默认
  static Future<void> reset(String key) async {
    _overrides.remove(key);
    await _save();
  }

  /// 重置全部
  static Future<void> resetAll() async {
    _overrides.clear();
    await _save();
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(_overrides));
  }
}
