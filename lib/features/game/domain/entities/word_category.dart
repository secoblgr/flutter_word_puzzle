import 'package:flutter/material.dart';

/// Available word categories in the game.
enum WordCategory {
  animals,
  jobs,
  food,
  nature,
  sports,
  technology,
  music,
  geography,
  science,
  history;

  String get displayName {
    switch (this) {
      case WordCategory.animals:
        return 'Animals';
      case WordCategory.jobs:
        return 'Jobs';
      case WordCategory.food:
        return 'Food & Drinks';
      case WordCategory.nature:
        return 'Nature';
      case WordCategory.sports:
        return 'Sports';
      case WordCategory.technology:
        return 'Technology';
      case WordCategory.music:
        return 'Music';
      case WordCategory.geography:
        return 'Geography';
      case WordCategory.science:
        return 'Science';
      case WordCategory.history:
        return 'History';
    }
  }

  String get subtitle {
    switch (this) {
      case WordCategory.animals:
        return 'Creatures of the world';
      case WordCategory.jobs:
        return 'Professions & careers';
      case WordCategory.food:
        return 'Tasty words';
      case WordCategory.nature:
        return 'Earth & elements';
      case WordCategory.sports:
        return 'Games & athletics';
      case WordCategory.technology:
        return 'Digital & science';
      case WordCategory.music:
        return 'Instruments & sounds';
      case WordCategory.geography:
        return 'Places & landforms';
      case WordCategory.science:
        return 'Facts & discoveries';
      case WordCategory.history:
        return 'Past events & eras';
    }
  }

  IconData get icon {
    switch (this) {
      case WordCategory.animals:
        return Icons.pets_rounded;
      case WordCategory.jobs:
        return Icons.work_rounded;
      case WordCategory.food:
        return Icons.restaurant_rounded;
      case WordCategory.nature:
        return Icons.eco_rounded;
      case WordCategory.sports:
        return Icons.sports_soccer_rounded;
      case WordCategory.technology:
        return Icons.computer_rounded;
      case WordCategory.music:
        return Icons.music_note_rounded;
      case WordCategory.geography:
        return Icons.public_rounded;
      case WordCategory.science:
        return Icons.science_rounded;
      case WordCategory.history:
        return Icons.account_balance_rounded;
    }
  }

  /// Turkish display name for the category.
  String get displayNameTr {
    switch (this) {
      case WordCategory.animals:
        return 'Hayvanlar';
      case WordCategory.jobs:
        return 'Meslekler';
      case WordCategory.food:
        return 'Yiyecekler';
      case WordCategory.nature:
        return 'Doğa';
      case WordCategory.sports:
        return 'Spor';
      case WordCategory.technology:
        return 'Teknoloji';
      case WordCategory.music:
        return 'Müzik';
      case WordCategory.geography:
        return 'Coğrafya';
      case WordCategory.science:
        return 'Bilim';
      case WordCategory.history:
        return 'Tarih';
    }
  }

  /// Turkish subtitle for the category.
  String get subtitleTr {
    switch (this) {
      case WordCategory.animals:
        return 'Dünyanın canlıları';
      case WordCategory.jobs:
        return 'Meslek ve kariyer';
      case WordCategory.food:
        return 'Lezzetli kelimeler';
      case WordCategory.nature:
        return 'Dünya ve elementler';
      case WordCategory.sports:
        return 'Oyun ve atletizm';
      case WordCategory.technology:
        return 'Dijital dünya';
      case WordCategory.music:
        return 'Enstrüman ve sesler';
      case WordCategory.geography:
        return 'Yerler ve coğrafya';
      case WordCategory.science:
        return 'Bilim ve keşifler';
      case WordCategory.history:
        return 'Geçmiş olaylar';
    }
  }

  /// Returns display name based on language code.
  String localizedName(String langCode) =>
      langCode == 'tr' ? displayNameTr : displayName;

  /// Returns subtitle based on language code.
  String localizedSubtitle(String langCode) =>
      langCode == 'tr' ? subtitleTr : subtitle;

  Color get color {
    switch (this) {
      case WordCategory.animals:
        return const Color(0xFFFF7043);
      case WordCategory.jobs:
        return const Color(0xFF42A5F5);
      case WordCategory.food:
        return const Color(0xFFFFCA28);
      case WordCategory.nature:
        return const Color(0xFF66BB6A);
      case WordCategory.sports:
        return const Color(0xFFEF5350);
      case WordCategory.technology:
        return const Color(0xFFAB47BC);
      case WordCategory.music:
        return const Color(0xFFEC407A);
      case WordCategory.geography:
        return const Color(0xFF26C6DA);
      case WordCategory.science:
        return const Color(0xFF7CB342);
      case WordCategory.history:
        return const Color(0xFF8D6E63);
    }
  }
}
