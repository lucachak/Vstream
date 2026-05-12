import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vstream/core/theme/app_theme.dart';
import 'package:vstream/shared/models/user_profile.dart';
import 'package:vstream/shared/providers/local_movies_provider.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _nameCtrl = TextEditingController();
  int _selectedColorValue = 0xFFE50914;
  DateTime? _selectedDob;
  String? _selectedGender;
  bool _isAdultContentEnabled = false;
  bool _pushNotificationsEnabled = true;
  List<String> _selectedGenres = [];
  bool _isSaving = false;

  final List<int> _avatarColors = [
    0xFFE50914, 0xFF2196F3, 0xFF4CAF50, 0xFFFFC107,
    0xFF9C27B0, 0xFF00BCD4, 0xFFFF5722, 0xFF607D8B,
  ];

  final List<String> _availableGenres = [
    'Action', 'Drama', 'Sci-Fi', 'Animation', 'Comedy', 'Horror', 'Documentary', 'Anime'
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(sessionProvider);
    if (profile != null) {
      _nameCtrl.text = profile.name;
      _selectedColorValue = profile.avatarColorValue;
      _selectedDob = profile.dob;
      _selectedGender = profile.gender;
      _isAdultContentEnabled = profile.isAdultContentEnabled;
      _pushNotificationsEnabled = profile.pushNotificationsEnabled;
      _selectedGenres = List.from(profile.favoriteGenres);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);
    final notifier = ref.read(sessionProvider.notifier);
    final current = ref.read(sessionProvider);
    
    if (current != null) {
      final updated = current.copyWith(
        name: _nameCtrl.text.trim(),
        avatarColorValue: _selectedColorValue,
        dob: _selectedDob,
        gender: _selectedGender,
        isAdultContentEnabled: _isAdultContentEnabled,
        favoriteGenres: _selectedGenres,
        pushNotificationsEnabled: _pushNotificationsEnabled,
      );
      await notifier.updateProfile(updated);
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings updated!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(sessionProvider);
    if (profile == null) return const Scaffold();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.red,
            labelColor: AppColors.red,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
            tabs: const [
              Tab(text: 'PROFILE'),
              Tab(text: 'INTERESTS'),
              Tab(text: 'SAFETY'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  _buildProfileTab(profile),
                  _buildInterestsTab(),
                  _buildSafetyTab(),
                ],
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(UserProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Center(
            child: Stack(
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(_selectedColorValue),
                  ),
                  child: Center(
                    child: Text(
                      _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(bottom: 0, right: 0, child: _CircleIcon(Icons.brush_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildColorPicker(),
          const SizedBox(height: 32),
          _buildField('Full Name', _nameCtrl, Icons.person_outline_rounded),
          const SizedBox(height: 16),
          _buildGenderPicker(),
          const SizedBox(height: 16),
          _buildDatePicker(),
          const SizedBox(height: 32),
          _buildReadOnlyField('Account Email', profile.email, Icons.email_outlined),
        ],
      ),
    );
  }

  Widget _buildInterestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FAVORITE GENRES', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.red, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Tell us what you like to improve your feed recommendations.', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableGenres.map((genre) {
              final isSelected = _selectedGenres.contains(genre);
              return FilterChip(
                selected: isSelected,
                label: Text(genre),
                onSelected: (val) {
                  setState(() {
                    if (val) _selectedGenres.add(genre);
                    else _selectedGenres.remove(genre);
                  });
                },
                selectedColor: AppColors.red.withAlpha(40),
                checkmarkColor: AppColors.red,
                labelStyle: TextStyle(color: isSelected ? AppColors.red : AppColors.textPrimary(context), fontSize: 13),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SAFETY & PRIVACY', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.red, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildToggle(
            'Adult Content (+18)',
            'Show R-rated movies and explicit content in your feed.',
            _isAdultContentEnabled,
            (v) => setState(() => _isAdultContentEnabled = v),
          ),
          const Divider(height: 40),
          Text('NOTIFICATIONS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.red, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildToggle(
            'Push Notifications',
            'Get alerts for new releases and trending shows.',
            _pushNotificationsEnabled,
            (v) => setState(() => _pushNotificationsEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _avatarColors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          final color = _avatarColors[i];
          final isSelected = _selectedColorValue == color;
          return GestureDetector(
            onTap: () => setState(() => _selectedColorValue = color),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Color(color), shape: BoxShape.circle,
                border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenderPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedGender,
          hint: Text('Select Gender', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          isExpanded: true,
          items: ['Male', 'Female', 'Non-Binary', 'Prefer not to say'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (v) => setState(() => _selectedGender = v),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDob ?? DateTime(2000),
          firstDate: DateTime(1940),
          lastDate: DateTime.now(),
        );
        if (date != null) setState(() => _selectedDob = date);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgSurface(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Text(
              _selectedDob == null ? 'Date of Birth' : DateFormat('MMM dd, yyyy').format(_selectedDob!),
              style: TextStyle(color: _selectedDob == null ? AppColors.textMuted : AppColors.textPrimary(context), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(String title, String sub, bool val, Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary(context))),
            const SizedBox(height: 4),
            Text(sub, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ]),
        ),
        Switch(value: val, onChanged: onChanged, activeColor: AppColors.red),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 90, top: 12),
      child: SizedBox(
        width: double.infinity, height: 54,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE SETTINGS'),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20)),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return TextField(
      controller: TextEditingController(text: value),
      enabled: false,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20)),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  const _CircleIcon(this.icon);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(6),
    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    child: Icon(icon, size: 14, color: Colors.black),
  );
}
