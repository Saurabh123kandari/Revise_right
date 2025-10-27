import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AIProvider {
  openai,
  gemini,
}

class AIConfig {
  static const _storage = FlutterSecureStorage();
  
  static AIProvider _selectedProvider = AIProvider.openai;
  static String? _openaiApiKey;
  static String? _geminiApiKey;
  
  static AIProvider get selectedProvider => _selectedProvider;
  static String? get openaiApiKey => _openaiApiKey;
  static String? get geminiApiKey => _geminiApiKey;
  
  static Future<void> setProvider(AIProvider provider) async {
    _selectedProvider = provider;
    await _saveConfig();
  }
  
  static Future<void> setOpenAIApiKey(String? apiKey) async {
    _openaiApiKey = apiKey;
    if (apiKey != null) {
      await _storage.write(key: 'openai_api_key', value: apiKey);
    } else {
      await _storage.delete(key: 'openai_api_key');
    }
  }
  
  static Future<void> setGeminiApiKey(String? apiKey) async {
    _geminiApiKey = apiKey;
    if (apiKey != null) {
      await _storage.write(key: 'gemini_api_key', value: apiKey);
    } else {
      await _storage.delete(key: 'gemini_api_key');
    }
  }
  
  static Future<void> loadConfig() async {
    final storage = const FlutterSecureStorage();
    _openaiApiKey = await storage.read(key: 'openai_api_key');
    _geminiApiKey = await storage.read(key: 'gemini_api_key');
    final providerStr = await storage.read(key: 'ai_provider');
    if (providerStr != null) {
      _selectedProvider = AIProvider.values.firstWhere(
        (e) => e.toString() == providerStr,
        orElse: () => AIProvider.openai,
      );
    }
  }
  
  static Future<void> _saveConfig() async {
    await _storage.write(
      key: 'ai_provider',
      value: _selectedProvider.toString(),
    );
  }
  
  static bool isConfigured() {
    switch (_selectedProvider) {
      case AIProvider.openai:
        return _openaiApiKey != null && _openaiApiKey!.isNotEmpty;
      case AIProvider.gemini:
        return _geminiApiKey != null && _geminiApiKey!.isNotEmpty;
    }
  }
}

