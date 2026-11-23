import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 全局内容过滤规则
class ContentFilterRule {
  final String id;
  final String name;
  final String pattern;
  final String replacement;
  final bool enabled;

  ContentFilterRule({
    required this.id,
    required this.name,
    required this.pattern,
    this.replacement = '',
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pattern': pattern,
        'replacement': replacement,
        'enabled': enabled,
      };

  factory ContentFilterRule.fromJson(Map<String, dynamic> json) =>
      ContentFilterRule(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        pattern: json['pattern'] as String? ?? '',
        replacement: json['replacement'] as String? ?? '',
        enabled: json['enabled'] as bool? ?? true,
      );

  ContentFilterRule copyWith({
    String? name,
    String? pattern,
    String? replacement,
    bool? enabled,
  }) =>
      ContentFilterRule(
        id: id,
        name: name ?? this.name,
        pattern: pattern ?? this.pattern,
        replacement: replacement ?? this.replacement,
        enabled: enabled ?? this.enabled,
      );
}

/// 全局内容净化服务 — 对所有书源的正文统一应用正则过滤
class ContentFilterService {
  static const _prefKey = 'global_content_filter_rules';
  static const _enabledKey = 'global_content_filter_enabled';
  static List<ContentFilterRule> _cache = [];
  static bool _globalEnabled = true;

  /// 预设常见广告过滤规则
  static List<ContentFilterRule> presetRules() => [
        ContentFilterRule(
          id: 'preset_1',
          name: '过滤"本章未完"提示',
          pattern: r'本章未完.*?继续阅读',
          replacement: '',
        ),
        ContentFilterRule(
          id: 'preset_2',
          name: '过滤"请收藏"推广',
          pattern: r'请收藏.*?网址',
          replacement: '',
        ),
        ContentFilterRule(
          id: 'preset_3',
          name: '过滤"第一小说网"等站名推广',
          pattern: r'(第一小说网|笔趣阁|八壹中文网|看书神器|顶点小说|八一中文|八一中文网).*?(com|net|org)',
          replacement: '',
        ),
        ContentFilterRule(
          id: 'preset_4',
          name: '过滤纯网址行',
          pattern: r'^https?://\S+$',
          replacement: '',
        ),
        ContentFilterRule(
          id: 'preset_5',
          name: '过滤"百度搜索"推广',
          pattern: r'百度搜索.*?关键词',
          replacement: '',
        ),
        ContentFilterRule(
          id: 'preset_6',
          name: '过滤"作者的话/ PS"段落',
          pattern: r'(PS[:：]|作者的话[:：]|作者说[:：]).*',
          replacement: '',
        ),
        ContentFilterRule(
          id: 'preset_7',
          name: '过滤"求月票/推荐票"',
          pattern: r'(求月票|求推荐票|求票|投月票|投推荐票).*',
          replacement: '',
        ),
        ContentFilterRule(
          id: 'preset_8',
          name: '过滤"关注微信公众号"',
          pattern: r'(关注.*?微信.*?公众号|扫码.*?关注|微信搜索.*?关注).*',
          replacement: '',
        ),
      ];

  /// 从 SharedPreferences 加载规则
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _globalEnabled = prefs.getBool(_enabledKey) ?? true;
    final jsonStr = prefs.getString(_prefKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final list = jsonDecode(jsonStr) as List;
        _cache = list
            .map((e) => ContentFilterRule.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cache = [];
      }
    }
  }

  static List<ContentFilterRule> get rules => List.unmodifiable(_cache);
  static bool get globalEnabled => _globalEnabled;

  static Future<void> setGlobalEnabled(bool enabled) async {
    _globalEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }

  static Future<void> addRule(ContentFilterRule rule) async {
    _cache.add(rule);
    await _save();
  }

  static Future<void> updateRule(ContentFilterRule rule) async {
    final idx = _cache.indexWhere((r) => r.id == rule.id);
    if (idx >= 0) {
      _cache[idx] = rule;
      await _save();
    }
  }

  static Future<void> removeRule(String id) async {
    _cache.removeWhere((r) => r.id == id);
    await _save();
  }

  static Future<void> loadPresetRules() async {
    final existingIds = _cache.map((r) => r.id).toSet();
    for (final preset in presetRules()) {
      if (!existingIds.contains(preset.id)) {
        _cache.add(preset);
      }
    }
    await _save();
  }

  static Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, jsonEncode(_cache.map((r) => r.toJson()).toList()));
  }

  /// 对正文应用所有启用的过滤规则
  static String applyFilters(String content) {
    if (!_globalEnabled || content.isEmpty) return content;
    String result = content;
    for (final rule in _cache) {
      if (!rule.enabled || rule.pattern.isEmpty) continue;
      try {
        final regex = RegExp(rule.pattern, multiLine: true);
        result = result.replaceAll(regex, rule.replacement);
      } catch (_) {
        // 无效正则跳过
      }
    }
    // 清理过滤后产生的多余空行
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return result.trim();
  }
}
