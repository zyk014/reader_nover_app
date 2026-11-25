import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/service/content_filter_service.dart';

/// 内容净化页面 — 参考读不舍手风格：简洁、直接
class ContentFilterSettingsPage extends StatefulWidget {
  const ContentFilterSettingsPage({super.key});

  @override
  State<ContentFilterSettingsPage> createState() => _ContentFilterSettingsPageState();
}

class _ContentFilterSettingsPageState extends State<ContentFilterSettingsPage> {
  bool _globalEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ContentFilterService.init();
    setState(() {
      _globalEnabled = ContentFilterService.globalEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final blockedTexts = ContentFilterService.blockedTexts;
    final rules = ContentFilterService.rules;

    return Scaffold(
      appBar: AppBar(
        title: const Text('内容净化'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'preset') {
                await ContentFilterService.loadPresetRules();
                _load();
                Get.snackbar('提示', '预设规则已加载',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green.withValues(alpha: 0.8),
                    colorText: Colors.white);
              } else if (v == 'clear') {
                _showClearConfirm();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'preset', child: Text('加载预设规则')),
              const PopupMenuItem(value: 'clear', child: Text('清空全部')),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          // 总开关
          SwitchListTile(
            title: const Text('内容净化', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('开启后自动过滤正文中的广告和推广内容'),
            value: _globalEnabled,
            onChanged: (v) async {
              await ContentFilterService.setGlobalEnabled(v);
              setState(() => _globalEnabled = v);
            },
          ),
          const Divider(height: 1),

          // 屏蔽文字（长按添加的）
          if (blockedTexts.isNotEmpty) ...[
            _sectionHeader('屏蔽文字', blockedTexts.length),
            ...blockedTexts.map((text) => _buildBlockedItem(text)),
            const Divider(height: 32),
          ],

          // 规则列表
          if (rules.isNotEmpty) ...[
            _sectionHeader('净化规则', rules.where((r) => r.enabled).length),
            ...rules.map((rule) => _buildRuleItem(rule)),
            const Divider(height: 32),
          ],

          // 空状态
          if (blockedTexts.isEmpty && rules.isEmpty)
            _buildEmptyState(),

          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedItem(String text) {
    return Dismissible(
      key: Key('blocked_$text'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ContentFilterService.unblockText(text);
        _load();
      },
      child: ListTile(
        leading: const Icon(Icons.block, size: 18, color: Colors.red),
        title: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
        subtitle: const Text('长按屏蔽的文字', style: TextStyle(fontSize: 10, color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: () async {
            await ContentFilterService.unblockText(text);
            _load();
          },
        ),
      ),
    );
  }

  Widget _buildRuleItem(ContentFilterRule rule) {
    return ListTile(
      leading: Icon(
        rule.enabled ? Icons.check_circle : Icons.circle_outlined,
        size: 20,
        color: rule.enabled ? Colors.green : Colors.grey,
      ),
      title: Text(rule.name, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        rule.pattern,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace'),
      ),
      trailing: Switch(
        value: rule.enabled,
        onChanged: (v) async {
          await ContentFilterService.updateRule(rule.copyWith(enabled: v));
          _load();
        },
      ),
      onLongPress: () => _showEditRuleDialog(rule),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(Icons.shield_outlined, size: 56, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('暂无净化规则', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('点击右下角 + 添加屏蔽文字\n或点击右上角 ⋮ 加载预设规则',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final textController = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('添加屏蔽文字', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('输入要屏蔽的文字，正文中出现这段文字时自动删除',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '例如：请关注微信公众号xxx',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Get.back(), child: const Text('取消')),
                  FilledButton(
                    onPressed: () {
                      final text = textController.text.trim();
                      if (text.isNotEmpty) {
                        _addBlockedText(text);
                      }
                      textController.dispose();
                    },
                    child: const Text('添加'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _addBlockedText(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    Get.back();
    await ContentFilterService.blockText(trimmed);
    _load();
    Get.snackbar('已添加', '"$trimmed" 将在所有章节中屏蔽',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2));
  }

  void _showEditRuleDialog(ContentFilterRule rule) {
    final nameCtrl = TextEditingController(text: rule.name);
    final patternCtrl = TextEditingController(text: rule.pattern);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑规则'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '规则名称')),
            const SizedBox(height: 12),
            TextField(
              controller: patternCtrl,
              decoration: const InputDecoration(labelText: '正则表达式', helperText: '匹配到的内容将被删除'),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ContentFilterService.removeRule(rule.id);
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await ContentFilterService.updateRule(rule.copyWith(
                name: nameCtrl.text.trim(),
                pattern: patternCtrl.text.trim(),
              ));
              Navigator.pop(ctx);
              _load();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空全部'),
        content: const Text('确定清空所有屏蔽文字和净化规则？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              for (final text in ContentFilterService.blockedTexts) {
                await ContentFilterService.unblockText(text);
              }
              for (final rule in ContentFilterService.rules) {
                await ContentFilterService.removeRule(rule.id);
              }
              Navigator.pop(ctx);
              _load();
              Get.snackbar('已清空', '所有净化规则已删除',
                  snackPosition: SnackPosition.BOTTOM);
            },
            child: const Text('确定清空'),
          ),
        ],
      ),
    );
  }
}
