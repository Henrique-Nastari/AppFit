// lib/presentation/screens/profile/edit_profile_page.dart - CORRIGIDO (Todos os Erros/Warnings)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // <- Import usado para DateFormat
import '../../../application/profile/profile_service.dart';
import 'dart:io'; // Import para File (será usado no upload de foto)
import 'package:image_picker/image_picker.dart'; // Import para ImagePicker

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

  // Future para carregar os dados iniciais
  late Future<void> _loadDataFuture; // <- AGORA USADO

  @override
  void initState() {
    super.initState();
    _loadDataFuture = _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await _profileService.getUserData(_currentUserId);

      // CORREÇÃO: Verifica se o widget ainda está "montado"
      if (!mounted) return;

      if (data != null) {
        _nameController.text = data['displayName'] ?? '';
        _usernameController.text = data['username'] ?? data['email']?.split('@').first ?? '';
        _bioController.text = data['bio'] ?? '';

        final timestamp = data['birthDate'] as Timestamp?;
        if (timestamp != null) _birthDate = timestamp.toDate();

        _gender = data['gender'];
        _photoUrlPreview = data['photoUrl'];

        // setState é necessário aqui para preencher os campos *depois* do load
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return; // CORREÇÃO: Verifica o mounted
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
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  /// Salva o perfil (AGORA USADO)
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _isSaving) {
      return;
    }
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

  /// Mostra as opções (Câmera ou Galeria)
  Future<void> _showImagePickerOptions() async {
    FocusScope.of(context).unfocus();

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Selecionar da Galeria'),
                onTap: () {
                  Navigator.of(context).pop();
                  _handlePhotoUpload(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tirar Foto com a Câmera'),
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

  /// Lida com a seleção e o upload da imagem
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // CORREÇÃO: withOpacity -> withAlpha (e agora está USADO)
    final inputFillColor = theme.colorScheme.onSurface.withAlpha(13); // 0.05 opacidade
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: theme.colorScheme.onSurface.withAlpha(51), // 0.2 opacidade
      ),
    );
    // CORREÇÃO: Agora está USADO
    final focusedInputBorder = inputBorder.copyWith(
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "Editar Perfil",
          style: GoogleFonts.epilogue(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
              : TextButton(
            onPressed: _saveProfile, // <-- AGORA USADO
            child: Text(
              "Salvar",
              style: GoogleFonts.epilogue(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
      // CORREÇÃO: Usando FutureBuilder para usar _loadDataFuture
      body: FutureBuilder<void>(
        future: _loadDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar dados: ${snapshot.error}"));
          }

          // Constrói o formulário
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  // --- Seção da Foto de Perfil ---
                  CircleAvatar(
                    radius: 64,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_photoUrlPreview != null && _photoUrlPreview!.isNotEmpty)
                        ? NetworkImage(_photoUrlPreview!)
                        : null,
                    child: (_photoUrlPreview == null || _photoUrlPreview!.isEmpty) && _imageFile == null
                        ? Icon(Icons.person, size: 64, color: Colors.grey[600])
                        : null,
                  ),
                  TextButton(
                    onPressed: _isSaving ? null : _showImagePickerOptions,
                    child: Text(
                      "Alterar foto de perfil",
                      style: GoogleFonts.epilogue(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Campos do Formulário ---
                  _buildSectionTitle("Nome Completo"),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputFillColor, // <-- AGORA USADO
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: focusedInputBorder, // <-- AGORA USADO
                      hintText: "Seu nome",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'O nome não pode ficar em branco.';
                      }
                      return null;
                    },
                  ),

                  _buildSectionTitle("Nome de Usuário"),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputFillColor,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: focusedInputBorder,
                      hintText: "username",
                      prefixText: "@",
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'O nome de usuário não pode ficar em branco.';
                      }
                      return null;
                    },
                  ),

                  _buildSectionTitle("Biografia"),
                  TextFormField(
                    controller: _bioController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputFillColor,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: focusedInputBorder,
                      hintText: "Fale um pouco sobre você...",
                    ),
                    maxLines: 4,
                  ),

                  _buildSectionTitle("Data de Nascimento"),
                  TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _birthDate == null  // <-- AGORA USADO
                          ? 'Selecione sua data'
                          : DateFormat('dd/MM/yyyy').format(_birthDate!), // <-- `intl` USADO
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: inputFillColor,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: focusedInputBorder,
                      suffixIcon: Icon(Icons.calendar_month, color: theme.hintColor),
                    ),
                    onTap: _selectDate,
                  ),

                  _buildSectionTitle("Gênero"),
                  _buildGenderSelector(theme), // <-- _gender USADO aqui dentro

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: GoogleFonts.epilogue(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildGenderSelector(ThemeData theme) {
    final Set<String> selection = (_gender != null && ['male', 'female', 'other'].contains(_gender))
        ? <String>{_gender!}
        : <String>{};

    return SegmentedButton<String>(
      segments: const <ButtonSegment<String>>[
        ButtonSegment<String>(value: 'male', label: Text('Masculino'), icon: Icon(Icons.male)),
        ButtonSegment<String>(value: 'female', label: Text('Feminino'), icon: Icon(Icons.female)),
        ButtonSegment<String>(value: 'other', label: Text('Não dizer'), icon: Icon(Icons.close)),
      ],
      selected: selection,
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _gender = newSelection.first;
        });
      },
      multiSelectionEnabled: false,
      emptySelectionAllowed: true, // Corrigido daquele crash antigo
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}