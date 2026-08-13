import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../domain/ustaz.dart';
import '../domain/video_item.dart';
import '../providers/ustaz_providers.dart';
import 'video_list_screen.dart';

class UstazVideosScreen extends ConsumerWidget {
  final Ustaz ustaz;

  const UstazVideosScreen({super.key, required this.ustaz});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final videosAsync = ref.watch(paginatedVideosProvider(ustaz));
    final notifier = ref.read(paginatedVideosProvider(ustaz).notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!notifier.isLoadingMore &&
              notifier.hasMore &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
            notifier.fetchNextBatch();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context, isDark),
            videosAsync.when(
              data: (videos) => videos.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _VideoState(
                        icon: Icons.video_library_outlined,
                        title: 'No videos available',
                        message: 'New public lectures will appear here.',
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == videos.length) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(
                                    color: AppColors.accent,
                                  ),
                                ),
                              );
                            }
                            return _VideoTile(video: videos[index]);
                          },
                          childCount:
                              videos.length + (notifier.hasMore ? 1 : 0),
                        ),
                      ),
                    ),
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: _VideoState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Couldn’t load videos',
                  message: 'Check your connection and try again.',
                  action: FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(paginatedVideosProvider(ustaz)),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      elevation: 0,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'ustaz_avatar_${ustaz.id}',
              child: CachedNetworkImage(
                imageUrl: ustaz.imageUrl,
                fit: BoxFit.cover,
                httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    (isDark ? AppColors.backgroundDark : AppColors.background)
                        .withValues(alpha: 0.5),
                    isDark ? AppColors.backgroundDark : AppColors.background,
                  ],
                  stops: const [0.4, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
        title: Text(
          ustaz.name,
          style: AppTextStyles.heading2.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
      ),
    );
  }
}

class _VideoState extends StatelessWidget {
  const _VideoState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

class _VideoTile extends StatelessWidget {
  final VideoItem video;

  const _VideoTile({required this.video});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = video.title.trim().isEmpty
        ? 'Lecture from ${video.author}'
        : video.title.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFDCE6E3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoPlayerScreen(videoId: video.id),
              ),
            );
          },
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(18),
                ),
                child: SizedBox(
                  width: 132,
                  height: 92,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: video.thumbnailUrl,
                        fit: BoxFit.cover,
                        httpHeaders: const {'User-Agent': 'Mozilla/5.0'},
                        placeholder: (context, url) => Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.video_library),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        video.author,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
