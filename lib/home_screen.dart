import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> visitors = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchVisitors();
    supabase
        .from('visitors')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((data) {
      setState(() {
        visitors = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    });
  }

  Future<void> _fetchVisitors() async {
    final data = await supabase.from('visitors').select().order('created_at');
    setState(() {
      visitors = List<Map<String, dynamic>>.from(data);
      loading = false;
    });
  }

  void _logout() async {
    await supabase.auth.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Visitantes'),
        backgroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo visitante'),
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add');
          if (result == true) {
            _fetchVisitors();
          }
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3E8F7), Color(0xFFF4F6FB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : visitors.isEmpty
                ? const Center(
                    child: Text(
                      'No hay visitantes registrados',
                      style: TextStyle(fontSize: 18, color: Colors.indigo),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: visitors.length,
                    itemBuilder: (context, i) {
                      final v = visitors[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          leading: v['photo_url'] != null
                              ? CircleAvatar(radius: 28, backgroundImage: NetworkImage(v['photo_url']))
                              : const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 28)),
                          title: Text(
                            v['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v['reason'] ?? '',
                                style: const TextStyle(fontSize: 15, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                v['created_at'] != null ? v['created_at'].toString().replaceFirst('T', ' ').substring(0, 16) : '',
                                style: const TextStyle(fontSize: 13, color: Colors.indigo),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class AddVisitorScreen extends StatefulWidget {
  const AddVisitorScreen({super.key});

  @override
  State<AddVisitorScreen> createState() => _AddVisitorScreenState();
}

class _AddVisitorScreenState extends State<AddVisitorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;
  File? _image;
  Uint8List? _webImageBytes;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    XFile? pickedFile;
    if (kIsWeb) {
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
        });
      }
    } else {
      // Mostrar diálogo para elegir cámara o galería
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.indigo),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.indigo),
                title: const Text('Elegir de galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source != null) {
        pickedFile = await picker.pickImage(source: source);
        if (pickedFile != null) {
          setState(() {
            _image = File(pickedFile!.path);
          });
        }
      }
    }
  }

  Future<String?> _uploadImage() async {
    final supabase = Supabase.instance.client;
    final fileName = 'visitor_${DateTime.now().millisecondsSinceEpoch}.jpg';
    dynamic uploadData;
    if (kIsWeb && _webImageBytes != null) {
      uploadData = _webImageBytes;
    } else if (_image != null) {
      uploadData = await _image!.readAsBytes();
    }
    if (uploadData == null) return null;
    final res = await supabase.storage.from('visitor-photos').uploadBinary(fileName, uploadData);
    if (res.isNotEmpty) {
      return supabase.storage.from('visitor-photos').getPublicUrl(fileName);
    }
    return null;
  }

  Future<void> _saveVisitor() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    String? photoUrl;
    if ((kIsWeb && _webImageBytes != null) || (!kIsWeb && _image != null)) {
      photoUrl = await _uploadImage();
    }
    final supabase = Supabase.instance.client;
    await supabase.from('visitors').insert({
      'name': _nameController.text,
      'reason': _reasonController.text,
      'created_at': _selectedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'photo_url': photoUrl,
    });
    Fluttertoast.showToast(msg: 'Visitante registrado');
    _nameController.clear();
    _reasonController.clear();
    setState(() {
      _selectedDate = null;
      _image = null;
      _webImageBytes = null;
      _loading = false;
    });
    // Notificar a la pantalla anterior para que actualice la lista
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Agregar visitante'),
        backgroundColor: Colors.indigo,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: Colors.indigo.withOpacity(0.04),
                  ),
                  validator: (v) => v != null && v.isNotEmpty ? null : 'Campo requerido',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Motivo',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.info_outline),
                    filled: true,
                    fillColor: Colors.indigo.withOpacity(0.04),
                  ),
                  validator: (v) => v != null && v.isNotEmpty ? null : 'Campo requerido',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Selecciona la hora'
                            : 'Hora: ${_selectedDate!.hour.toString().padLeft(2, '0')}:${_selectedDate!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 15, color: Colors.indigo),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.access_time, color: Colors.indigo),
                      label: const Text('Elegir hora', style: TextStyle(color: Colors.indigo)),
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: now.hour, minute: now.minute),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (kIsWeb && _webImageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_webImageBytes!, height: 120, fit: BoxFit.cover),
                  )
                else if (!kIsWeb && _image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_image!, height: 120, fit: BoxFit.cover),
                  )
                else
                  TextButton.icon(
                    icon: const Icon(Icons.camera_alt, color: Colors.indigo),
                    label: const Text('Tomar foto', style: TextStyle(color: Colors.indigo)),
                    onPressed: _pickImage,
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      elevation: 2,
                    ),
                    onPressed: _loading ? null : _saveVisitor,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
