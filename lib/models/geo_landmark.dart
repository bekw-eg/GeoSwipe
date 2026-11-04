import 'dart:math' as math;

class GeoLandmark {
  const GeoLandmark({
    required this.id,
    required this.name,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.geometryType,
    required this.description,
    required this.mathFact,
    required this.bonusPoints,
  });

  final String id;
  final String name;
  final String city;
  final double latitude;
  final double longitude;
  final String geometryType;
  final String description;
  final String mathFact;
  final int bonusPoints;

  /// Haversine formula to compute distance in kilometers between two GPS coordinates
  double distanceTo(double userLat, double userLng) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(latitude - userLat);
    final dLng = _degreesToRadians(longitude - userLng);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(userLat)) *
            math.cos(_degreesToRadians(latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Format distance into user-friendly text (e.g., '1.2 км' or '350 м')
  String formatDistanceTo(double userLat, double userLng) {
    final km = distanceTo(userLat, userLng);
    if (km < 1.0) {
      return '${(km * 1000).round()} м';
    }
    return '${km.toStringAsFixed(1)} км';
  }

  static double _degreesToRadians(double degrees) =>
      degrees * (math.pi / 180.0);
}

/// Catalog of famous architectural structures showcasing geometric figures
const List<GeoLandmark> kGeometricLandmarks = [
  GeoLandmark(
    id: 'nur-alem-sphere',
    name: '«Нұр Әлем» сферасы',
    city: 'Астана',
    latitude: 51.0899,
    longitude: 71.4172,
    geometryType: 'Сфера (Диаметрі 80 м)',
    description: 'Дүние жүзіндегі ең үлкен біртұтас шар тәрізді сәулет кешені.',
    mathFact: 'Шар бетінің ауданы S = 4πR² = πD² ≈ 20 106 м² құрайды.',
    bonusPoints: 50,
  ),
  GeoLandmark(
    id: 'peace-pyramid',
    name: 'Бейбітшілік және келісім сарайы',
    city: 'Астана',
    latitude: 51.1228,
    longitude: 71.4636,
    geometryType: 'Дұрыс төртбұрышты пирамида',
    description: 'Норман Фостер салған таза 62x62 метрлік дұрыс пирамида.',
    mathFact:
        'Пирамида қырларының көлбеу бұрышы 60°-тық теңқабырғалы үшбұрыш жасайды.',
    bonusPoints: 60,
  ),
  GeoLandmark(
    id: 'khan-shatyr',
    name: '«Хан Шатыр» кешені',
    city: 'Астана',
    latitude: 51.1325,
    longitude: 71.4037,
    geometryType: 'Эллиптикалық гиперболоид',
    description: 'Әлемдегі ең үлкен созылмалы шатыр пішінді сәулет құрылымы.',
    mathFact:
        'Гиперболоид қимасы математикалық гиперболалар мен эллипстер жиынынан тұрады.',
    bonusPoints: 55,
  ),
  GeoLandmark(
    id: 'bayterek-tower',
    name: '«Бәйтерек» монументі',
    city: 'Астана',
    latitude: 51.1283,
    longitude: 71.4305,
    geometryType: 'Цилиндрлік діңгек + Сфера',
    description: 'Биіктігі 97 метрлік діңгек және диаметрі 22 метр алтын шар.',
    mathFact: 'Шар көлемі V = (4/3)πR³ ≈ 5 575 м³ тең.',
    bonusPoints: 45,
  ),
  GeoLandmark(
    id: 'kaznu-math',
    name: 'ҚазҰУ Мех-Мат қалашығы',
    city: 'Алматы',
    latitude: 43.2241,
    longitude: 76.9248,
    geometryType: 'Фракталдық кампус геометриясы',
    description:
        'Әл-Фараби атындағы ҚазҰУ математика және геометрия ғылыми ордасы.',
    mathFact: 'Евклидтік және Римандық кеңістік геометриясын зерттеу орталығы.',
    bonusPoints: 70,
  ),
];
