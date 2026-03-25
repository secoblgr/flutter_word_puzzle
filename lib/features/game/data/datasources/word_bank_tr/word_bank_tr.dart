import 'package:word_puzzle/features/game/data/models/word_model.dart';

import 'animals_words_tr.dart';
import 'jobs_words_tr.dart';
import 'food_words_tr.dart';
import 'nature_words_tr.dart';
import 'sports_words_tr.dart';
import 'technology_words_tr.dart';
import 'music_words_tr.dart';
import 'geography_words_tr.dart';
import 'science_words_tr.dart';
import 'history_words_tr.dart';

/// All default Turkish words organized by category.
/// Key = category name (matches [WordCategory.name]).
final Map<String, List<WordModel>> defaultWordBankTr = {
  'animals': animalsWordsTr,
  'jobs': jobsWordsTr,
  'food': foodWordsTr,
  'nature': natureWordsTr,
  'sports': sportsWordsTr,
  'technology': technologyWordsTr,
  'music': musicWordsTr,
  'geography': geographyWordsTr,
  'science': scienceWordsTr,
  'history': historyWordsTr,
};
