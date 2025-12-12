import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/entities/asset.entity.dart';
import 'package:immich_mobile/extensions/build_context_extensions.dart';
import 'package:immich_mobile/providers/asset.provider.dart';
import 'package:immich_mobile/providers/search/recently_taken_asset.provider.dart';
import 'package:immich_mobile/widgets/common/immich_image.dart';
import 'package:immich_mobile/widgets/common/immich_loading_indicator.dart';

@RoutePage()
class SwipeReviewPage extends HookConsumerWidget {
  const SwipeReviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentlyTakenAssetProvider);
    final queue = useState<List<Asset>>([]);
    final totalCount = useState<int>(0);
    final isProcessing = useState(false);

    useEffect(() {
      final assets = recents.valueOrNull;
      if (assets != null) {
        queue.value = List.of(assets);
        totalCount.value = assets.length;
      }
      return null;
    }, [recents.valueOrNull]);

    Future<void> skipAsset() async {
      if (queue.value.isEmpty) return;
      queue.value = queue.value.sublist(1);
    }

    Future<bool> deleteAsset() async {
      if (queue.value.isEmpty) return false;
      isProcessing.value = true;
      final asset = queue.value.first;
      final success = await ref.read(assetProvider.notifier).deleteAssets({asset});
      isProcessing.value = false;

      if (success) {
        queue.value = queue.value.sublist(1);
      } else {
        context.showSnackBar(
          SnackBar(content: const Text('unable_to_delete_asset').tr()),
        );
      }

      return success;
    }

    Widget buildCard(Asset asset) {
      final remaining = queue.value.length;
      final currentIndex = totalCount.value - remaining + 1;
      final progressText = remaining > 0 && totalCount.value > 0
          ? 'review_swipe_progress'.tr(namedArgs: {
              'current': currentIndex.toString(),
              'total': totalCount.value.toString(),
            })
          : '';

      return Dismissible(
        key: ValueKey(asset.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart) {
            return deleteAsset();
          }
          await skipAsset();
          return true;
        },
        background: _SwipeBackground(
          alignment: Alignment.centerLeft,
          color: context.colorScheme.secondaryContainer,
          icon: Icons.check_circle_rounded,
          label: 'review_swipe_keep'.tr(),
          padding: const EdgeInsets.only(left: 24),
        ),
        secondaryBackground: _SwipeBackground(
          alignment: Alignment.centerRight,
          color: context.colorScheme.errorContainer,
          icon: Icons.delete_rounded,
          label: 'review_swipe_delete'.tr(),
          padding: const EdgeInsets.only(right: 24),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ColoredBox(
                  color: context.colorScheme.surfaceVariant.withAlpha(60),
                  child: ImmichImage(
                    asset,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              progressText,
              style: context.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isProcessing.value ? null : skipAsset,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('review_swipe_keep').tr(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colorScheme.errorContainer,
                      foregroundColor: context.colorScheme.onErrorContainer,
                    ),
                    onPressed: isProcessing.value ? null : deleteAsset,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('review_swipe_delete').tr(),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('review_swipe_title').tr(),
        leading: IconButton(
          onPressed: () => context.maybePop(),
          icon: const Icon(Icons.arrow_back_ios_rounded),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: recents.when(
          data: (assets) {
            if (assets.isEmpty) {
              return _EmptyState(message: 'review_swipe_empty'.tr());
            }

            if (queue.value.isEmpty) {
              return _EmptyState(message: 'memories_all_caught_up'.tr());
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'review_swipe_description'.tr(),
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium,
                  ),
                ),
                Expanded(child: buildCard(queue.value.first)),
              ],
            );
          },
          loading: () => const Center(child: ImmichLoadingIndicator()),
          error: (_, __) => _EmptyState(message: 'error'.tr()),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.burst_mode_outlined,
            size: 64,
            color: context.colorScheme.onSurface.withOpacity(0.45),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: context.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
    required this.padding,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Align(
        alignment: alignment,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: alignment == Alignment.centerLeft
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Icon(icon, size: 32, color: context.colorScheme.onSecondaryContainer),
            const SizedBox(height: 8),
            Text(
              label,
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
