class Fonts {
  // 系统字体（苹方）
  static const String? system = null;

  // 汉仪细行楷（项目内置）
  static const String xiXingKai = '细行楷';

  // iOS 系统自带中文字体
  static const String songti = 'Songti SC';       // 宋体
  static const String kaiti = 'Kaiti SC';          // 楷体
  static const String heiti = 'Heiti SC';          // 黑体
  static const String fangsong = 'STFangsong';     // 仿宋
  static const String yuanti = 'Yuanti SC';        // 圆体
  static const String baoli = 'Baoli SC';          // 宝丽体
  static const String libian = 'Libian SC';        // 隶变体

  /// 获取所有可用字体列表
  static List<Map<String, String?>> get availableFonts => [
    {'name': '系统字体', 'family': system},
    {'name': '宋体', 'family': songti},
    {'name': '楷体', 'family': kaiti},
    {'name': '黑体', 'family': heiti},
    {'name': '仿宋', 'family': fangsong},
    {'name': '圆体', 'family': yuanti},
    {'name': '汉仪细行楷', 'family': xiXingKai},
  ];

  /// 获取字体显示名称
  static String getDisplayName(String? fontFamily) {
    if (fontFamily == null || fontFamily.isEmpty) return '系统字体';
    switch (fontFamily) {
      case songti:
        return '宋体';
      case kaiti:
        return '楷体';
      case heiti:
        return '黑体';
      case fangsong:
        return '仿宋';
      case yuanti:
        return '圆体';
      case xiXingKai:
        return '细行楷';
      default:
        return fontFamily;
    }
  }
}
