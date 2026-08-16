import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wallet/l10n/app_localizations.dart';

class ImagePickerWidget extends StatelessWidget {
  final String title;
  final File? imageFile;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  /// 当图片已添加时，点击图片预览区触发（通常用于跳全屏查看）。
  final VoidCallback? onPreviewImage;

  const ImagePickerWidget({
    super.key,
    required this.title,
    this.imageFile,
    required this.onPickImage,
    required this.onRemoveImage,
    this.onPreviewImage,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 12.0, top: 12.0),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        // 无论是否已添加图片，主容器固定高 150，宽度填满父级约束。
        // 保证"未添加状态（按钮）"和"已添加状态（图片）"在布局上
        // 大小、位置完全一致（左右并排显示时不会跳动）。
        SizedBox(
          height: 150,
          width: double.infinity,
          child: imageFile == null
              ? OutlinedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(l.selectImage),
                  style: OutlinedButton.styleFrom(
                    // 填满 SizedBox（高度 150 + 宽度无限），这样左右两个
                    // 选择按钮大小、位置与图片预览完全一致。
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.502),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: onPickImage,
                )
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onPreviewImage,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            imageFile!,
                            fit: BoxFit.cover,
                            cacheWidth: 500,
                            cacheHeight: 300,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 16,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: onRemoveImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
