import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static final String? _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

  static String? get googleApiKey {
    if (_googleApiKey == null) {
      throw Exception('A chave da API do Google não está definida no .env do projeto!');
    }
    return _googleApiKey;
  }

  static Future<void> loadEnvVariables() async {
    await dotenv.load(fileName: ".env");
  }
}
