import 'dart:async';
import 'dart:convert';
import 'package:dart_appwrite/dart_appwrite.dart';
import 'dart:io';

/// Appwrite Function for translating text using Gemini API
/// 
/// Environment Variables:
/// - GEMINI_API_KEY: Your Gemini API key
/// 
/// Input (JSON):
/// {
///   "text": "Text to translate",
///   "targetLanguage": "en" or "ru"
/// }
/// 
/// Output (JSON):
/// {
///   "success": true,
///   "translatedText": "Translated text",
///   "originalText": "Original text",
///   "targetLanguage": "en"
/// }

// ignore: strict_top_level_inference, type_annotate_public_apis
Future<dynamic> main(final context) async {
  try {
    // Initialize Appwrite client (useful for Appwrite-specific operations/logging)
    final client = Client()
      .setProject(context.env['APPWRITE_FUNCTION_PROJECT_ID'] ?? '')
      .setKey(context.req.variables['GEMINI_API_KEY'] ?? '');
    context.log('Appwrite client initialized: ${client.runtimeType}');

    // Parse request body
    final payload = jsonDecode(context.req.bodyRaw);
    
    // Validate input
    if (payload['text'] == null || payload['text'].toString().isEmpty) {
      return context.res.json({
        'success': false,
        'error': 'Text is required',
      }, statusCode: 400);
    }

    if (payload['targetLanguage'] == null) {
      return context.res.json({
        'success': false,
        'error': 'Target language is required (en or ru)',
      }, statusCode: 400);
    }

    final text = payload['text'].toString();
    final targetLanguage = payload['targetLanguage'].toString();

    // Validate target language
    if (targetLanguage != 'en' && targetLanguage != 'ru') {
      return context.res.json({
        'success': false,
        'error': 'Target language must be either "en" or "ru"',
      }, statusCode: 400);
    }

    // Get Gemini API key from environment
  final apiKey = context.req.variables['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      context.log('Error: GEMINI_API_KEY environment variable not set');
      return context.res.json({
        'success': false,
        'error': 'Translation service not configured',
      }, statusCode: 500);
    }

    // Translate using Gemini API
    final translatedText = await translateText(
      text: text,
      targetLanguage: targetLanguage,
      apiKey: apiKey,
      logger: context.log,
    );

    // Return success response
    return context.res.json({
      'success': true,
      'translatedText': translatedText,
      'originalText': text,
      'targetLanguage': targetLanguage,
    });
  } catch (e, stackTrace) {
    context.error('Translation error: $e');
    context.error('Stack trace: $stackTrace');
    
    return context.res.json({
      'success': false,
      'error': 'Translation failed: ${e.toString()}',
    }, statusCode: 500);
  }
}

/// Translate text using Gemini API
Future<String> translateText({
  required String text,
  required String targetLanguage,
  required String apiKey,
  required Function(String) logger,
}) async {
  // Gemini API endpoint
  // Gemini REST endpoint (Appwrite Client will handle headers)
  final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey';
  
  // Prepare prompt
  final languageName = targetLanguage == 'en' ? 'English' : 'Russian';
  final prompt = '''
Translate the following text to $languageName. 
Provide ONLY the translation without any explanations, notes, or additional text.
If the text is already in $languageName, return it as is.

Text to translate:
$text
''';

  logger('Translating to $languageName...');
  logger('Text length: ${text.length} characters');

  try {
    // Use Appwrite Client to call external Gemini endpoint
    // Try calling Client.call with positional args: (path, method, headers, body)
    // Use dart:io HttpClient to call Gemini REST API
    final httpClient = HttpClient();
    final uri = Uri.parse(endpoint);
    final request = await httpClient.postUrl(uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.add(utf8.encode(jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 1024,
      },
    })));

    final httpResponse = await request.close();
    final responseBody = await utf8.decoder.bind(httpResponse).join();
    dynamic data;
    try {
      data = jsonDecode(responseBody);
    } catch (_) {
      data = {};
    }
    
    if (data['candidates'] != null && 
        data['candidates'].isNotEmpty &&
        data['candidates'][0]['content'] != null &&
        data['candidates'][0]['content']['parts'] != null &&
        data['candidates'][0]['content']['parts'].isNotEmpty) {
      
      final translatedText = data['candidates'][0]['content']['parts'][0]['text']?.toString().trim() ?? text;
      
      logger('Translation successful');
      logger('Translated length: ${translatedText.length} characters');
      
      return translatedText;
    }

    // If no translation found, return original
    logger('Warning: No translation in response, returning original text');
    return text;
  } catch (e) {
    logger('Error calling Gemini API: $e');
    // On error, return original text
    return text;
  }
}
