import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_model.dart';

class ApiService {
  // ⚠️ IMPORTANTE: Si pruebas en un celular real, cambia 'localhost' por tu IP local
  // Ejemplo: 'http://192.168.1.15:8000/api/games/'
  static const String baseUrl = 'https://aprendo-app-backend.onrender.com/api';

  Future<List<Game>> getGames() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/games/'));

      if (response.statusCode == 200) {
        // Convertimos el JSON que envía Django a una lista de objetos Game
        List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => Game.fromJson(item)).toList();
      } else {
        throw "No se pudo conectar con el servidor";
      }
    } catch (e) {
      throw "Error de red: $e";
    }
  }
}
