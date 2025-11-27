// lib/presentation/screens/feed/create_post_page.dart - VERSÃO FINAL COMPLETA (Com Edição de Local)

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../application/feed/post_service.dart';
import '../../../models/workout.dart';
import '../../../services/firestore_repository.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  // --- LÓGICA DO FORMULÁRIO ---
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  final _durationController = TextEditingController();
  final _volumeController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _moodController = TextEditingController();

  final List<_ExerciseFormData> _exercises = [];
  bool _isSubmitting = false;
  bool _isLoadingLocation = false;

  final PostService _postService = PostService();
  final FirestoreRepository _firestoreRepository = FirestoreRepository();
  Workout? _selectedWorkout;
  File? _imageFile;
  String? _location; // Armazena o texto da localização
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (_exercises.isEmpty) {
      _addExercise();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    _durationController.dispose();
    _volumeController.dispose();
    _caloriesController.dispose();
    _moodController.dispose();
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  // --- MÉTODOS DE LOCALIZAÇÃO ---

  // 1. Buscar GPS
  Future<void> _getLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('O serviço de localização está desativado.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Permissão de localização negada.');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Permissão negada permanentemente.');

      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "${place.thoroughfare ?? place.subLocality ?? ''}, ${place.subAdministrativeArea ?? place.locality ?? ''}";
        if (address.startsWith(", ")) address = address.substring(2);
        if (address.endsWith(", ")) address = address.substring(0, address.length - 2);
        if (address.trim().isEmpty) address = "Minha localização";

        setState(() {
          _location = address;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao obter local: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  // 2. Editar Manualmente
  Future<void> _editLocation() async {
    final controller = TextEditingController(text: _location);

    // Cores para o Dialog (Adaptativas)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF102218) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1C1C1C);
    final primaryColor = const Color(0xFF13EC6D);

    final newLocation = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        title: Text("Editar Localização", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: textColor),
          cursorColor: primaryColor,
          decoration: InputDecoration(
            hintText: "Ex: Smart Fit - Paulista",
            hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textColor.withValues(alpha: 0.3))),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: TextStyle(color: textColor.withValues(alpha: 0.6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text("Salvar", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newLocation != null && newLocation.isNotEmpty) {
      setState(() {
        _location = newLocation;
      });
    }
  }

  // 3. Remover Localização
  void _removeLocation() {
    setState(() {
      _location = null;
    });
  }

  // --- OUTROS MÉTODOS LÓGICOS ---

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _showImagePickerOptions() async {
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
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera, color: txtColor),
                title: Text('Câmera', style: TextStyle(color: txtColor)),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openWorkoutPicker() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF102218) : const Color(0xFFF6F8F7);
    final txtColor = isDark ? Colors.white : const Color(0xFF1C1C1C);
    final subTxtColor = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF797979);

    final selected = await showModalBottomSheet<Workout>(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Selecione um Treino", style: GoogleFonts.epilogue(color: txtColor, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  child: StreamBuilder<List<Workout>>(
                    stream: _firestoreRepository.listWorkouts(ownerId: user.uid, limit: 50),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final workouts = snapshot.data!;
                      if (workouts.isEmpty) return Center(child: Text("Nenhum treino salvo.", style: TextStyle(color: subTxtColor)));

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: workouts.length,
                        separatorBuilder: (_, __) => Divider(color: theme.dividerColor),
                        itemBuilder: (context, index) {
                          final workout = workouts[index];
                          return ListTile(
                            title: Text(workout.title, style: TextStyle(color: txtColor, fontWeight: FontWeight.bold)),
                            subtitle: Text("${workout.exercises.length} exercícios", style: TextStyle(color: subTxtColor)),
                            onTap: () => Navigator.of(bottomSheetContext).pop(workout),
                            tileColor: txtColor.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      _applyWorkoutTemplate(selected);
    }
  }

  void _applyWorkoutTemplate(Workout workout) {
    final newExercises = workout.exercises.isEmpty
        ? <_ExerciseFormData>[_ExerciseFormData()]
        : workout.exercises.map(_ExerciseFormData.fromWorkoutExercise).toList();

    for (final exercise in _exercises) exercise.dispose();

    setState(() {
      _selectedWorkout = workout;
      if (_titleController.text.isEmpty) _titleController.text = workout.title;
      _exercises..clear()..addAll(newExercises);
    });
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() { _isSubmitting = true; });

    try {
      final postData = _buildPostData();
      await _postService.publishPost(postData: postData, imageFile: _imageFile);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Postado com sucesso!')));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $error')));
    } finally {
      if (mounted) setState(() { _isSubmitting = false; });
    }
  }

  Map<String, dynamic> _buildPostData() {
    final exercises = _exercises.map((e) => e.toMap()).where((m) => m['name'] != null).toList();
    final metrics = <String, dynamic>{};

    if (_durationController.text.isNotEmpty) metrics['DuracaoMin'] = int.tryParse(_durationController.text);
    if (_volumeController.text.isNotEmpty) metrics['VolumeKg'] = double.tryParse(_volumeController.text);
    if (_caloriesController.text.isNotEmpty) metrics['Calorias'] = int.tryParse(_caloriesController.text);
    if (_moodController.text.isNotEmpty) metrics['Humor'] = _moodController.text;

    return {
      'workoutTitle': _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
      'caption': _captionController.text.trim().isNotEmpty ? _captionController.text.trim() : null,
      'location': _location, // Salva a localização
      'exercises': exercises,
      'metrics': metrics.isEmpty ? null : metrics,
    };
  }

  void _addExercise() => setState(() => _exercises.add(_ExerciseFormData()));

  void _removeExercise(int index) {
    if (_exercises.length <= 1) return;
    setState(() => _exercises.removeAt(index).dispose());
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
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
            // HEADER
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
                  Text("Nova Publicação", style: GoogleFonts.epilogue(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                  _isSubmitting
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2))
                      : TextButton(
                    onPressed: _handleSubmit,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text("Publicar", style: GoogleFonts.epilogue(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? primaryColor : const Color(0xFF0DA84B))),
                  ),
                ],
              ),
            ),

            // CORPO DO FORMULÁRIO
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SELEÇÃO DE FOTO E LEGENDA
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _showImagePickerOptions,
                            child: Container(
                              width: 100, height: 100,
                              decoration: BoxDecoration(
                                color: inputBackgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: textColor.withValues(alpha: 0.2)),
                              ),
                              child: _imageFile != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(_imageFile!, fit: BoxFit.cover))
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, color: primaryColor),
                                  Text("Foto", style: TextStyle(color: primaryColor, fontSize: 10))
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                _buildStyledTextField(
                                  controller: _captionController,
                                  hint: "Escreva uma legenda...",
                                  maxLines: 3,
                                  fillColor: inputBackgroundColor,
                                  textColor: textColor,
                                  hintColor: subTextColor,
                                  primaryColor: primaryColor,
                                ),

                                // --- BOTÃO DE LOCALIZAÇÃO (Conectado e Editável) ---
                                const SizedBox(height: 8),
                                _buildLocationButton(inputBackgroundColor, textColor, primaryColor),
                                // ----------------------------
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Divider(color: textColor.withValues(alpha: 0.1)),
                      const SizedBox(height: 12),

                      // BOTÃO DE IMPORTAR TREINO
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openWorkoutPicker,
                          icon: Icon(Icons.library_books, color: primaryColor),
                          label: Text("Carregar Treino Salvo", style: TextStyle(color: textColor)),
                          style: OutlinedButton.styleFrom(
                              side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Text("Detalhes do Treino", style: GoogleFonts.epilogue(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      _buildStyledTextField(
                        controller: _titleController,
                        hint: "Título do Treino (ex: Peito e Tríceps)",
                        isBold: true,
                        fillColor: inputBackgroundColor,
                        textColor: textColor,
                        hintColor: subTextColor,
                        primaryColor: primaryColor,
                      ),

                      const SizedBox(height: 16),
                      ..._buildExerciseForms(inputBackgroundColor, textColor, subTextColor, primaryColor, backgroundColor),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _addExercise,
                        icon: Icon(Icons.add, color: subTextColor),
                        label: Text("Adicionar Exercício", style: TextStyle(color: subTextColor)),
                      ),
                      const SizedBox(height: 24),
                      Text("Métricas", style: GoogleFonts.epilogue(color: primaryColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _buildPickerInput("Duração", _durationController, false, 300, "min", inputBackgroundColor, textColor, subTextColor, primaryColor, backgroundColor)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildPickerInput("Volume", _volumeController, true, 10000, "kg", inputBackgroundColor, textColor, subTextColor, primaryColor, backgroundColor)),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _buildPickerInput("Calorias", _caloriesController, false, 2000, "kcal", inputBackgroundColor, textColor, subTextColor, primaryColor, backgroundColor)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStyledTextField(controller: _moodController, hint: "Humor/Energia", fillColor: inputBackgroundColor, textColor: textColor, hintColor: subTextColor, primaryColor: primaryColor)),
                      ]),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES ---

  // Widget para o Botão de Localização (INTELIGENTE: GPS + EDIÇÃO)
  Widget _buildLocationButton(Color fillColor, Color textColor, Color primaryColor) {
    return GestureDetector(
      // Lógica Inteligente: Se null, busca GPS. Se existe, edita texto.
      onTap: _location == null ? _getLocation : _editLocation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
          border: _location != null ? Border.all(color: primaryColor.withValues(alpha: 0.3)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoadingLocation)
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
            else
              Icon(
                _location != null ? Icons.location_on : Icons.add_location_alt_outlined,
                size: 16,
                color: _location != null ? primaryColor : textColor.withValues(alpha: 0.5),
              ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _location ?? "Adicionar Localização",
                style: TextStyle(
                  color: _location != null ? primaryColor : textColor.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (_location != null) ...[
              const SizedBox(width: 8),
              // Botão X separado para remover (com HitTestBehavior para garantir o clique)
              GestureDetector(
                onTap: _removeLocation,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(Icons.close, size: 16, color: textColor.withValues(alpha: 0.5)),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hint,
    required Color fillColor,
    required Color textColor,
    required Color hintColor,
    required Color primaryColor,
    int maxLines = 1,
    bool isBold = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.epilogue(
          color: textColor,
          fontSize: 16,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        ),
        cursorColor: primaryColor,
        validator: validator,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.epilogue(color: hintColor),
        ),
      ),
    );
  }

  Widget _buildPickerInput(
      String hint,
      TextEditingController controller,
      bool isDecimal,
      double max,
      String suffix,
      Color fillColor,
      Color textColor,
      Color hintColor,
      Color primaryColor,
      Color backgroundColor) {
    return GestureDetector(
      onTap: () => _showWheelPicker(
          title: hint,
          controller: controller,
          isDecimal: isDecimal,
          max: max,
          suffix: suffix,
          backgroundColor: backgroundColor,
          textColor: textColor,
          primaryColor: primaryColor
      ),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: IgnorePointer(
                child: TextFormField(
                  controller: controller,
                  style: GoogleFonts.epilogue(color: textColor, fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: GoogleFonts.epilogue(color: hintColor),
                  ),
                ),
              ),
            ),
            Icon(Icons.unfold_more, color: hintColor, size: 18),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExerciseForms(Color fillColor, Color textColor, Color hintColor, Color primaryColor, Color backgroundColor) {
    return List<Widget>.generate(_exercises.length, (index) {
      final exercise = _exercises[index];
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: fillColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStyledTextField(
                      controller: exercise.nameController,
                      hint: "Nome do Exercício",
                      isBold: true,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                      fillColor: fillColor, textColor: textColor, hintColor: hintColor, primaryColor: primaryColor
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _removeExercise(index),
                )
              ],
            ),
            const SizedBox(height: 8),
            _buildStyledTextField(controller: exercise.notesController, hint: "Notas (opcional)", fillColor: fillColor, textColor: textColor, hintColor: hintColor, primaryColor: primaryColor),
            const SizedBox(height: 12),

            ...List.generate(exercise.sets.length, (setIndex) {
              final setForm = exercise.sets[setIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text("${setIndex + 1}", style: TextStyle(color: hintColor, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPickerInput("Reps", setForm.repsController, false, 100, "", fillColor, textColor, hintColor, primaryColor, backgroundColor)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildPickerInput("Kg", setForm.weightController, true, 500, "kg", fillColor, textColor, hintColor, primaryColor, backgroundColor)),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: hintColor),
                      onPressed: () => setState(() => exercise.removeSet(setIndex)),
                    )
                  ],
                ),
              );
            }),
            TextButton(
              onPressed: () => setState(() => exercise.addSet()),
              child: Text("+ Adicionar Série", style: TextStyle(color: primaryColor)),
            )
          ],
        ),
      );
    });
  }

  void _showWheelPicker({
    required String title,
    required TextEditingController controller,
    required bool isDecimal,
    required double max,
    required Color backgroundColor,
    required Color textColor,
    required Color primaryColor,
    String suffix = '',
  }) {
    List<String> values;
    if (isDecimal) {
      values = List.generate((max * 2).toInt() + 1, (i) => (i / 2).toString());
    } else {
      values = List.generate(max.toInt() + 1, (i) => i.toString());
    }

    int initialIndex = 0;
    try {
      double current = double.parse(controller.text);
      if (isDecimal) initialIndex = (current * 2).toInt();
      else initialIndex = current.toInt();
    } catch (_) {}

    if (initialIndex < 0) initialIndex = 0;
    if (initialIndex >= values.length) initialIndex = values.length - 1;

    final FixedExtentScrollController scrollController =
    FixedExtentScrollController(initialItem: initialIndex);

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      builder: (BuildContext context) {
        return SizedBox(
          height: 250,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: textColor.withValues(alpha: 0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("OK", style: TextStyle(color: primaryColor)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: scrollController,
                  magnification: 1.22,
                  squeeze: 1.2,
                  useMagnifier: true,
                  itemExtent: 32,
                  onSelectedItemChanged: (int selectedItem) {
                    controller.text = values[selectedItem];
                  },
                  children: values.map((val) => Center(
                    child: Text(
                      "$val $suffix",
                      style: TextStyle(color: textColor),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// CLASSES HELPER (MANTIDAS)
class _ExerciseFormData {
  _ExerciseFormData({String? initialName, String? initialNotes, List<_SetFormData>? initialSets}) {
    if (initialName != null) nameController.text = initialName;
    if (initialNotes != null) notesController.text = initialNotes;
    if (initialSets != null) sets.addAll(initialSets); else addSet();
  }
  factory _ExerciseFormData.fromWorkoutExercise(Exercise exercise) {
    final initialSets = exercise.sets.isEmpty ? null : exercise.sets.map(_SetFormData.fromSetEntry).toList();
    return _ExerciseFormData(initialName: exercise.name, initialNotes: exercise.notes, initialSets: initialSets);
  }
  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final List<_SetFormData> sets = [];
  void addSet({_SetFormData? set}) => sets.add(set ?? _SetFormData());
  void removeSet(int index) { if (sets.length > 1) sets.removeAt(index).dispose(); }
  Map<String, dynamic> toMap() {
    final name = nameController.text.trim();
    if (name.isEmpty) return {};
    final notes = notesController.text.trim();
    final setsMap = sets.map((set) => set.toMap()).where((map) => map.isNotEmpty).toList();
    return {'name': name, if (notes.isNotEmpty) 'notes': notes, if (setsMap.isNotEmpty) 'sets': setsMap};
  }
  void dispose() { nameController.dispose(); notesController.dispose(); for (final set in sets) set.dispose(); }
}

class _SetFormData {
  _SetFormData({int? reps, double? weight, double? distance, int? duration, double? rpe}) {
    if (reps != null) repsController.text = reps.toString();
    if (weight != null) weightController.text = weight.toString();
  }
  factory _SetFormData.fromSetEntry(SetEntry entry) => _SetFormData(reps: entry.reps, weight: entry.weightKg);
  final TextEditingController repsController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  Map<String, dynamic> toMap() {
    final reps = int.tryParse(repsController.text.trim());
    final weight = double.tryParse(weightController.text.trim());
    return {if (reps != null) 'reps': reps, if (weight != null) 'weight': weight};
  }
  void dispose() { repsController.dispose(); weightController.dispose(); }
}