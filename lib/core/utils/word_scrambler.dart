import 'dart:math';

/// Utility for scrambling word letters.
class WordScrambler {
  static final _random = Random();

  /// Returns a shuffled version of [word] that differs from the original.
  static String scramble(String word) {
    if (word.length <= 1) return word;

    final chars = word.split('');
    String scrambled;

    do {
      chars.shuffle(_random);
      scrambled = chars.join();
    } while (scrambled == word);

    return scrambled;
  }
}
