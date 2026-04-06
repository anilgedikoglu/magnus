import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../data/providers.dart';

class CoffeeScreen extends ConsumerStatefulWidget {
  const CoffeeScreen({super.key});

  @override
  ConsumerState<CoffeeScreen> createState() => _CoffeeScreenState();
}

class _CoffeeScreenState extends ConsumerState<CoffeeScreen> {
  final _picker = ImagePicker();
  final List<String?> _photos = [null, null, null]; // 3 photos
  bool _isGenerating = false;

  static const _photoLabels = [
    'Fincanın İçi',
    'Fincanın Dışı',
    'Tabak',
  ];

  static const _photoHints = [
    'Fincanı ters çevirin ve kapağa koyun.\nBiraz bekledikten sonra içini fotoğraflayın.',
    'Fincanın dış yüzeyini fotoğraflayın.',
    'Tabağın üzerindeki kahve izlerini fotoğraflayın.',
  ];

  @override
  Widget build(BuildContext context) {
    final allTaken = _photos.every((p) => p != null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navBarBackground,
        title: const Text('Kahve Falı'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/chat'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInstructions(),
                    const SizedBox(height: 28),
                    for (int i = 0; i < 3; i++) ...[
                      _buildPhotoSlot(i),
                      if (i < 2) const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            _buildSubmitButton(allTaken),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bubble2.first.withValues(alpha: 0.7),
            AppColors.bubble2.last.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.bubbleFrame2.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('☕', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                'Fal için 3 fotoğraf gerekli',
                style: AppTextStyles.inboxTitle,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Kahvenizi içtikten sonra fincanı ters çevirin,\n'
            'soğumasını bekleyin ve üç fotoğraf çekin.',
            style: AppTextStyles.inboxDescription,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot(int index) {
    final photo = _photos[index];
    final hasPhoto = photo != null;

    return GestureDetector(
      onTap: () => _pickPhoto(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 160,
        decoration: BoxDecoration(
          color: hasPhoto
              ? Colors.transparent
              : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPhoto
                ? AppColors.glowGreen.withValues(alpha: 0.7)
                : AppColors.divider,
            width: hasPhoto ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: hasPhoto
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(photo), fit: BoxFit.cover),
                  // Overlay with label
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.75),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: AppColors.glowGreen, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _photoLabels[index],
                            style: AppTextStyles.inboxMeta.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Değiştir',
                            style: AppTextStyles.inboxMeta.copyWith(
                              color: AppColors.navBarActive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.answerBubbleBorder,
                      ),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_rounded,
                      color: AppColors.navBarActive,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${index + 1}. ${_photoLabels[index]}',
                    style: AppTextStyles.inboxTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _photoHints[index],
                      style: AppTextStyles.inboxMeta,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubmitButton(bool allTaken) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.navBarBackground,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: allTaken ? 1.0 : 0.4,
          child: GestureDetector(
            onTap: allTaken && !_isGenerating ? _generateFortune : null,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                gradient: allTaken
                    ? const LinearGradient(
                        colors: AppColors.bubble1,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: allTaken ? null : AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(27),
                boxShadow: allTaken
                    ? [
                        BoxShadow(
                          color: AppColors.bubble1.first.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: _isGenerating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        allTaken
                            ? 'Falımı Yorumla ✨'
                            : '${_photos.where((p) => p != null).length}/3 Fotoğraf Çekildi',
                        style: AppTextStyles.answerText.copyWith(fontSize: 16),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(int index) async {
    final source = await _showPhotoSourceDialog();
    if (source == null) return;

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image == null) return;

    setState(() => _photos[index] = image.path);
  }

  Future<ImageSource?> _showPhotoSourceDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.backgroundSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.navBarActive),
                title: Text('Kamera', style: AppTextStyles.inboxTitle),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.navBarActive),
                title: Text('Galeri', style: AppTextStyles.inboxTitle),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateFortune() async {
    setState(() => _isGenerating = true);

    try {
      final profile = ref.read(userProfileProvider);
      final fortuneService = ref.read(fortuneServiceProvider);

      await fortuneService.init();
      final item = await fortuneService.generateCoffeeFortune(
        profile: profile,
        photoPath1: _photos[0],
        photoPath2: _photos[1],
        photoPath3: _photos[2],
      );

      await ref.read(inboxProvider.notifier).addItem(item);

      if (!mounted) return;
      // Show success, navigate to inbox
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kahve falın inbox\'a eklendi! ☕',
            style: AppTextStyles.inboxDescription,
          ),
          backgroundColor: AppColors.backgroundSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      context.go('/inbox');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}
