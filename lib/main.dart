import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logging/logging.dart';

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
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
  int _selectedIndex =
      0; // Índice para la barra inferior (0: Cuenta, 1: Traductor)
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPlaying = false;
  final _logger = Logger('MyHomePage');
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  Future<void> _startRecording() async {
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

  void _repeatAnimation() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    // Aquí puedes agregar la lógica para comunicarte con Unity
    _logger.info('Reproduciendo animación...');
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Aplicación"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: Center(
                  child: Text(
                    _isPlaying
                        ? "Reproduciendo animación..."
                        : "Avatar de Unity (animaciones)",
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _toggleRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording ? Colors.red : null,
                      ),
                      child: Text(_isRecording ? "Detener" : "Audio"),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: "Escribe tu mensaje aquí...",
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendText(),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    ElevatedButton(
                      onPressed: _repeatAnimation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPlaying ? Colors.green : null,
                      ),
                      child: Text(_isPlaying ? "Detener" : "Repetir"),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _sendText,
                    icon: const Icon(Icons.send),
                    label: const Text("Enviar"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _textController.dispose();
    super.dispose();
  }
}
