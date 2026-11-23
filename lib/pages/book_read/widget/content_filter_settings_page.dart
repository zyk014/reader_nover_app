import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/service/content_filter_service.dart';
import '../../../util/color_utils.dart';

class ContentFilterSettingsPage extends StatefulWidget {
  const ContentFilterSettingsPage({super.key});

  @override
  State<ContentFilterSettingsPage> createState() => _ContentFilterSettingsPageState();
}

class _ContentFilterSettingsPageState extends State<ContentFilterSettingsPage> {
  List<ContentFilterRule> _rules = [];
  bool _globalEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await ContentFilterService.init();
    setState(() {
      _rules = ContentFilterService.rules;
      _globalEnabled = ContentFilterService.globalEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('内容净化'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEditDialog(context, null),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'preset') _loadPresets();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'preset', child: Text('加载预设规则')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 全局开关
          SwitchListTile(
            title: const Text('启用内容净化'),
            subtitle: const Text('对所有书源的正文应用正则过滤'),
            value: _globalEnabled,
            onChanged: (v) async {
              await ContentFilterService.setGlobalEnabled(v);
              setState(() => _globalEnabled = v);
            },
          ),
          const Divider(height: 1),
          // 规则列表
          Expanded(
            child: _rules.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        const Text('暂无过滤规则', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _loadPresets,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('加载预设规则'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _rules.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final rule = _rules[index];
                      return ListTile(
                        title: Text(rule.name),
                        subtitle: Text(
                          rule.pattern,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: rule.enabled,
                              onChanged: (v) async {
                                await ContentFilterService.updateRule(
                                  rule.copyWith(enabled: v),
                                );
                                _loadData();
                              },
                            ),
                            PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _showEditDialog(context, rule);
                                } else if (action == 'delete') {
                                  ContentFilterService.removeRule(rule.id);
                                  _loadData();
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('编辑')),
                                const PopupMenuItem(value: 'delete', child: Text('删除')),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPresets() async {
    await ContentFilterService.loadPresetRules();
    _loadData();
    Get.snackbar('提示', '预设规则已加载', snackPosition: SnackPosition.BOTTOM);
  }

  void _showEditDialog(BuildContext context, ContentFilterRule? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final patternCtrl = TextEditingController(text: existing?.pattern ?? '');
    final replacementCtrl = TextEditingController(text: existing?.replacement ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? '添加过滤规则' : '编辑规则'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '规则名称',
                  hintText: '如：过滤广告链接',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: patternCtrl,
                decoration: const InputDecoration(
                  labelText: '正则表达式',
                  hintText: '如：https?://\\S+',
                  helperText: '匹配到的内容将被替换',
                ),
                style: const TextStyle(fontFamily: 'monospace'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: replacementCtrl,
                decoration: const InputDecoration(
                  labelText: '替换为（留空=删除）',
                  hintText: '如：（可留空）',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              if (patternCtrl.text.trim().isEmpty) return;
              final rule = ContentFilterRule(
                id: existing?.id ?? 'rule_${DateTime.now().millisecondsSinceEpoch}',
                name: nameCtrl.text.trim().isEmpty ? '未命名规则' : nameCtrl.text.trim(),
                pattern: patternCtrl.text.trim(),
                replacement: replacementCtrl.text.trim(),
                enabled: existing?.enabled ?? true,
              );
              if (existing == null) {
                await ContentFilterService.addRule(rule);
              } else {
                await ContentFilterService.updateRule(rule);
              }
              Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
