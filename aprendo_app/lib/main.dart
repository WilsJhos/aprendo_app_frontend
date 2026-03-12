import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:aprendo_app/services/api_service.dart';
import 'package:aprendo_app/models/game_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const AprendoApp());
}

class AprendoApp extends StatelessWidget {
  const AprendoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aprendo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const GameListPage(),
    );
  }
}

// ── MODEL FOR STATS ──
class GameStat {
  final String id;
  final String name;
  final String emoji;
  final int sessions;
  final int totalScore;
  final int bestScore;
  final String lastPlayed;

  GameStat({
    required this.id,
    required this.name,
    required this.emoji,
    required this.sessions,
    required this.totalScore,
    required this.bestScore,
    required this.lastPlayed,
  });

  factory GameStat.fromJson(String id, Map<String, dynamic> json) {
    return GameStat(
      id: id,
      name: json['name'] ?? id,
      emoji: json['emoji'] ?? '🎮',
      sessions: json['sessions'] ?? 0,
      totalScore: json['totalScore'] ?? 0,
      bestScore: json['bestScore'] ?? 0,
      lastPlayed: json['lastPlayed'] ?? '',
    );
  }
}

// ── GAME LIST PAGE ──
class GameListPage extends StatefulWidget {
  const GameListPage({super.key});

  @override
  State<GameListPage> createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  final ApiService apiService = ApiService();
  late Future<List<Game>> futureGames;
  List<GameStat> rankingStats = [];

  @override
  void initState() {
    super.initState();
    futureGames = apiService.getGames();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('gstat_'));
    final stats = <GameStat>[];

    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final id = key.replaceFirst('gstat_', '');
        if ((json['sessions'] ?? 0) > 0) {
          stats.add(GameStat.fromJson(id, json));
        }
      } catch (_) {}
    }

    stats.sort((a, b) => b.sessions.compareTo(a.sessions));
    if (mounted) setState(() => rankingStats = stats);
  }

  void _refreshStats() => _loadStats();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: CustomScrollView(
        slivers: [
          // ── APP BAR ──
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: const Color(0xFF1A1640),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                '🌈 Aprendo App',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C63FF), Color(0xFF302B63), Color(0xFF0F0C29)],
                  ),
                ),
                child: const Center(
                  child: Text('🎓', style: TextStyle(fontSize: 60)),
                ),
              ),
            ),
          ),

          // ── RANKING PANEL ──
          if (rankingStats.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🏆 Ranking de Juegos',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFFec4899)],
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text('TU PROGRESO',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: rankingStats.length,
                        itemBuilder: (context, i) {
                          final g = rankingStats[i];
                          final medals = ['🥇', '🥈', '🥉'];
                          final medalColors = [
                            const Color(0xFFFFD700),
                            const Color(0xFFC0C0C0),
                            const Color(0xFFCD7F32),
                          ];
                          final borderCol = i < 3 ? medalColors[i] : const Color(0xFF6C63FF);

                          return Container(
                            width: 155,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              border: Border.all(color: borderCol, width: 1.5),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(i < 3 ? medals[i] : '${i + 1}',
                                    style: const TextStyle(fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(g.emoji, style: const TextStyle(fontSize: 24)),
                                const SizedBox(height: 4),
                                Text(g.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                _statRow('🎮', 'Sesiones', '${g.sessions}'),
                                _statRow('⭐', 'Mejor', '${g.bestScore}'),
                                if (g.lastPlayed.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text('Último: ${g.lastPlayed}',
                                        style: const TextStyle(
                                            color: Color(0x99FFFFFF), fontSize: 9)),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

          if (rankingStats.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🏆 Ranking de Juegos',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        border: Border.all(color: const Color(0x1AFFFFFF)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Aún no has jugado ningún juego. ¡Empieza a explorar! 🚀',
                        style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── SECTION TITLE ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                children: [
                  const Text('🎮 Juegos Disponibles',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),

          // ── GAME GRID ──
          FutureBuilder<List<Game>>(
            future: futureGames,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  ),
                );
              } else if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('Error al cargar juegos',
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            futureGames = apiService.getGames();
                          }),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No hay juegos disponibles',
                        style: TextStyle(color: Colors.white70)),
                  ),
                );
              }

              final games = snapshot.data!;
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final game = games[index];
                      final stat = rankingStats.firstWhere(
                        (s) => s.id == game.idName,
                        orElse: () => GameStat(
                            id: '', name: '', emoji: '', sessions: 0,
                            totalScore: 0, bestScore: 0, lastPlayed: ''),
                      );
                      return _GameCard(
                        game: game,
                        stat: stat.sessions > 0 ? stat : null,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GamePage(
                                idName: game.idName,
                                gameTitle: game.title,
                              ),
                            ),
                          );
                          _refreshStats();
                        },
                      );
                    },
                    childCount: games.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _statRow(String icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$icon $label',
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ── GAME CARD WIDGET ──
class _GameCard extends StatelessWidget {
  final Game game;
  final GameStat? stat;
  final VoidCallback onTap;

  const _GameCard({required this.game, required this.stat, required this.onTap});

  // Map game to gradient colors
  static const Map<int, List<Color>> _gradients = {
    0: [Color(0xFF6C63FF), Color(0xFF9B59B6)],
    1: [Color(0xFF43E97B), Color(0xFF38F9D7)],
    2: [Color(0xFFFA709A), Color(0xFFFEE140)],
    3: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
    4: [Color(0xFFF7971E), Color(0xFFFFD200)],
    5: [Color(0xFFB06EFF), Color(0xFF6C63FF)],
    6: [Color(0xFFFF6584), Color(0xFFFC5C7D)],
  };

  @override
  Widget build(BuildContext context) {
    final gradIdx = game.idName.hashCode.abs() % _gradients.length;
    final colors = _gradients[gradIdx]!;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors[0].withOpacity(0.15), colors[1].withOpacity(0.08)],
          ),
          border: Border.all(color: colors[0].withOpacity(0.35), width: 1.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors[0].withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Center(
                      child: Builder(builder: (_) {
                        // Override emoji for specific games that were updated server-side
                        final displayEmoji = (game.idName == 'rutinas' || game.idName == 'rutina') ? '🍎' : game.emoji;
                        return Text(displayEmoji, style: const TextStyle(fontSize: 30));
                      }),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(game.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(game.description,
                      style: const TextStyle(
                          color: Color(0x80FFFFFF), fontSize: 10),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            // Sessions badge
            if (stat != null)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '${stat!.sessions} ${stat!.sessions == 1 ? "sesión" : "sesiones"}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── GAME PAGE (WebView) ──
class GamePage extends StatefulWidget {
  final String idName;
  final String gameTitle;
  const GamePage({super.key, required this.idName, required this.gameTitle});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final WebViewController controller;
  bool isLoading = true;
  late final FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    // Initialize TTS asynchronously to ensure plugin is ready on Android
    _initTts();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F0C29))
      ..addJavaScriptChannel(
        'FlutterStorage',
        onMessageReceived: (msg) async {
          // Handle game stats sent from the game's JS and surface JS errors/logs
          try {
            // Print raw message to flutter logs for debugging
            // ignore: avoid_print
            print('[DEBUG][FlutterStorage] message: ' + msg.message);
            // Try to parse as JSON stats and persist
            final data = jsonDecode(msg.message);
            if (data is Map<String, dynamic>) {
              final key = 'gstat_${widget.idName}';
              final prefs = await SharedPreferences.getInstance();
              prefs.setString(key, jsonEncode(data));
            }
          } catch (e) {
            print('[DEBUG][FlutterStorage] parse/error: $e');
            // ignore parsing errors, message may be a debug/error string
          }
        },
      )
      ..addJavaScriptChannel(
        'FlutterTTS',
        onMessageReceived: (msg) async {
          try {
            final raw = msg.message;
            // Debug log incoming TTS payload
            // ignore: avoid_print
            print('[DEBUG][FlutterTTS] received: ' + raw);
            String text = raw;
            double rate = 0.9;
            double pitch = 1.0;
            try {
              final parsed = jsonDecode(raw);
              if (parsed is Map) {
                text = parsed['text']?.toString() ?? raw;
                rate = (parsed['rate'] is num) ? (parsed['rate'] as num).toDouble() : rate;
                pitch = (parsed['pitch'] is num) ? (parsed['pitch'] as num).toDouble() : pitch;
              }
            } catch (_) {}
            // Debug settings
            // ignore: avoid_print
            print('[DEBUG][FlutterTTS] speak params -> text: "${text}", rate: ${rate}, pitch: ${pitch}');
            await flutterTts.setSpeechRate(rate);
            await flutterTts.setPitch(pitch);
            await flutterTts.speak(text);
          } catch (_) {}
        },
      )
      ..addJavaScriptChannel(
        'FlutterTTS_Cancel',
        onMessageReceived: (msg) async {
          try {
            await flutterTts.stop();
          } catch (_) {}
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_){
            // Debug: page started
            // ignore: avoid_print
            print('[DEBUG][WebView] onPageStarted: ${widget.idName}');
            setState(() => isLoading = true);
          },
          onPageFinished: (_){
            // Debug: page finished
            // ignore: avoid_print
            print('[DEBUG][WebView] onPageFinished: ${widget.idName}');
            setState(() => isLoading = false);
            // Inject JS to sync localStorage stats to Flutter via FlutterStorage
            controller.runJavaScript('''
              (function() {
                const key = 'gstat_${widget.idName}';
                setInterval(function() {
                  const raw = localStorage.getItem(key);
                  if (raw && window.FlutterStorage) {
                    try {
                      FlutterStorage.postMessage(raw);
                    } catch(e) {}
                  }
                }, 5000);
              })();
            ''');
            // Inject error and console forwarding so Flutter can log JS errors
            controller.runJavaScript('''
              (function() {
                function forward(msg){ try { if(window.FlutterStorage) FlutterStorage.postMessage('[JS] '+msg); } catch(e){} }
                window.onerror = function(msg, src, line, col, err) { forward('ERROR: '+msg+' at '+src+':'+line+':'+col); };
                const origErr = console.error;
                console.error = function(){ try { forward('CONSOLE ERROR: '+Array.from(arguments).join(' | ')); } catch(e){}; if(origErr) origErr.apply(console, arguments); };
                const origLog = console.log;
                console.log = function(){ try { forward('CONSOLE LOG: '+Array.from(arguments).join(' | ')); } catch(e){}; if(origLog) origLog.apply(console, arguments); };
              })();
            ''');
            // Debug: JS forwarding injected
            // ignore: avoid_print
            print('[DEBUG][WebView] injected JS forwarding for ${widget.idName}');
            // Inject Web Speech API interceptor to route native TTS to Flutter
            controller.runJavaScript('''
              (function() {
                // Keep the old helper just in case
                window.speak = function(text, rate, pitch) {
                  try {
                    const payload = JSON.stringify({text: text, rate: rate, pitch: pitch});
                    if (window.FlutterTTS) FlutterTTS.postMessage(payload);
                  } catch(e) {
                    try { if (window.FlutterTTS) FlutterTTS.postMessage(text); } catch(_) {}
                  }
                };

                // Polyfill SpeechSynthesisUtterance if not supported
                if (typeof window.SpeechSynthesisUtterance === 'undefined') {
                  window.SpeechSynthesisUtterance = function(text) {
                    this.text = text || '';
                    this.rate = 1.0;
                    this.pitch = 1.0;
                    this.volume = 1.0;
                    this.lang = 'es-ES';
                  };
                }

                // Intercept window.speechSynthesis
                if (!window.speechSynthesis) {
                  window.speechSynthesis = {};
                }
                const originalSpeak = window.speechSynthesis.speak;
                const originalCancel = window.speechSynthesis.cancel;
                
                window.speechSynthesis.getVoices = function() {
                  return [{
                    default: true,
                    lang: 'es-ES',
                    localService: true,
                    name: 'Flutter TTS (es-ES)',
                    voiceURI: 'Flutter TTS (es-ES)'
                  }];
                };
                
                window.speechSynthesis.speak = function(utterance) {
                  if (window.FlutterTTS) {
                    try {
                      let r = utterance.rate !== undefined ? utterance.rate : 0.9;
                      let p = utterance.pitch !== undefined ? utterance.pitch : 1.0;
                      // Fallback when values are somehow invalid
                      if (isNaN(r) || r <= 0) r = 1.0;
                      if (isNaN(p) || p <= 0) p = 1.0;

                      const payload = JSON.stringify({ text: utterance.text, rate: r, pitch: p });
                      FlutterTTS.postMessage(payload);
                      
                      // Emulate Web Speech API events for game logic
                      if (utterance.onstart) {
                        setTimeout(function() { utterance.onstart({ type: 'start', utterance: utterance }); }, 50);
                      }
                      if (utterance.onend) {
                        // rough estimation: ~80ms per char
                        const durationMs = Math.max(1000, (utterance.text.length * 80) / r);
                        setTimeout(function() { utterance.onend({ type: 'end', utterance: utterance }); }, durationMs);
                      }
                    } catch(e) {
                      try { FlutterTTS.postMessage(utterance.text || ''); } catch(_) {}
                    }
                  } else if (originalSpeak) {
                    originalSpeak.call(window.speechSynthesis, utterance);
                  }
                };
                
                window.speechSynthesis.cancel = function() {
                  try {
                    if (window.FlutterTTS_Cancel) {
                      FlutterTTS_Cancel.postMessage('cancel');
                    }
                  } catch(e) {}
                  if (originalCancel) {
                    try { originalCancel.call(window.speechSynthesis); } catch(e){}
                  }
                };
              })();
            ''');
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://aprendo-app-backend.onrender.com/game/${widget.idName}/'),
      );
  }

  Future<void> _initTts() async {
    flutterTts = FlutterTts();
    try {
      // Configurar idioma español
      await flutterTts.setLanguage('es-ES');
      await flutterTts.awaitSpeakCompletion(true);
      await flutterTts.setSpeechRate(0.9);
      await flutterTts.setPitch(1.0);
      await flutterTts.setVolume(1.0);
      
      // Intentar usar el motor Google Text-to-Speech si está disponible
      await flutterTts.setEngine('com.google.android.tts');

      flutterTts.setStartHandler(() {
        print('[TTS] Iniciando síntesis de voz');
      });
      flutterTts.setCompletionHandler(() {
        print('[TTS] Síntesis completada');
      });
      flutterTts.setErrorHandler((msg) {
        print('[TTS] Error: $msg');
      });
      
      print('[TTS] Inicialización completada correctamente');
    } catch (e) {
      print('[TTS] Error durante la inicialización: $e');
      // Intentar inicializar con configuración mínima como fallback
      try {
        await flutterTts.setLanguage('es-ES');
        print('[TTS] Configuración mínima de fallback completada');
      } catch (fallbackError) {
        print('[TTS] Error en fallback: $fallbackError');
      }
    }
  }

  @override
  void dispose() {
    try { flutterTts.stop(); } catch (_) {}
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1640),
        title: Text(
          widget.gameTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            onPressed: () => controller.reload(),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          // Floating back button for easier access on mobile
          Positioned(
            top: 70,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: const [
                    Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Atrás', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: const Color(0xFF0F0C29),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎮', style: TextStyle(fontSize: 60)),
                    SizedBox(height: 20),
                    CircularProgressIndicator(color: Color(0xFF6C63FF)),
                    SizedBox(height: 16),
                    Text('Cargando juego...',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
