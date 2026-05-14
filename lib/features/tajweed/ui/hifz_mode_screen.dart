import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../quran/data/quran_api.dart';
import '../../quran/data/surah_api.dart';
import '../../quran/domain/surah_info.dart';
import '../../quran/domain/surah_detail.dart';
import '../providers/tajweed_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/reciter.dart';
import 'tajweed_player_screen.dart';

class HifzModeScreen extends ConsumerStatefulWidget {
  const HifzModeScreen({super.key});

  @override
  ConsumerState<HifzModeScreen> createState() => _HifzModeScreenState();
}

class _HifzModeScreenState extends ConsumerState<HifzModeScreen> {
  List<SurahInfo> _surahs = [];
  SurahInfo? _selectedSurah;
  SurahDetail? _surahDetail;
  int _startAyah = 1;
  int _endAyah = 1;
  bool _isLoadingSurahs = true;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
  }

  Future<void> _loadSurahs() async {
    try {
      final surahs = await QuranApi.fetchSurahs();
      setState(() {
        _surahs = surahs;
        _isLoadingSurahs = false;
        if (_surahs.isNotEmpty) {
          _selectedSurah = _surahs[0];
          _loadSurahDetail(_selectedSurah!);
        }
      });
    } catch (e) {
      setState(() => _isLoadingSurahs = false);
    }
  }

  Future<void> _loadSurahDetail(SurahInfo surah) async {
    setState(() {
      _isLoadingDetail = true;
    });
    try {
      final surahNo = _surahs.indexOf(surah) + 1;
      final detail = await SurahApi.fetchSurahDetail(surahNo);
      setState(() {
        _surahDetail = detail;
        _startAyah = 1;
        _endAyah = detail.totalAyah;
        _isLoadingDetail = false;
      });
    } catch (e) {
      setState(() => _isLoadingDetail = false);
    }
  }

  void _startHifzSession() {
    if (_selectedSurah == null || _surahDetail == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TajweedPlayerScreen(
          surahDetail: _surahDetail!,
          startAyah: _startAyah,
          endAyah: _endAyah,
        ),
      ),
    );
  }

  void _showReciterPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final tajweedState = ref.watch(tajweedProvider);
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: popularTajweedReciters.length,
              itemBuilder: (context, index) {
                final reciter = popularTajweedReciters[index];
                final isSelected = reciter.id == tajweedState.selectedReciterId;
                return ListTile(
                  title: Text(reciter.name, style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary)),
                  subtitle: Text(reciter.description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFD4AF37)) : null,
                  onTap: () {
                    ref.read(tajweedProvider.notifier).updateReciter(reciter.id);
                    Navigator.pop(context);
                  },
                );
              },
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final tajweedState = ref.watch(tajweedProvider);
    final tajweedNotifier = ref.read(tajweedProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Hifz / Recitation Mode', style: AppTextStyles.heading2),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: _isLoadingSurahs
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Surah', style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SurahInfo>(
                        isExpanded: true,
                        dropdownColor: AppColors.surface,
                        value: _selectedSurah,
                        items: _surahs.asMap().entries.map((entry) => DropdownMenuItem(
                          value: entry.value,
                          child: Text('${entry.key + 1}. ${entry.value.surahName}', style: AppTextStyles.bodyLarge),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSurah = val;
                            });
                            _loadSurahDetail(val);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (_isLoadingDetail)
                    const Center(child: CircularProgressIndicator())
                  else if (_surahDetail != null) ...[
                    Text('Ayah Range', style: AppTextStyles.heading3),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From', style: AppTextStyles.labelMedium),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    dropdownColor: AppColors.surface,
                                    value: _startAyah,
                                    items: List.generate(_surahDetail!.totalAyah, (index) => index + 1).map((a) => DropdownMenuItem(
                                      value: a,
                                      child: Text('Ayah $a', style: AppTextStyles.bodyLarge),
                                    )).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() { _startAyah = val; if (_endAyah < _startAyah) _endAyah = _startAyah; });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('To', style: AppTextStyles.labelMedium),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    dropdownColor: AppColors.surface,
                                    value: _endAyah,
                                    items: List.generate(_surahDetail!.totalAyah - _startAyah + 1, (index) => index + _startAyah).map((a) => DropdownMenuItem(
                                      value: a,
                                      child: Text('Ayah $a', style: AppTextStyles.bodyLarge),
                                    )).toList(),
                                    onChanged: (val) {
                                      if (val != null) setState(() { _endAyah = val; });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Text('Reciter', style: AppTextStyles.heading3),
                    const SizedBox(height: 12),
                    ListTile(
                      tileColor: AppColors.surface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      leading: const Icon(Icons.person, color: Color(0xFFD4AF37)),
                      title: Text(tajweedNotifier.currentReciter.name, style: AppTextStyles.bodyLarge),
                      subtitle: Text(tajweedNotifier.currentReciter.description, style: AppTextStyles.bodyMedium),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textTertiary),
                      onTap: _showReciterPicker,
                    ),

                    const SizedBox(height: 24),
                    Text('Repetition', style: AppTextStyles.heading3),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Repeat Each Ayah', style: AppTextStyles.bodyLarge),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary),
                              onPressed: () {
                                if (tajweedState.repeatCount > 1) {
                                  tajweedNotifier.updateRepeatCount(tajweedState.repeatCount - 1);
                                }
                              },
                            ),
                            Text('${tajweedState.repeatCount}x', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                              onPressed: () {
                                if (tajweedState.repeatCount < 20) {
                                  tajweedNotifier.updateRepeatCount(tajweedState.repeatCount + 1);
                                }
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                    SwitchListTile(
                      title: Text('Loop Entire Range', style: AppTextStyles.bodyLarge),
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFFD4AF37),
                      value: tajweedState.loopRange,
                      onChanged: tajweedNotifier.updateLoopRange,
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: AppColors.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.play_circle_fill, size: 24),
                        label: Text('Start Session', style: AppTextStyles.heading3.copyWith(color: AppColors.primaryDark)),
                        onPressed: _startHifzSession,
                      ),
                    ),
                  ],
                  const SizedBox(height: 40), 
                ],
              ),
            ),
    );
  }
}
