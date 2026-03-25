import 'package:word_puzzle/features/game/data/models/word_model.dart';

import 'animals_words.dart';
import 'jobs_words.dart';
import 'food_words.dart';
import 'nature_words.dart';
import 'sports_words.dart';
import 'technology_words.dart';
import 'music_words.dart';
import 'geography_words.dart';
import 'science_words.dart';
import 'history_words.dart';

import 'package:word_puzzle/features/game/data/datasources/word_bank_tr/word_bank_tr.dart';

/// All default English words organized by category.
/// Key = category name (matches [WordCategory.name]).
final Map<String, List<WordModel>> defaultWordBank = {
  'animals': animalsWords,
  'jobs': jobsWords,
  'food': foodWords,
  'nature': natureWords,
  'sports': sportsWords,
  'technology': technologyWords,
  'music': musicWords,
  'geography': geographyWords,
  'science': scienceWords,
  'history': historyWords,
};

/// Returns the word bank for the given language code.
/// 'en' → English, 'tr' → Turkish.
Map<String, List<WordModel>> getWordBankForLanguage(String langCode) {
  if (langCode == 'tr') return defaultWordBankTr;
  return defaultWordBank;
}
