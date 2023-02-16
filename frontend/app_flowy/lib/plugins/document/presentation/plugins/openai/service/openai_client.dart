import 'dart:convert';

import 'text_completion.dart';
import 'package:dartz/dartz.dart';
import 'dart:async';

import 'error.dart';
import 'package:http/http.dart' as http;

// Please fill in your own API key
const apiKey = '';

enum OpenAIRequestType {
  textCompletion,
  textEdit;

  Uri get uri {
    switch (this) {
      case OpenAIRequestType.textCompletion:
        return Uri.parse('https://api.openai.com/v1/completions');
      case OpenAIRequestType.textEdit:
        return Uri.parse('https://api.openai.com/v1/edits');
    }
  }
}

abstract class OpenAIRepository {
  /// Get completions from GPT-3
  ///
  /// [prompt] is the prompt text
  /// [suffix] is the suffix text
  /// [maxTokens] is the maximum number of tokens to generate
  /// [temperature] is the temperature of the model
  ///
  Future<Either<OpenAIError, TextCompletionResponse>> getCompletions({
    required String prompt,
    String? suffix,
    int maxTokens = 50,
    double temperature = .3,
  });
}

class HttpOpenAIRepository implements OpenAIRepository {
  const HttpOpenAIRepository({
    required this.client,
    required this.apiKey,
  });

  final http.Client client;
  final String apiKey;

  Map<String, String> get headers => {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

  @override
  Future<Either<OpenAIError, TextCompletionResponse>> getCompletions({
    required String prompt,
    String? suffix,
    int maxTokens = 50,
    double temperature = 0.3,
  }) async {
    final parameters = {
      'model': 'text-davinci-003',
      'prompt': prompt,
      'suffix': suffix,
      'max_tokens': maxTokens,
      'temperature': temperature,
      'stream': false,
    };

    final response = await http.post(
      OpenAIRequestType.textCompletion.uri,
      headers: headers,
      body: json.encode(parameters),
    );

    if (response.statusCode == 200) {
      return Right(TextCompletionResponse.fromJson(json.decode(response.body)));
    } else {
      return Left(OpenAIError.fromJson(json.decode(response.body)['error']));
    }
  }
}
