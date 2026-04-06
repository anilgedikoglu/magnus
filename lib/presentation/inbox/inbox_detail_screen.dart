import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/models/inbox_item.dart';

/// Fal metninin tamamını gösteren detay ekranı.
/// Unity'deki PanelShowWholeTextManager karşılığı.
class InboxDetailScreen extends StatelessWidget {
  final InboxItem item;

  const InboxDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navBarBackground,
        title: Text(item.fortuneTypeLabel),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photos for coffee fortune
            if (_hasPhotos) _buildPhotos(context),
            // Fortune text
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + date
                  Text(item.title, style: AppTextStyles.title),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(item.date),
                    style: AppTextStyles.inboxMeta,
                  ),
                  const SizedBox(height: 24),
                  // Decorative divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.bubble1.first.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '✦',
                          style: TextStyle(
                            color: AppColors.bubble1.first,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.bubble1.first.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Fortune text
                  SelectableText(
                    item.text,
                    style: AppTextStyles.bubbleText.copyWith(
                      height: 1.8,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Footer
                  Center(
                    child: Text(
                      '✦ Magnus ✦',
                      style: AppTextStyles.magnusLabel,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasPhotos =>
      item.photoPath1 != null ||
      item.photoPath2 != null ||
      item.photoPath3 != null;

  Widget _buildPhotos(BuildContext context) {
    final photos = [item.photoPath1, item.photoPath2, item.photoPath3]
        .whereType<String>()
        .toList();

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _viewPhoto(context, photos[i]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(photos[i]),
              width: 148,
              height: 148,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  void _viewPhoto(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
        'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}
