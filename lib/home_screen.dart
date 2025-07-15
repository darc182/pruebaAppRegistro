import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

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
      appBar: AppBar(
        title: const Text('Visitantes'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.pushNamed(context, '/add'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : visitors.isEmpty
              ? const Center(child: Text('No hay visitantes registrados'))
              : ListView.builder(
                  itemCount: visitors.length,
                  itemBuilder: (context, i) {
                    final v = visitors[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: v['photo_url'] != null
                            ? CircleAvatar(backgroundImage: NetworkImage(v['photo_url']))
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(v['name'] ?? ''),
                        subtitle: Text('${v['reason'] ?? ''}\n${v['created_at'] ?? ''}'),
                      ),
                    );
                  },
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
      pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile!.path);
        });
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
    setState(() => _loading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar visitante'), backgroundColor: Colors.indigo),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Campo requerido',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(labelText: 'Motivo', border: OutlineInputBorder()),
                validator: (v) => v != null && v.isNotEmpty ? null : 'Campo requerido',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(_selectedDate == null
                        ? 'Selecciona la hora'
                        : 'Hora: ${_selectedDate!.hour}:${_selectedDate!.minute}'),
                  ),
                  TextButton(
                    child: const Text('Elegir hora'),
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
                Image.memory(_webImageBytes!, height: 120)
              else if (!kIsWeb && _image != null)
                Image.file(_image!, height: 120)
              else
                TextButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Tomar foto'),
                  onPressed: _pickImage,
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: _loading ? null : _saveVisitor,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
