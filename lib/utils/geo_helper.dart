
import 'package:geolocator/geolocator.dart';
import 'dart:math' show cos, sqrt, asin;

// GeoHelper é uma classe utilitária que fornece métodos para determinar a posição atual do usuário e calcular a distância entre coordenadas geográficas. Ela é usada principalmente para validar a localização do usuário durante o processo de check-in, garantindo que ele esteja dentro de um raio permitido em relação ao local do evento.
class GeoHelper {
  // Coordenadas do local do evento e raio permitido para check-in. Para o exemplo o local é fixo. Mas como evolução pode ser implementado uma logca de cadastro de eventos onde cada evento tem suas coordenadas e raio especifico. E esses valores se tornam dinamicos.
  static const double targetLat = 38.745; 
  static const double targetLng = -9.134;
  static const double radiusMeters = 200.0;

  static Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission; // Verifica se o serviço de localização está habilitado. Se não estiver, retorna um erro.

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('GPS desativado.');

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return Future.error('Permissão negada.');
    }
    
    return await Geolocator.getCurrentPosition(); // Retorna a posição atual do usuário.
  }

  // Calcula a distância entre duas coordenadas geográficas usando a fórmula de Haversine. Retorna a distância em metros.
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p) / 2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }
}
