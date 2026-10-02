import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/localization.dart';
import '../models/document_model.dart';
import '../services/storage_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/likh_components.dart';
import 'document_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String language;

  const HistoryScreen({
    super.key,
    required this.language,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DocumentModel> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final docs = await StorageService.getDocuments();
    if (mounted) {
      setState(() {
        _historyItems = docs;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocale.text(widget.language, 'Clear History', 'इतिहास साफ़ करें')),
        content: Text(
          AppLocale.text(
            widget.language,
            'Are you sure you want to clear all document history?',
            'क्या आप वास्तव में सभी दस्तावेज़ इतिहास को साफ़ करना चाहते हैं?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocale.text(widget.language, 'Cancel', 'रद्द करें')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(AppLocale.text(widget.language, 'Clear All', 'सब साफ़ करें')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAll();
      _loadHistory();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocale.text(widget.language, 'History', 'इतिहास'),
        ),
        actions: [
          if (_historyItems.isNotEmpty)
            IconButton(
              tooltip: AppLocale.text(widget.language, 'Clear All', 'सब साफ़ करें'),
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historyItems.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: EmptyState(
                            icon: Icons.history_rounded,
                            title: AppLocale.text(
                              widget.language,
                              'No Conversion History',
                              'कोई रूपांतरण इतिहास नहीं',
                            ),
                            message: AppLocale.text(
                              widget.language,
                              'Your digitized handwriting notes and scanned documents will be logged here.',
                              'आपके डिजिटाइज़ किए गए हस्तलिखित नोट्स और स्कैन किए गए दस्तावेज़ यहाँ लॉग किए जाएंगे।',
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadHistory,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          itemCount: _historyItems.length,
                          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = _historyItems[index];
                            final confColor = item.confidence >= 0.88
                                ? AppColors.success
                                : (item.confidence >= 0.70 ? AppColors.primary : AppColors.warning);
                            final confLabel = item.confidence >= 0.88
                                ? 'High Accuracy'
                                : (item.confidence >= 0.70 ? 'Digitized' : 'Review Needed');

                            return LikhCard(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DocumentDetailScreen(
                                      document: item,
                                      language: widget.language,
                                    ),
                                  ),
                                ).then((_) => _loadHistory());
                              },
                              padding: const EdgeInsets.all(16),
                              borderRadius: 18,
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: confColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(13),
                                      border: Border.all(
                                        color: confColor.withAlpha(50),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: confColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppColors.textDark : AppColors.textLight,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              _formatDate(item.createdAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            LikhBadge(
                                              label: confLabel,
                                              fontSize: 9,
                                              color: confColor,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ),
      ),
    );
  }
}
