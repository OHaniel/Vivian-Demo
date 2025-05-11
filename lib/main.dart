import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vivian',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 1; // Traductor como pantalla principal
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPlaying = false;
  final _logger = Logger('MyHomePage');
  final _textController = TextEditingController();
  final List<String> _historialAnimaciones = [];
  String? _animacionActual;
  Timer? _timer;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  Future<void> _startRecording() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'La grabación de audio solo está disponible en Android/iOS.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      if (await Permission.microphone.isGranted) {
        final directory = await getTemporaryDirectory();
        final path =
            '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
        });
      }
    } catch (e) {
      _logger.severe('Error al iniciar la grabación', e);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
      _timer?.cancel();
      _timer = null;
      _recordDuration = 0;
      _logger.info('Audio guardado en: $path');
      // Aquí puedes agregar la lógica para enviar el audio a Unity
    } catch (e) {
      _logger.severe('Error al detener la grabación', e);
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _repeatAnimation([String? animacion]) {
    setState(() {
      _isPlaying = !_isPlaying;
      if (animacion != null) {
        _animacionActual = animacion;
      } else {
        _animacionActual = DateTime.now().toIso8601String();
        _historialAnimaciones.add(_animacionActual!);
      }
    });
    // Aquí puedes agregar la lógica para comunicarte con Unity
    _logger.info('Reproduciendo animación...');
  }

  void _mostrarHistorial() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Historial de animaciones',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (_historialAnimaciones.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No hay animaciones en el historial.'),
              )
            else
              ..._historialAnimaciones.reversed.map((animacion) => ListTile(
                    title: Text('Animación: $animacion'),
                    trailing: IconButton(
                      icon: const Icon(Icons.replay),
                      onPressed: () {
                        Navigator.pop(context);
                        _repeatAnimation(animacion);
                      },
                    ),
                  )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      _logger.info('Enviando texto: $text');
      // Aquí puedes agregar la lógica para enviar el texto a Unity
      // Por ahora solo limpiamos el campo
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: ClipOval(
            child: Image.asset(
              'assets/logo.jpeg',
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.08 * 255).toInt()),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _isPlaying
                      ? "Reproduciendo animación..."
                      : "Avatar de Unity (animaciones)",
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: ElevatedButton.icon(
                        onPressed: _toggleRecording,
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white),
                        label: Text(_isRecording ? "Detener" : "Audio"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isRecording ? Colors.redAccent : Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  if (_isRecording)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        _formatDuration(_recordDuration),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha((0.06 * 255).toInt()),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          prefixIcon:
                              Icon(Icons.message, color: Colors.blueGrey),
                          hintText: "Escribe tu mensaje aquí...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendText(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: ElevatedButton.icon(
                        onPressed: _repeatAnimation,
                        icon: Icon(_isPlaying ? Icons.stop : Icons.replay,
                            color: Colors.white),
                        label: Text(_isPlaying ? "Detener" : "Repetir"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isPlaying ? Colors.green : Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendText,
                  icon: const Icon(Icons.send, size: 22),
                  label: const Text("Enviar", style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Vivian", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.deepPurple),
            tooltip: 'Ver historial',
            onPressed: _mostrarHistorial,
          ),
        ],
      ),
      body: _selectedIndex == 0 ? const AccountScreen() : mainContent,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.08 * 255).toInt()),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: "Cuenta",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.translate),
              label: "Traductor",
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _textController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle, size: 100, color: Colors.blue),
            SizedBox(height: 24),
            Text(
              'Información de la cuenta',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('Nombre: Usuario Ejemplo'),
            Text('Correo: usuario@ejemplo.com'),
            // Puedes agregar más información aquí
          ],
        ),
      ),
    );
  }
}
