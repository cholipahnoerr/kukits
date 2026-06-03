import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../config/env.dart';

class ScanResult {
  final String foodName;
  final String portion;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;

  const ScanResult({
    required this.foodName,
    required this.portion,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory ScanResult.fromJson(Map<String, dynamic> json) => ScanResult(
        foodName: json['foodName'] as String,
        portion: (json['portion'] as String?) ?? '1 porsi',
        calories: (json['calories'] as num).toInt(),
        protein: (json['protein'] as num).toDouble(),
        carbs: (json['carbs'] as num).toDouble(),
        fat: (json['fat'] as num).toDouble(),
      );
}

class AiService {
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  static const _prompt = '''
Analisis gambar makanan ini dan berikan estimasi nutrisi dalam format JSON berikut:
{
  "foodName": "nama makanan dalam Bahasa Indonesia",
  "portion": "estimasi porsi",
  "calories": 0,
  "protein": 0,
  "carbs": 0,
  "fat": 0
}
Semua nilai nutrisi dalam satuan gram (kecuali kalori dalam kkal).
Jika gambar bukan makanan, kembalikan null.
Hanya kembalikan JSON, tanpa teks lain.
''';

  Future<ScanResult?> analyzeFood(File imageFile) async {
    if (Env.geminiApiKey.isEmpty) {
      throw Exception('Gemini API key belum di-set di env.dart');
    }

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final response = await http.post(
      Uri.parse('$_endpoint?key=${Env.geminiApiKey}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': _prompt},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {'temperature': 0.1},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = data['candidates'][0]['content']['parts'][0]['text'] as String;

    final cleaned = text.trim().replaceAll('```json', '').replaceAll('```', '').trim();
    if (cleaned == 'null') return null;

    return ScanResult.fromJson(jsonDecode(cleaned) as Map<String, dynamic>);
  }
}
