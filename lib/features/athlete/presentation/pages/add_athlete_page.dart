import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/utils/date_helpers.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/core/utils/validators.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/presentation/bloc/athlete_bloc.dart';

class AddAthletePage extends StatefulWidget {
  final String parentId;
  final AthleteEntity? existingAthlete;

  const AddAthletePage({super.key, required this.parentId, this.existingAthlete});

  @override
  State<AddAthletePage> createState() => _AddAthletePageState();
}

class _AddAthletePageState extends State<AddAthletePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _weeklyHoursController = TextEditingController();

  DateTime? _birthDate;
  Gender _gender = Gender.male;
  SwimLevel _swimLevel = SwimLevel.beginner;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  StreamSubscription<AthleteState>? _blocSubscription;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAthlete;
    if (existing != null) {
      _nameController.text = existing.name;
      _birthDate = existing.birthDate;
      _gender = existing.gender;
      _swimLevel = existing.swimLevel;
      if (existing.weightKg != null) _weightController.text = existing.weightKg!.toString();
      if (existing.heightCm != null) _heightController.text = existing.heightCm!.toString();
      _weeklyHoursController.text = existing.targetWeeklyHours.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.read<AppLocalizations>();

    final isEditing = widget.existingAthlete != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isEditing ? t.translate('edit_athlete') : t.translate('add_athlete')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoPicker(t),
              const SizedBox(height: 20),
              _buildSectionHeader('👤', t.translate('basic_info')),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                textDirection: t.textDirection,
                decoration: InputDecoration(
                  labelText: t.translate('athlete_name'),
                  prefixIcon: const Icon(Icons.person_outlined, color: AppColors.accent),
                ),
                validator: Validators.validateName,
              ),
              const SizedBox(height: 16),
              _buildDatePicker(t),
              const SizedBox(height: 16),
              _buildGenderSelector(t),
              const SizedBox(height: 20),
              _buildSectionHeader('🏊', t.translate('training_level')),
              const SizedBox(height: 12),
              _buildSwimLevelSelector(),
              const SizedBox(height: 20),
              _buildSectionHeader('📏', t.translate('measurements_optional')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t.translate('weight'),
                        prefixIcon: const Icon(Icons.monitor_weight_outlined, color: AppColors.accent),
                      ),
                      validator: Validators.validateWeight,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t.translate('height'),
                        prefixIcon: const Icon(Icons.height, color: AppColors.accent),
                      ),
                      validator: Validators.validateHeight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weeklyHoursController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t.translate('weekly_goal'),
                  prefixIcon: const Icon(Icons.access_time, color: AppColors.accent),
                ),
                validator: Validators.validateWeeklyHours,
              ),
              const SizedBox(height: 32),
              BlocBuilder<AthleteBloc, AthleteState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: state is AthleteLoading ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                      ),
                      child: state is AthleteLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              widget.existingAthlete != null ? t.translate('save_changes') : t.translate('save'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(AppLocalizations t) {
    final photoUrl = widget.existingAthlete?.photoUrl;
    final hasImage = _selectedImage != null || photoUrl != null;
    return Semantics(
      button: true,
      label: 'اختيار صورة',
      child: InkWell(
        onTap: _isUploading ? null : _pickImage,
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 56,
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                backgroundImage: _selectedImage != null
                    ? null
                    : (photoUrl != null ? NetworkImage(photoUrl) : null),
                child: _selectedImageBytes != null
                    ? ClipOval(
                        child: Image.memory(
                          _selectedImageBytes!,
                          width: 112, height: 112,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _photoPlaceholder(t),
                        ),
                      )
                    : _photoPlaceholder(t),
              ),
              if (hasImage)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger, shape: BoxShape.circle,
                    ),
                    child: Semantics(
                      button: true,
                      label: 'إزالة الصورة',
                      child: InkWell(
                        onTap: () => setState(() => _selectedImage = null),
                        borderRadius: BorderRadius.circular(8),
                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              if (_isUploading)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                      child: const CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoPlaceholder(AppLocalizations t) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt, size: 32, color: AppColors.accent),
        const SizedBox(height: 4),
        Text(t.translate('athlete_photo'), style: const TextStyle(fontSize: 11, color: AppColors.accent)),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<String?> _uploadPhoto(String athleteId) async {
    if (_selectedImage == null) return widget.existingAthlete?.photoUrl;
    setState(() => _isUploading = true);
    try {
      final bytes = await _selectedImage!.readAsBytes();
      final ref = FirebaseStorage.instance.ref('athletes/$athleteId/photo.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      return widget.existingAthlete?.photoUrl;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildSectionHeader(String emoji, String title) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(AppLocalizations t) {
    final age = _birthDate != null ? DateHelpers.calculateAge(_birthDate!) : null;
    return InkWell(
      onTap: _pickDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: t.translate('birth_date'),
          prefixIcon: const Icon(Icons.calendar_today, color: AppColors.accent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _birthDate != null
                  ? DateHelpers.formatDate(_birthDate!)
                  : t.translate('select_date_hint'),
              style: TextStyle(
                color: _birthDate != null ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
            if (age != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha:  0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$age سنة',
                  style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderSelector(AppLocalizations t) {
    return Row(
      children: [
        Expanded(
          child: _genderChip(Gender.male, t.translate('male'), Icons.man),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _genderChip(Gender.female, t.translate('female'), Icons.woman),
        ),
      ],
    );
  }

  Widget _genderChip(Gender gender, String label, IconData icon) {
    final isSelected = _gender == gender;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () => setState(() => _gender = gender),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent.withValues(alpha:  0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? AppColors.accent : AppColors.textMuted, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwimLevelSelector() {
    final t = context.read<AppLocalizations>();
    final levels = [
      (SwimLevel.beginner, t.translate('beginner'), '1'),
      (SwimLevel.intermediate, t.translate('intermediate'), '2'),
      (SwimLevel.advanced, t.translate('advanced'), '3'),
      (SwimLevel.competitive, t.translate('competitive'), '4'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: levels.map((l) {
        final isSelected = _swimLevel == l.$1;
        return ChoiceChip(
          label: Text('${l.$3}  ${l.$2}'),
          selected: isSelected,
          onSelected: (_) => setState(() => _swimLevel = l.$1),
        );
      }).toList(),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 12, 1, 1),
      firstDate: DateTime(now.year - 18),
      lastDate: DateTime(now.year - 6),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    final t = context.read<AppLocalizations>();
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('choose_birth_date'))),
      );
      return;
    }

    final existing = widget.existingAthlete;
    String? photoUrl = existing?.photoUrl;

    if (_selectedImage != null) {
      photoUrl = await _uploadPhoto(existing?.id ?? const Uuid().v4());
    }

    if (!mounted) return;
    final bloc = context.read<AthleteBloc>();
    final navigator = Navigator.of(context);
    final birthDate = _birthDate!;

    if (existing != null) {
      bloc.add(UpdateAthleteEvent(
            athlete: AthleteEntity(
              id: existing.id,
              parentId: existing.parentId,
              name: _nameController.text.trim(),
              birthDate: birthDate,
              gender: _gender,
              swimLevel: _swimLevel,
              weightKg: double.tryParse(_weightController.text),
              heightCm: double.tryParse(_heightController.text),
              targetWeeklyHours: double.tryParse(_weeklyHoursController.text) ?? 6,
              restingHRBaseline: existing.restingHRBaseline,
              sleepBaseline: existing.sleepBaseline,
              photoUrl: photoUrl,
              isActive: existing.isActive,
              createdAt: existing.createdAt,
            ),
          ));
    } else {
      bloc.add(AddAthleteEvent(
            parentId: widget.parentId,
            name: _nameController.text.trim(),
            birthDate: birthDate,
            gender: _gender,
            swimLevel: _swimLevel,
            weightKg: double.tryParse(_weightController.text),
            heightCm: double.tryParse(_heightController.text),
            targetWeeklyHours: double.tryParse(_weeklyHoursController.text) ?? 6,
            photoUrl: photoUrl,
          ));
    }

    final completer = Completer<void>();
    _blocSubscription = bloc.stream.listen((state) {
      if (!mounted) return;
      if (state is AthletesLoaded) {
        if (!completer.isCompleted) completer.complete();
        navigator.pop();
      }
      if (state is AthleteError) {
        if (!completer.isCompleted) completer.complete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(state.message)),
        );
      }
    });
    await completer.future.timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  @override
  void dispose() {
    _blocSubscription?.cancel();
    _nameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _weeklyHoursController.dispose();
    super.dispose();
  }
}
