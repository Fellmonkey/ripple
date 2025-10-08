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
      .setProject(Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'] ?? '')
      .setKey(context.req.headers['x-appwrite-key'] ?? '');
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
  final apiKey = Platform.environment['GEMINI_API_KEY'];
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
  // Gemini API endpoint - using v1beta with gemini-pro (most stable)
  final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey';
  
  // Prepare simple, direct prompt
  final languageName = targetLanguage == 'en' ? 'English' : 'Russian';
  final prompt = 'Translate to $languageName: $text';

  logger('Translating to $languageName...');
  logger('Text length: ${text.length} characters');
  logger('Using Gemini API: v1beta/gemini-pro');

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
    final statusCode = httpResponse.statusCode;
    final responseBody = await utf8.decoder.bind(httpResponse).join();
    
    logger('HTTP Status: $statusCode');
    logger('Response body length: ${responseBody.length} chars');
    logger('Response preview: ${responseBody.substring(0, responseBody.length > 500 ? 500 : responseBody.length)}');
    
    dynamic data;
    try {
      data = jsonDecode(responseBody);
    } catch (e) {
      logger('Failed to parse JSON response: $e');
      logger('Raw response: $responseBody');
      return text;
    }
    
    // Check for API errors first
    if (data['error'] != null) {
      logger('Gemini API error: ${data['error']}');
      return text;
    }
    
    // Try to extract translation from response
    String? extractedText;
    
    // Standard response structure
    if (data['candidates'] != null && 
        data['candidates'] is List &&
        data['candidates'].isNotEmpty) {
      
      final candidate = data['candidates'][0];
      logger('Candidate structure: ${candidate.keys.toList()}');
      
      if (candidate['content'] != null &&
          candidate['content']['parts'] != null &&
          candidate['content']['parts'] is List &&
          candidate['content']['parts'].isNotEmpty) {
        
        extractedText = candidate['content']['parts'][0]['text']?.toString();
      }
      
      // Alternative: sometimes text is directly in candidate
      if (extractedText == null && candidate['text'] != null) {
        extractedText = candidate['text'].toString();
      }
      
      // Alternative: check output field
      if (extractedText == null && candidate['output'] != null) {
        extractedText = candidate['output'].toString();
      }
    }
    
    if (extractedText != null && extractedText.isNotEmpty) {
      final translatedText = extractedText.trim();
      
      logger('Translation successful');
      logger('Translated: "$translatedText"');
      logger('Translated length: ${translatedText.length} characters');
      
      return translatedText;
    }

    // If no translation found, return original
    logger('Warning: No translation in response structure, returning original text');
    logger('Available keys in response: ${data.keys.toList()}');
    if (data['candidates'] != null && data['candidates'].isNotEmpty) {
      logger('First candidate keys: ${data['candidates'][0].keys.toList()}');
    }
    return text;
  } catch (e) {
    logger('Error calling Gemini API: $e');
    // On error, return original text
    return text;
  }
}
