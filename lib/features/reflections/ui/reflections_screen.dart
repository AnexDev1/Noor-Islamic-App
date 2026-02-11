import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reflections_provider.dart';
import 'widgets/feeling_selector.dart';

class ReflectionsScreen extends ConsumerStatefulWidget {
  const ReflectionsScreen({super.key});

  @override
  ConsumerState<ReflectionsScreen> createState() => _ReflectionsScreenState();
}

class _ReflectionsScreenState extends ConsumerState<ReflectionsScreen> {
  @override
  Widget build(BuildContext context) {
    final reflState = ref.watch(reflectionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Salah Reflections',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37),
        onPressed: () => _showAddReflectionSheet(context),
        child: const Icon(Icons.add, color: Color(0xFF0A1628)),
      ),
      body: reflState.reflections.isEmpty
          ? _buildEmptyState()
          : _buildContent(reflState),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🤲', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No reflections yet',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first prayer reflection',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ReflectionsState reflState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSentimentOverview(reflState),
          const SizedBox(height: 24),
          _buildWeekChart(reflState),
          const SizedBox(height: 24),
          const Text(
            'Recent Reflections',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...reflState.reflections.take(20).map(_buildReflectionCard),
        ],
      ),
    );
  }

  Widget _buildSentimentOverview(ReflectionsState reflState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0F4C3A).withValues(alpha: 0.6),
            const Color(0xFF1A6B50).withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _miniStat(
              '${reflState.totalReflections}',
              'Total',
              Icons.edit_note,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _miniStat(
              reflState.averageSentiment.toStringAsFixed(1),
              'Avg Feeling',
              Icons.favorite,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _miniStat(
              '${reflState.last7Days.length}',
              'This Week',
              Icons.calendar_today,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFD4AF37), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekChart(ReflectionsState reflState) {
    final last7 = reflState.last7Days;
    if (last7.isEmpty) return const SizedBox.shrink();

    // Group by day
    final now = DateTime.now();
    final days = <String, List<int>>{};
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.month}/${date.day}';
      days[key] = [];
    }
    for (final r in last7) {
      final key = '${r.dateTime.month}/${r.dateTime.day}';
      days[key]?.add(r.sentiment);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Sentiment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.entries.map((entry) {
                final avg = entry.value.isNotEmpty
                    ? entry.value.reduce((a, b) => a + b) / entry.value.length
                    : 0.0;
                final barHeight = (avg / 5) * 60;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: barHeight,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              _barColor(avg).withValues(alpha: 0.6),
                              _barColor(avg),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _barColor(double avg) {
    if (avg >= 4) return const Color(0xFF64B5F6);
    if (avg >= 3) return const Color(0xFF81C784);
    if (avg >= 2) return const Color(0xFFFFD54F);
    return const Color(0xFFE57373);
  }

  Widget _buildReflectionCard(Reflection reflection) {
    final sentimentEmojis = ['', '😔', '😐', '🙂', '😊', '🤲'];
    final timeStr = _formatTime(reflection.dateTime);

    return Dismissible(
      key: Key(reflection.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      onDismissed: (_) {
        ref.read(reflectionsProvider.notifier).deleteReflection(reflection.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sentimentEmojis[reflection.sentiment],
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        reflection.prayerName,
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  if (reflection.note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      reflection.note,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (reflection.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: reflection.tags
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFD4AF37,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t,
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}';
  }

  void _showAddReflectionSheet(BuildContext context) {
    int selectedSentiment = 3;
    String selectedPrayer = 'Fajr';
    final noteController = TextEditingController();
    final selectedTags = <String>[];
    final availableTags = [
      'Khushoo',
      'Grateful',
      'Rushed',
      'Distracted',
      'Emotional',
      'Peaceful',
      'Community',
      'Late',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF1A2540),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'How was your prayer?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Prayer selector
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']
                        .map(
                          (prayer) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(prayer),
                              selected: selectedPrayer == prayer,
                              onSelected: (_) {
                                setSheetState(() => selectedPrayer = prayer);
                              },
                              selectedColor: const Color(0xFFD4AF37),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              labelStyle: TextStyle(
                                color: selectedPrayer == prayer
                                    ? const Color(0xFF0A1628)
                                    : Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),
                // Feeling selector
                FeelingSelector(
                  selectedSentiment: selectedSentiment,
                  onChanged: (v) => setSheetState(() => selectedSentiment = v),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      FeelingSelector.sentimentLabel(selectedSentiment),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Note field
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'What stood out during your prayer...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableTags
                      .map(
                        (tag) => FilterChip(
                          label: Text(tag),
                          selected: selectedTags.contains(tag),
                          onSelected: (selected) {
                            setSheetState(() {
                              if (selected) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                            });
                          },
                          selectedColor: const Color(
                            0xFFD4AF37,
                          ).withValues(alpha: 0.3),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          labelStyle: TextStyle(
                            color: selectedTags.contains(tag)
                                ? const Color(0xFFD4AF37)
                                : Colors.white60,
                            fontSize: 12,
                          ),
                          checkmarkColor: const Color(0xFFD4AF37),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(reflectionsProvider.notifier)
                          .addReflection(
                            prayerName: selectedPrayer,
                            sentiment: selectedSentiment,
                            note: noteController.text,
                            tags: selectedTags,
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Reflection saved 🤲'),
                          backgroundColor: const Color(0xFF0F4C3A),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: const Color(0xFF0A1628),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Reflection',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
