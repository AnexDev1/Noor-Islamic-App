class TajweedReciter {
  final String id;
  final String name;
  final String folderName;
  final String description;

  const TajweedReciter({
    required this.id,
    required this.name,
    required this.folderName,
    required this.description,
  });
}

const List<TajweedReciter> popularTajweedReciters = [
  TajweedReciter(id: 'alafasy', name: 'Mishary Rashid Alafasy', folderName: 'Alafasy_128kbps', description: 'Clear and melodic'),
  TajweedReciter(id: 'abdul_basit', name: 'Abdul Basit (Murattal)', folderName: 'Abdul_Basit_Murattal_192kbps', description: 'Classic murattal'),
  TajweedReciter(id: 'abdullah_basfar', name: 'Abdullah Basfar', folderName: 'Abdullah_Basfar_192kbps', description: 'Paced and clear'),
  TajweedReciter(id: 'abu_bakr', name: 'Abu Bakr Ash-Shaatree', folderName: 'Abu_Bakr_Ash-Shaatree_128kbps', description: 'Emotional'),
  TajweedReciter(id: 'hani_rifai', name: 'Hani Rifai', folderName: 'Hani_Rifai_192kbps', description: 'Soft and touching'),
  TajweedReciter(id: 'husary', name: 'Mahmoud Khalil Al-Husary', folderName: 'Husary_128kbps', description: 'Perfect Tajweed'),
  TajweedReciter(id: 'hudhaify', name: 'Ali Al-Hudhaify', folderName: 'Hudhaify_128kbps', description: 'Clear and slow'),
  TajweedReciter(id: 'maher', name: 'Maher Al Muaiqly', folderName: 'Maher_AlMuaiqly_64kbps', description: 'Popular Makkah Imam'),
  TajweedReciter(id: 'minshawy', name: 'Minshawy (Murattal)', folderName: 'Minshawy_Murattal_128kbps', description: 'Heartfelt'),
  TajweedReciter(id: 'muhammad_ayyoub', name: 'Muhammad Ayyoub', folderName: 'Muhammad_Ayyoub_128kbps', description: 'Beautiful Hijazi'),
  TajweedReciter(id: 'muhammad_jibreel', name: 'Muhammad Jibreel', folderName: 'Muhammad_Jibreel_128kbps', description: 'Egyptian classic'),
  TajweedReciter(id: 'shuraym', name: 'Saood ash-Shuraym', folderName: 'Saood_ash-Shuraym_128kbps', description: 'Makkah style'),
  TajweedReciter(id: 'sudais', name: 'Abdul Rahman Al-Sudais', folderName: 'Abdurrahmaan_As-Sudais_192kbps', description: 'Imam of Grand Mosque'),
  TajweedReciter(id: 'dussary', name: 'Yasser Ad-Dussary', folderName: 'Yasser_Ad-Dussary_128kbps', description: 'Energetic'),
  TajweedReciter(id: 'ghamdi', name: 'Saad Al-Ghamdi', folderName: 'Ghamadi_40kbps', description: 'Smooth and powerful'),
  TajweedReciter(id: 'english', name: 'English (Ibrahim Walk)', folderName: 'English/Sahih_Intnl_Ibrahim_Walk_192kbps', description: 'English translation only'),
  TajweedReciter(id: 'juhany', name: 'Abdullah Al-Juhany', folderName: 'Abdullaah_3awwaad_Al-Juhaynee_128kbps', description: 'Makkah Imam'),
];
