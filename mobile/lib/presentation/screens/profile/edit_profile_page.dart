// lib/presentation/screens/profile/edit_profile_page.dart - VISUAL STITCH

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../../application/profile/profile_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ProfileService _profileService = ProfileService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final _formKey = GlobalKey<FormState>();

  // Controladores
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Variáveis de estado
  DateTime? _birthDate;
  String? _gender;
  bool _isSaving = false;

  // Variáveis para Foto
  File? _imageFile;
  String? _photoUrlPreview;

  late Future<void> _loadDataFuture;

  @override
  void initState() {
    super.initState();
    _loadDataFuture = _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _profileService.getUserData(_currentUserId);
      if (!mounted) return;

      if (data != null) {
        _nameController.text = data['displayName'] ?? '';
        _usernameController.text = data['username'] ?? data['email']?.split('@').first ?? '';
        _bioController.text = data['bio'] ?? '';

        final timestamp = data['birthDate'] as Timestamp?;
        if (timestamp != null) _birthDate = timestamp.toDate();

        _gender = data['gender'];
        _photoUrlPreview = data['photoUrl'];

        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: ${e.toString()}'))
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (context, child) {
        // Customiza o calendário para o tema escuro se necessário
        return Theme(
          data: Theme.of(context).brightness == Brightness.dark
              ? ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: Color(0xFF13EC6D)))
              : Theme.of(context),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    FocusScope.of(context).unfocus();
    setState(() { _isSaving = true; });

    try {
      final Map<String, dynamic> dataToUpdate = {
        'displayName': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'gender': _gender,
        'birthDate': _birthDate != null
            ? Timestamp.fromDate(_birthDate!)
            : null,
      };

      await _profileService.updateUserData(dataToUpdate);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil salvo com sucesso!')),
      );
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar perfil: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  Future<void> _showImagePickerOptions() async {
    FocusScope.of(context).unfocus();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF102218) : const Color(0xFFF6F8F7);
    final txtColor = isDark ? Colors.white : const Color(0xFF1C1C1C);

    await showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.photo_library, color: txtColor),
                title: Text('Galeria', style: TextStyle(color: txtColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  _handlePhotoUpload(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: txtColor),
                title: Text('Câmera', style: TextStyle(color: txtColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  _handlePhotoUpload(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePhotoUpload(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 800,
    );

    if (pickedFile == null) return;

    final File imageFile = File(pickedFile.path);

    setState(() {
      _imageFile = imageFile;
      _photoUrlPreview = null;
      _isSaving = true;
    });

    try {
      final String newPhotoUrl = await _profileService.uploadProfilePicture(imageFile);

      if (mounted) {
        setState(() {
          _photoUrlPreview = newPhotoUrl;
          _imageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil atualizada!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao enviar foto: ${e.toString()}'))
        );
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    // Cores do Tema (Stitch Adaptativo)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color backgroundColor = isDark ? const Color(0xFF102218) : const Color(0xFFF6F8F7);
    final Color textColor = isDark ? Colors.white : const Color(0xFF1C1C1C);
    final Color subTextColor = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF797979);

    final Color inputBackgroundColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);

    const Color primaryColor = Color(0xFF13EC6D);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. HEADER CUSTOMIZADO
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: textColor.withValues(alpha: 0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: textColor.withValues(alpha: 0.9)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text(
                      "Editar Perfil",
                      style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
                  ),
                  _isSaving
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2))
                      : TextButton(
                    onPressed: _saveProfile,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text("Salvar", style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? primaryColor : const Color(0xFF0DA84B))),
                  ),
                ],
              ),
            ),

            // 2. CORPO (FORMULÁRIO)
            Expanded(
              child: FutureBuilder<void>(
                future: _loadDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text("Erro ao carregar dados.", style: TextStyle(color: subTextColor)));
                  }

                  return Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // FOTO DE PERFIL
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primaryColor.withValues(alpha: 0.3), width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.grey.shade800,
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : (_photoUrlPreview != null && _photoUrlPreview!.isNotEmpty)
                                      ? NetworkImage(_photoUrlPreview!)
                                      : null,
                                  child: (_photoUrlPreview == null || _photoUrlPreview!.isEmpty) && _imageFile == null
                                      ? Icon(Icons.person, size: 60, color: subTextColor)
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _isSaving ? null : _showImagePickerOptions,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: backgroundColor, width: 3),
                                    ),
                                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _isSaving ? null : _showImagePickerOptions,
                            child: Text("Alterar foto de perfil", style: GoogleFonts.epilogue(color: primaryColor, fontWeight: FontWeight.bold)),
                          ),

                          const SizedBox(height: 32),

                          // CAMPOS DO FORMULÁRIO
                          _buildStyledTextField(
                            controller: _nameController,
                            label: "Nome Completo",
                            fillColor: inputBackgroundColor, textColor: textColor, hintColor: subTextColor, primaryColor: primaryColor,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
                          ),

                          const SizedBox(height: 16),

                          _buildStyledTextField(
                            controller: _usernameController,
                            label: "Nome de Usuário",
                            prefixText: "@",
                            fillColor: inputBackgroundColor, textColor: textColor, hintColor: subTextColor, primaryColor: primaryColor,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Usuário obrigatório' : null,
                          ),

                          const SizedBox(height: 16),

                          _buildStyledTextField(
                            controller: _bioController,
                            label: "Biografia",
                            maxLines: 4,
                            fillColor: inputBackgroundColor, textColor: textColor, hintColor: subTextColor, primaryColor: primaryColor,
                          ),

                          const SizedBox(height: 16),

                          // CAMPO DE DATA (Customizado)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Data de Nascimento", style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _selectDate,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: inputBackgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _birthDate == null ? "Selecione uma data" : DateFormat('dd/MM/yyyy').format(_birthDate!),
                                        style: GoogleFonts.epilogue(color: textColor, fontSize: 16),
                                      ),
                                      Icon(Icons.calendar_today, color: subTextColor, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // SELETOR DE GÊNERO (Customizado tipo Stitch)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Gênero", style: TextStyle(color: subTextColor, fontSize: 14, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildGenderSelector(textColor, primaryColor, inputBackgroundColor),
                            ],
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    String? prefixText,
    required Color fillColor,
    required Color textColor,
    required Color hintColor,
    required Color primaryColor,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: hintColor, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.epilogue(color: textColor, fontSize: 16),
            cursorColor: primaryColor,
            validator: validator,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: label,
              hintStyle: GoogleFonts.epilogue(color: hintColor.withValues(alpha: 0.5)),
              prefixText: prefixText,
              prefixStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(Color textColor, Color primaryColor, Color fillColor) {
    return Row(
      children: [
        Expanded(child: _buildGenderOption("Masculino", "male", textColor, primaryColor, fillColor)),
        const SizedBox(width: 8),
        Expanded(child: _buildGenderOption("Feminino", "female", textColor, primaryColor, fillColor)),
        const SizedBox(width: 8),
        Expanded(child: _buildGenderOption("Outro", "other", textColor, primaryColor, fillColor)),
      ],
    );
  }

  Widget _buildGenderOption(String label, String value, Color textColor, Color primaryColor, Color fillColor) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.2) : fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.epilogue(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primaryColor : textColor,
          ),
        ),
      ),
    );
  }
}