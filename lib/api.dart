import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:twtxt_flutter/models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Api {
  final http.Client _httpClient;
  final FlutterSecureStorage _flutterSecureStorage;
  final String tokenKey = 'token';

  Api(this._httpClient, this._flutterSecureStorage);

  Future<User> get user async {
    String json = await _flutterSecureStorage.read(key: tokenKey);
    if (json == null) {
      return null;
    }
    return User.fromJson(jsonDecode(json));
  }

  void clearUserToken() {
    _flutterSecureStorage.delete(key: tokenKey);
  }

  Future<User> login(String username, String password, Uri podURI) async {
    print(podURI.replace(path: "/api/v1/auth"));
    final response = await _httpClient.post(
      podURI.replace(path: "/api/v1/auth"),
      body: jsonEncode({'username': username, 'password': password}),
      headers: {HttpHeaders.contentTypeHeader: ContentType.json.toString()},
    );

    if (response.statusCode == 401) {
      throw http.ClientException(
        'Invalid username! Hint: Register an account?',
      );
    }

    if (response.statusCode >= 400) {
      throw http.ClientException('Failed to login');
    }

    final user = User(
      username: username,
      podURL: podURI,
      token: AuthReponse.fromJson(jsonDecode(response.body)).token,
    );

    await _flutterSecureStorage.write(key: tokenKey, value: jsonEncode(user));

    return user;
  }

  Future<void> register(String username, String password, String email) async {
    final _user = await user;
    final response = await _httpClient.post(
      _user.podURL.replace(path: "/api/v1/register"),
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
      }),
      headers: {HttpHeaders.contentTypeHeader: ContentType.json.toString()},
    );

    if (response.statusCode >= 400) {
      throw http.ClientException('Failed to register. ${response.body}');
    }
  }

  Future<TimelineResponse> timeline(int page) async {
    final _user = await user;
    final response = await _httpClient.post(
      _user.podURL.replace(path: "/api/v1/timeline"),
      body: jsonEncode({'page': page}),
      headers: {
        'Token': _user.token,
        HttpHeaders.contentTypeHeader: ContentType.json.toString(),
      },
    );

    if (response.statusCode >= 400) {
      throw http.ClientException('Failed to get timeline');
    }

    return TimelineResponse.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)));
  }

  Future<void> savePost(String text) async {
    final _user = await user;
    final response = await _httpClient.post(
      _user.podURL.replace(path: "/api/v1/post"),
      body: jsonEncode({'text': text, 'post_as': "me"}),
      headers: {
        'Token': _user.token,
        HttpHeaders.contentTypeHeader: ContentType.json.toString(),
      },
    );

    if (response.statusCode >= 400) {
      throw http.ClientException('Failed post tweet. Please try again later');
    }
  }
}