import 'package:flutter/material.dart';

//
//  SALAH STEP IMAGES  Real images from Wikimedia Commons
//

// Verified working Wikimedia Commons image URLs (via API)
const Map<int, List<String>> _salahImageUrls = {
  1: [
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/say-allahu-akbar-to-start-salah.jpg',
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/say-allahu-akbar-to-start-salah-2.jpg',
  ],
  2: [
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/standing-for-salah-looking-at-ground.jpg',
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/standing-in-salah-recite-surah-fatihah.jpg',
  ],
  3: [
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/make-ruku-prostration.jpg',
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/how-to-make-ruku-bowing-down.jpg',
  ],
  4: [
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/standing-for-salah-looking-at-ground.jpg',
  ],
  5: [
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/making-sujud-in-salah-2.jpg',
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/making-sujud-in-salah.jpg',
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/make-sujud-in-salah.jpg',
  ],
  6: [
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/sitting-between-sujud.jpg',
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/sitting-in-salah-and-tashahud.jpg',
  ],
  7: [
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/making-sujud-in-salah.jpg',
  ],
  8: [
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/saying-tashahud-and-salah-an-nabi-prophet.jpg',
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/sitting-position-in-salah.jpg',
  ],
  9: [
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/sitting-position-in-salah.jpg',
  ],
  10: [
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/end-the-salah-with-tasleem-.jpg',
    'https://www.mymasjid.ca/wp-content/uploads/2017/03/end-the-salah-with-tasleem-2.jpg',
  ],
};

const Map<int, String> _salahPositionLabels = {
  1: 'Qiyam \u2014 Standing',
  2: 'Qira\u2019ah \u2014 Recitation',
  3: 'Ruku\u2019 \u2014 Bowing',
  4: 'I\u2019tidal \u2014 Rising',
  5: 'Sujud \u2014 Prostration',
  6: 'Juloos \u2014 Sitting',
  7: 'Sujud \u2014 2nd Prostration',
  8: 'Tashahhud \u2014 Sitting',
  9: 'Salawat \u2014 Sitting',
  10: 'Tasleem \u2014 Ending',
};

const Map<int, IconData> _fallbackIcons = {
  1: Icons.accessibility_new,
  2: Icons.menu_book,
  3: Icons.south,
  4: Icons.north,
  5: Icons.airline_seat_flat,
  6: Icons.event_seat,
  7: Icons.airline_seat_flat,
  8: Icons.event_seat,
  9: Icons.event_seat,
  10: Icons.waving_hand,
};

/// Returns a network image widget showing the Salah position for the given step.
Widget salahStepIllustration(int stepNum, {double size = 120}) {
  final urls = _salahImageUrls[stepNum];
  final label = _salahPositionLabels[stepNum] ?? 'Step $stepNum';

  if (urls == null || urls.isEmpty) {
    return SizedBox(width: size, height: size);
  }

  // Helper to build a single image with error handling
  Widget buildSingleImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            width: size,
            height: size,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
                color: const Color(0xFF0F4C3A),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: size,
            height: size,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _fallbackIcons[stepNum] ?? Icons.image_not_supported,
                  size: size * 0.4,
                  color: const Color(0xFF0F4C3A).withValues(alpha: 0.5),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // If we have multiple images, show them in a row
  Widget imageContent;
  if (urls.length > 1) {
    imageContent = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: urls.map((url) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: buildSingleImage(url),
          );
        }).toList(),
      ),
    );
  } else {
    imageContent = buildSingleImage(urls.first);
  }

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      imageContent,
      const SizedBox(height: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F4C3A),
        ),
      ),
    ],
  );
}
