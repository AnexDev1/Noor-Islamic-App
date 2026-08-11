import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../quran/data/quran_api.dart';
import '../../quran/data/surah_api.dart';
import '../../quran/domain/surah_detail.dart';
import '../../quran/domain/surah_info.dart';
import '../../quran/ui/widgets/quran_visuals.dart';
import '../models/reciter.dart';
import '../providers/tajweed_provider.dart';
import 'tajweed_player_screen.dart';

class HifzModeScreen extends ConsumerStatefulWidget {
  const HifzModeScreen({super.key});

  @override
  ConsumerState<HifzModeScreen> createState() => _HifzModeScreenState();
}

class _HifzModeScreenState extends ConsumerState<HifzModeScreen> {
  List<SurahInfo> _surahs = const [];
  SurahInfo? _selectedSurah;
  SurahDetail? _detail;
  int _startAyah = 1;
  int _endAyah = 1;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final surahs = await QuranApi.fetchSurahs();
      if (!mounted) return;
      _surahs = surahs;
      _selectedSurah = surahs.firstOrNull;
      if (_selectedSurah != null) {
        await _loadDetail(_selectedSurah!);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Couldn’t prepare your Hifz session.';
        });
      }
    }
  }

  Future<void> _loadDetail(SurahInfo surah) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await SurahApi.fetchSurahDetail(
        _surahs.indexOf(surah) + 1,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _startAyah = 1;
        _endAyah = detail.totalAyah;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Couldn’t load this surah.';
        });
      }
    }
  }

  void _startSession() {
    if (_detail == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TajweedPlayerScreen(
          surahDetail: _detail!,
          startAyah: _startAyah,
          endAyah: _endAyah,
        ),
      ),
    );
  }

  Future<void> _pickSurah() async {
    final selected = await showModalBottomSheet<SurahInfo>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: _surahs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final surah = _surahs[index];
              return ListTile(
                leading: AyahMedallion(number: index + 1),
                title: Text(surah.surahName),
                trailing: _selectedSurah == surah
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, surah),
              );
            },
          ),
        ),
      ),
    );
    if (selected != null && selected != _selectedSurah) {
      setState(() => _selectedSurah = selected);
      await _loadDetail(selected);
    }
  }

  Future<void> _pickReciter() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(tajweedProvider);
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(
                  'Choose a reciter',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final reciter in popularTajweedReciters)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(reciter.name),
                    subtitle: Text(reciter.description),
                    trailing: reciter.id == state.selectedReciterId
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      ref
                          .read(tajweedProvider.notifier)
                          .updateReciter(reciter.id);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tajweedProvider);
    final notifier = ref.read(tajweedProvider.notifier);
    final reciter = notifier.currentReciter;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Hifz Studio')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _loadSurahs)
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                  sliver: SliverList.list(
                    children: [
                      QuranSurahBanner(
                        arabicName: _detail!.surahNameArabic,
                        name: _detail!.surahName,
                        subtitle:
                            '${_detail!.revelationPlace}  •  ${_detail!.totalAyah} verses',
                        showBasmala: _detail!.surahNo != 9,
                      ),
                      const SizedBox(height: 22),
                      _SectionTitle(
                        icon: Icons.menu_book_rounded,
                        title: 'Practice passage',
                        subtitle: 'Choose what you want to strengthen today',
                      ),
                      const SizedBox(height: 12),
                      _SelectionTile(
                        icon: Icons.auto_stories_rounded,
                        label: 'Surah',
                        value: '${_detail!.surahNo}. ${_detail!.surahName}',
                        onTap: _pickSurah,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _AyahPicker(
                              label: 'From',
                              value: _startAyah,
                              max: _detail!.totalAyah,
                              min: 1,
                              onChanged: (value) => setState(() {
                                _startAyah = value;
                                if (_endAyah < value) _endAyah = value;
                              }),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AyahPicker(
                              label: 'To',
                              value: _endAyah,
                              max: _detail!.totalAyah,
                              min: _startAyah,
                              onChanged: (value) =>
                                  setState(() => _endAyah = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      _SectionTitle(
                        icon: Icons.headphones_rounded,
                        title: 'Listen & repeat',
                        subtitle: 'Build familiarity before active recall',
                      ),
                      const SizedBox(height: 12),
                      _SelectionTile(
                        icon: Icons.graphic_eq_rounded,
                        label: 'Reciter',
                        value: reciter.name,
                        onTap: _pickReciter,
                      ),
                      const SizedBox(height: 12),
                      MushafSurface(
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Expanded(child: Text('Repeat each ayah')),
                                IconButton(
                                  onPressed: state.repeatCount > 1
                                      ? () => notifier.updateRepeatCount(
                                          state.repeatCount - 1,
                                        )
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                ),
                                Text(
                                  '${state.repeatCount}×',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: QuranVisuals.goldFor(context),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                IconButton(
                                  onPressed: state.repeatCount < 20
                                      ? () => notifier.updateRepeatCount(
                                          state.repeatCount + 1,
                                        )
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                ),
                              ],
                            ),
                            const Divider(),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Loop the complete range'),
                              subtitle: const Text(
                                'Begin again after the final ayah',
                              ),
                              value: state.loopRange,
                              onChanged: notifier.updateLoopRange,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: _startSession,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          'Begin ${_endAyah - _startAyah + 1}-ayah session',
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(58),
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    ],
  );
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => MushafSurface(
    padding: EdgeInsets.zero,
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: Theme.of(context).textTheme.labelMedium),
      subtitle: Text(
        value,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(Icons.keyboard_arrow_down_rounded),
    ),
  );
}

class _AyahPicker extends StatelessWidget {
  const _AyahPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => MushafSurface(
    child: DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        isExpanded: true,
        value: value,
        borderRadius: BorderRadius.circular(16),
        items: [
          for (var number = min; number <= max; number++)
            DropdownMenuItem(value: number, child: Text('$label ayah $number')),
        ],
        onChanged: (number) {
          if (number != null) onChanged(number);
        },
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 52),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
