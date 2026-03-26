import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:word_puzzle/core/theme/app_colors.dart';
import 'package:word_puzzle/core/utils/app_language.dart';
import 'package:word_puzzle/core/utils/app_strings.dart';
import 'package:word_puzzle/core/utils/responsive.dart';
import 'package:word_puzzle/features/auth/presentation/bloc/auth_bloc.dart';

/// Profile page where the user can change their display name and avatar.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _imagePicker = ImagePicker();
  int _selectedAvatarIndex = -1;
  bool _isEditing = false;
  bool _isUploading = false;
  String? _uploadedPhotoUrl; // URL from Firebase Storage after upload

  // Predefined avatar options
  static const _avatarColors = [
    Color(0xFF6C63FF),
    Color(0xFF03DAC6),
    Color(0xFFFF6B6B),
    Color(0xFFFF9800),
    Color(0xFF4CAF50),
    Color(0xFFE91E63),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF795548),
    Color(0xFF607D8B),
  ];

  static const _avatarEmojis = [
    '😎', '🤖', '👾', '🦊', '🐱', '🐶',
    '🦁', '🐸', '🦄', '🎮', '🧙', '🥷',
  ];

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      _nameController.text = state.user.name;
      _photoUrlController.text = state.user.photoUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (picked == null) return;

      setState(() {
        _isUploading = true;
        _selectedAvatarIndex = -1; // Clear emoji selection
      });

      // Upload to Firebase Storage
      final authState = context.read<AuthBloc>().state;
      final uid = authState is AuthAuthenticated ? authState.user.id : 'unknown';
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$uid.jpg');

      final bytes = await picked.readAsBytes();
      final uploadTask = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        _uploadedPhotoUrl = downloadUrl;
        _photoUrlController.text = downloadUrl;
        _isUploading = false;
        _isEditing = true;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Upload failed: $e', textAlign: TextAlign.center),
              backgroundColor: AppColors.wrong,
              behavior: SnackBarBehavior.floating,
            ),
          );
      }
    }
  }

  void _showImageSourceDialog(AppStrings s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(s.profilePhoto,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ImageSourceOption(
                        icon: Icons.photo_library_rounded,
                        label: s.isTr ? 'Galeri' : 'Gallery',
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ImageSourceOption(
                        icon: Icons.camera_alt_rounded,
                        label: s.isTr ? 'Kamera' : 'Camera',
                        color: AppColors.secondary,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveProfile() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    String photoUrl = _photoUrlController.text.trim();

    // Priority: uploaded photo > emoji avatar > existing
    if (_uploadedPhotoUrl != null && _uploadedPhotoUrl!.isNotEmpty) {
      photoUrl = _uploadedPhotoUrl!;
    } else if (_selectedAvatarIndex >= 0) {
      photoUrl = 'avatar:$_selectedAvatarIndex';
    }

    context.read<AuthBloc>().add(
          AuthProfileUpdateRequested(name: name, photoUrl: photoUrl),
        );

    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguageNotifier>().language;
    final s = AppStrings(lang);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated && !_isEditing) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(s.profileUpdated, textAlign: TextAlign.center),
                backgroundColor: AppColors.correct,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin:
                    const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
            );
        }
      },
      builder: (context, state) {
        String name = 'Player';
        String photoUrl = '';
        int score = 0;
        int totalLevel = 0;
        String friendCode = '';

        if (state is AuthAuthenticated) {
          name = state.user.name;
          photoUrl = state.user.photoUrl;
          score = state.user.score;
          friendCode = state.user.friendCode;
          if (state.user.categoryLevels.isNotEmpty) {
            totalLevel = state.user.categoryLevels.values
                .fold(0, (sum, lv) => sum + lv);
          } else {
            totalLevel = state.user.level;
          }
        }

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive(context).maxContentWidth,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    children: [
                      // App bar
                      _buildAppBar(s),
                      const SizedBox(height: 32),

                      // Avatar
                      _buildAvatar(name, photoUrl, s),
                      const SizedBox(height: 16),

                      // Name + Friend Code
                      Text(name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          )),
                      if (friendCode.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('#$friendCode',
                            style: TextStyle(
                              color: AppColors.primary.withValues(alpha: 0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            )),
                      ],
                      const SizedBox(height: 24),

                      // Stats
                      _buildStats(s, score, totalLevel),
                      const SizedBox(height: 32),

                      // Edit Name
                      _buildEditSection(s, name),
                      const SizedBox(height: 20),

                      // Avatar Picker
                      _buildAvatarPicker(s),
                      const SizedBox(height: 24),

                      // Save Button
                      _buildSaveButton(s),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(AppStrings s) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Colors.white70),
        ),
        Expanded(
          child: Text(s.profile,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 48), // Balance
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildAvatar(String name, String photoUrl, AppStrings s) {
    // Determine what to show
    final displayUrl = _uploadedPhotoUrl ?? photoUrl;
    Widget avatarContent;

    if (_isUploading) {
      avatarContent = Container(
        width: 100, height: 100,
        decoration: const BoxDecoration(
          shape: BoxShape.circle, color: AppColors.darkCard,
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
        ),
      );
    } else if (_selectedAvatarIndex >= 0) {
      avatarContent = Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _avatarColors[_selectedAvatarIndex],
        ),
        child: Center(
          child: Text(_avatarEmojis[_selectedAvatarIndex],
              style: const TextStyle(fontSize: 44)),
        ),
      );
    } else if (displayUrl.startsWith('avatar:')) {
      final idx = int.tryParse(displayUrl.replaceFirst('avatar:', '')) ?? 0;
      avatarContent = Container(
        width: 100, height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _avatarColors[idx.clamp(0, _avatarColors.length - 1)],
        ),
        child: Center(
          child: Text(
              _avatarEmojis[idx.clamp(0, _avatarEmojis.length - 1)],
              style: const TextStyle(fontSize: 44)),
        ),
      );
    } else if (displayUrl.isNotEmpty) {
      avatarContent = ClipOval(
        child: Image.network(displayUrl,
            width: 100, height: 100, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackAvatar(name)),
      );
    } else {
      avatarContent = _fallbackAvatar(name);
    }

    return GestureDetector(
      onTap: () => _showImageSourceDialog(s),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: avatarContent,
          ),
          // Camera badge
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.darkBg, width: 3),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _fallbackAvatar(String name) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'P',
          style: const TextStyle(
              fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStats(AppStrings s, int score, int totalLevel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ProfileStat(label: s.totalScore, value: '$score'),
        Container(
            width: 1,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            color: Colors.white.withValues(alpha: 0.1)),
        _ProfileStat(label: s.level, value: '$totalLevel'),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildEditSection(AppStrings s, String currentName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.displayName,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          onChanged: (_) => setState(() => _isEditing = true),
          decoration: InputDecoration(
            hintText: s.enterName,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon:
                const Icon(Icons.person_rounded, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.darkCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }

  Widget _buildAvatarPicker(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.chooseAvatar,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: _avatarEmojis.length,
          itemBuilder: (context, index) {
            final isSelected = _selectedAvatarIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAvatarIndex =
                      _selectedAvatarIndex == index ? -1 : index;
                  _isEditing = true;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _avatarColors[index].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 2.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(_avatarEmojis[index],
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 400.ms);
  }

  Widget _buildSaveButton(AppStrings s) {
    return GestureDetector(
      onTap: _saveProfile,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF8B7AFF)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            s.save,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 500.ms);
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
      ],
    );
  }
}

class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
