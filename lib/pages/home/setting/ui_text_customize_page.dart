import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/service/ui_text_service.dart';

class UITextCustomizePage extends StatefulWidget {
  const UITextCustomizePage({super.key});

  @override
  State<UITextCustomizePage> createState() => _UITextCustomizePageState();
}

class _UITextCustomizePageState extends State<UITextCustomizePage> {
  Map<String, String> _texts = {};
  final _controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _texts = UITextService.getAll();
    for (final entry in _texts.entries) {
      _controllers[entry.key]?.dispose();
      _controllers[entry.key] = TextEditingController(text: entry.value);
    }
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Group by category
    final categories = <String, List<String>>{
      '底部导航栏': ['tab_bookshelf', 'tab_bookstore', 'tab_booksource', 'tab_setting'],
      '页面标题': ['title_bookstore', 'title_content_filter', 'title_source_manage'],
      '阅读界面': ['reader_prev_chapter', 'reader_next_chapter', 'reader_directory', 'reader_settings', 'reader_more_settings'],
      '书源菜单': ['menu_import', 'menu_url_import', 'menu_qr_import', 'menu_auto_check', 'menu_export', 'menu_check_config', 'menu_group_manage', 'menu_refresh'],
      '内容净化': ['filter_title', 'filter_enable', 'filter_block_button'],
      '书架': ['shelf_empty_title', 'shelf_empty_sub'],
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('界面文字自定义'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '全部重置',
            onPressed: () async {
              await UITextService.resetAll();
              _loadData();
              Get.snackbar('已重置', '所有文字恢复默认', snackPosition: SnackPosition.BOTTOM);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '修改后立即生效。留空或与默认值相同则使用默认文字。',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...categories.entries.expand((entry) => [
            _buildCategoryHeader(entry.key),
            ...entry.value.map((key) => _buildTextItem(key)),
            const SizedBox(height: 16),
          ]),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildTextItem(String key) {
    final controller = _controllers[key];
    if (controller == null) return const SizedBox.shrink();
    final defaultValue = UITextService.defaults[key] ?? '';
    final isCustom = controller.text != defaultValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                defaultValue,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (isCustom) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text('已修改', style: TextStyle(fontSize: 9, color: Colors.green)),
                ),
              ],
              const Spacer(),
              if (isCustom)
                GestureDetector(
                  onTap: () async {
                    await UITextService.reset(key);
                    _loadData();
                  },
                  child: const Text('恢复', style: TextStyle(fontSize: 11, color: Colors.blue)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: IconButton(
                icon: const Icon(Icons.check, size: 18),
                onPressed: () async {
                  await UITextService.set(key, controller.text);
                  _loadData();
                  Get.snackbar('已保存', '文字已更新', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 1));
                },
              ),
            ),
            style: const TextStyle(fontSize: 14),
            onSubmitted: (value) async {
              await UITextService.set(key, value);
              _loadData();
            },
          ),
        ],
      ),
    );
  }
}
