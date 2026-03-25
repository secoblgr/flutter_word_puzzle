import 'package:word_puzzle/core/utils/app_language.dart';

/// Centralized localized strings for the entire app.
class AppStrings {
  final GameLanguage _lang;

  const AppStrings(this._lang);

  bool get isTr => _lang == GameLanguage.tr;

  // ---------------------------------------------------------------------------
  // Common
  // ---------------------------------------------------------------------------
  String get appName => isTr ? 'Kelime Bulmaca' : 'Word Puzzle';
  String get loading => isTr ? 'Yükleniyor...' : 'Loading...';
  String get retry => isTr ? 'Tekrar Dene' : 'Retry';
  String get cancel => isTr ? 'İptal' : 'Cancel';
  String get ok => isTr ? 'Tamam' : 'OK';
  String get yes => isTr ? 'Evet' : 'Yes';
  String get no => isTr ? 'Hayır' : 'No';
  String get back => isTr ? 'Geri' : 'Back';
  String get save => isTr ? 'Kaydet' : 'Save';
  String get close => isTr ? 'Kapat' : 'Close';

  // ---------------------------------------------------------------------------
  // Home Page
  // ---------------------------------------------------------------------------
  String get welcomeBack => isTr ? 'Tekrar hoşgeldin!' : 'Welcome back!';
  String get playGame => isTr ? 'Oyuna Başla' : 'Play Game';
  String get duel => isTr ? 'Düello' : 'Duel';
  String get rankings => isTr ? 'Sıralama' : 'Rankings';
  String get friends => isTr ? 'Arkadaşlar' : 'Friends';
  String get totalScore => isTr ? 'Toplam Puan' : 'Total Score';
  String get totalLevels => isTr ? 'Toplam Seviye' : 'Total Levels';
  String get settings => isTr ? 'Ayarlar' : 'Settings';

  // Home Page - New
  String get greeting => isTr ? 'Hoş geldin!' : 'Welcome back!';
  String get dailyStreak => isTr ? 'Günlük Seri' : 'Daily Streak';
  String get streakDays => isTr ? 'Gün' : 'Days';
  String get streakMotivation => isTr ? 'Yarın oynayarak serine devam et!' : 'Play tomorrow to keep your streak!';
  String get levelProgress => isTr ? 'Seviye İlerlemesi' : 'Level Progress';
  String get dailyQuests => isTr ? 'GÜNLÜK GÖREVLER' : 'DAILY QUESTS';
  String get quickRound => isTr ? 'Hızlı Tur' : 'Quick Round';
  String get winDuel => isTr ? 'Düello Kazan' : 'Win Duel';
  String get addFriendQuest => isTr ? 'Arkadaş Ekle' : 'Add Friend';
  String get completed => isTr ? 'Tamamlandı' : 'Completed';
  String get notCompleted => isTr ? 'Tamamlanmadı' : 'Not Completed';
  String get startGame => isTr ? 'Oyunu Başlat' : 'Start Game';
  String get rank => isTr ? 'Sıralama' : 'Rank';
  String get notifications => isTr ? 'Bildirimler' : 'Notifications';

  // Profile Page
  String get profile => isTr ? 'Profil' : 'Profile';
  String get editProfile => isTr ? 'Profili Düzenle' : 'Edit Profile';
  String get displayName => isTr ? 'Kullanıcı Adı' : 'Display Name';
  String get profilePhoto => isTr ? 'Profil Fotoğrafı' : 'Profile Photo';
  String get enterPhotoUrl => isTr ? 'Fotoğraf URL girin' : 'Enter photo URL';
  String get profileUpdated => isTr ? 'Profil güncellendi!' : 'Profile updated!';
  String get enterName => isTr ? 'İsim girin' : 'Enter a name';
  String get chooseAvatar => isTr ? 'Avatar Seç' : 'Choose Avatar';

  // ---------------------------------------------------------------------------
  // Auth / Login
  // ---------------------------------------------------------------------------
  String get signInWithGoogle => isTr ? 'Google ile Giriş Yap' : 'Sign in with Google';
  String get continueAsGuest => isTr ? 'Misafir olarak devam et' : 'Continue as Guest';
  String get signOut => isTr ? 'Çıkış Yap' : 'Sign Out';
  String get signOutConfirm => isTr ? 'Çıkış yapmak istediğinize emin misiniz?' : 'Are you sure you want to sign out?';

  // ---------------------------------------------------------------------------
  // Category Selection
  // ---------------------------------------------------------------------------
  String get selectCategory => isTr ? 'Kategori Seç' : 'Select Category';
  String get animals => isTr ? 'Hayvanlar' : 'Animals';
  String get jobs => isTr ? 'Meslekler' : 'Jobs';
  String get food => isTr ? 'Yiyecekler' : 'Food & Drinks';
  String get nature => isTr ? 'Doğa' : 'Nature';
  String get sports => isTr ? 'Spor' : 'Sports';
  String get technology => isTr ? 'Teknoloji' : 'Technology';
  String get music => isTr ? 'Müzik' : 'Music';
  String get geography => isTr ? 'Coğrafya' : 'Geography';
  String get science => isTr ? 'Bilim' : 'Science';
  String get history => isTr ? 'Tarih' : 'History';

  String categoryName(String key) {
    switch (key) {
      case 'animals': return animals;
      case 'jobs': return jobs;
      case 'food': return food;
      case 'nature': return nature;
      case 'sports': return sports;
      case 'technology': return technology;
      case 'music': return music;
      case 'geography': return geography;
      case 'science': return science;
      case 'history': return history;
      default: return key;
    }
  }

  // ---------------------------------------------------------------------------
  // Game Page
  // ---------------------------------------------------------------------------
  String get unscrambleTheWord => isTr ? 'Kelimeyi bul' : 'Unscramble the word';
  String get submit => isTr ? 'Gönder' : 'Submit';
  String get hint => isTr ? 'İpucu' : 'Hint';
  String get selectAllLetters => isTr ? 'Tüm harfleri seç' : 'Select all letters';
  String get level => isTr ? 'Seviye' : 'Level';
  String wordOf(int current, int total) => isTr ? 'Kelime $current / $total' : 'Word $current of $total';
  String get timeUp => isTr ? 'Süre Doldu!' : 'Time\'s Up!';
  String get exitGame => isTr ? 'Oyundan Çık' : 'Exit Game';
  String get exitGameConfirm => isTr ? 'Oyundan çıkmak istediğinize emin misiniz? İlerlemeniz kaybolacak.' : 'Are you sure you want to exit? Your progress will be lost.';

  // ---------------------------------------------------------------------------
  // Result Page
  // ---------------------------------------------------------------------------
  String get congratulations => isTr ? 'Tebrikler!' : 'Congratulations!';
  String get levelComplete => isTr ? 'Seviye Tamamlandı!' : 'Level Complete!';
  String get score => isTr ? 'Puan' : 'Score';
  String get time => isTr ? 'Süre' : 'Time';
  String get accuracy => isTr ? 'Doğruluk' : 'Accuracy';
  String get nextLevel => isTr ? 'Sonraki Seviye' : 'Next Level';
  String get backToHome => isTr ? 'Ana Sayfaya Dön' : 'Back to Home';
  String get gameOver => isTr ? 'Oyun Bitti!' : 'Game Over!';
  String get tryAgain => isTr ? 'Tekrar Dene' : 'Try Again';

  // ---------------------------------------------------------------------------
  // Leaderboard
  // ---------------------------------------------------------------------------
  String get leaderboard => isTr ? 'Sıralama' : 'Leaderboard';
  String get pts => isTr ? 'puan' : 'pts';
  String get noPlayersYet => isTr ? 'Henüz oyuncu yok' : 'No players yet';
  String get failedToLoad => isTr ? 'Yüklenemedi' : 'Failed to load';

  // ---------------------------------------------------------------------------
  // Friends
  // ---------------------------------------------------------------------------
  String get friendsTitle => isTr ? 'Arkadaşlar' : 'Friends';
  String get requests => isTr ? 'İstekler' : 'Requests';
  String get searchFriends => isTr ? 'Arkadaş ara...' : 'Search friends...';
  String get addFriend => isTr ? 'Arkadaş Ekle' : 'Add Friend';
  String get myCode => isTr ? 'Kodum' : 'My Code';
  String get friendCodeCopied => isTr ? 'Arkadaş kodu kopyalandı!' : 'Friend code copied!';
  String get enterFriendCode => isTr ? 'Arkadaşının 6 haneli kodunu gir' : 'Enter your friend\'s 6-digit code';
  String get noFriendsYet => isTr ? 'Henüz arkadaşın yok.\n+ ile ekle!' : 'No friends yet.\nTap + to add some!';
  String get noFriendsMatch => isTr ? 'Aramanızla eşleşen arkadaş yok.' : 'No friends match your search.';
  String get noUserFound => isTr ? 'Bu kodla kullanıcı bulunamadı.' : 'No user found with this code.';
  String get findFriend => isTr ? '6 haneli kod girerek\narkadaş bul.' : 'Enter a 6-digit code\nto find a friend.';
  String get thisIsYou => isTr ? 'Bu sensin' : 'This is you';
  String get send => isTr ? 'Gönder' : 'Send';
  String get friendRequestSent => isTr ? 'Arkadaşlık isteği gönderildi!' : 'Friend request sent!';
  String get noPendingRequests => isTr ? 'Bekleyen istek yok' : 'No pending requests';
  String get wantsToBeFriend => isTr ? 'arkadaşın olmak istiyor' : 'wants to be your friend';
  String get accept => isTr ? 'Kabul Et' : 'Accept';
  String get reject => isTr ? 'Reddet' : 'Reject';
  String duelInviteSent(String name) => isTr ? '$name\'e düello daveti gönderildi!' : 'Duel invite sent to $name!';

  // ---------------------------------------------------------------------------
  // Duel
  // ---------------------------------------------------------------------------
  String get duelArena => isTr ? 'Düello Arenası' : 'Duel Arena';
  String get createDuel => isTr ? 'Düello Oluştur' : 'Create Duel';
  String get availableDuels => isTr ? 'Mevcut Düellolar' : 'Available Duels';
  String get noDuelsAvailable => isTr ? 'Mevcut düello yok' : 'No duels available';
  String get createOneInvite => isTr ? 'Bir tane oluştur ve arkadaşını davet et!' : 'Create one and invite a friend!';
  String get waiting => isTr ? 'Bekleniyor...' : 'Waiting...';
  String get opponent => isTr ? 'Rakip' : 'Opponent';
  String get you => isTr ? 'Sen' : 'You';
  String get vs => 'VS';
  String get opponentScore => isTr ? 'Rakip puanı' : 'Opponent score';
  String get duelComplete => isTr ? 'Düello Bitti!' : 'Duel Complete!';
  String get youWin => isTr ? 'Kazandın!' : 'You Win!';
  String get youLose => isTr ? 'Kaybettin!' : 'You Lose!';
  String get draw => isTr ? 'Berabere!' : 'Draw!';
  String get waitingForOpponent => isTr ? 'Rakip bekleniyor...' : 'Waiting for opponent...';
  String get exitDuel => isTr ? 'Düellodan Çık' : 'Exit Duel';
  String get exitDuelConfirm => isTr ? 'Düellodan çıkmak istediğinize emin misiniz?' : 'Are you sure you want to exit the duel?';
  String get leaveDuel => isTr ? 'Düellodan Ayrıl' : 'Leave Duel';

  // Duel invites
  String get duelInvite => isTr ? 'Düello Daveti' : 'Duel Invite';
  String duelInviteFrom(String name) => isTr ? '$name seni düelloya davet ediyor!' : '$name challenges you to a duel!';
  String get duelAccepted => isTr ? 'Düello kabul edildi!' : 'Duel accepted!';
  String get duelRejected => isTr ? 'Düello reddedildi' : 'Duel rejected';
  String duelRejectedBy(String name) => isTr ? '$name düelloyu reddetti.' : '$name rejected the duel.';
  String get duelStarting => isTr ? 'Düello başlıyor...' : 'Duel starting...';
  String get duelInviteSending => isTr ? 'Düello daveti gönderiliyor...' : 'Sending duel invite...';
}
