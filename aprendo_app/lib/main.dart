import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:aprendo_app/services/api_service.dart';
import 'package:aprendo_app/models/game_model.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GameListPage(),
    );
  }
}

class GameListPage extends StatefulWidget {
  const GameListPage({super.key});

  @override
  State<GameListPage> createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  final ApiService apiService = ApiService();
  late Future<List<Game>> futureGames;

  @override
  void initState() {
    super.initState();
    futureGames = apiService.getGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Aprendo App - Mis Juegos"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: FutureBuilder<List<Game>>(
        future: futureGames,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No hay juegos disponibles"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final game = snapshot.data![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Text(game.emoji, style: const TextStyle(fontSize: 32)),
                  title: Text(game.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(game.description),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GamePage(idName: game.idName),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  final String idName;
  const GamePage({super.key, required this.idName});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('http://10.0.2.2:8000/game/${widget.idName}/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Jugando...")),
      body: WebViewWidget(controller: controller),
    );
  }
}
