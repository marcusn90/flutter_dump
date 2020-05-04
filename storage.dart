import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String _tokenKey = 'access_token';
const String _refreshTokenKey = 'refresh_token';

get _instance => SharedPreferences.getInstance();

Future<bool> setToken(String token) async {
  return (await _instance).setString(_tokenKey, token);
}

Future<String> getToken() async {
  return (await _instance).getString(_tokenKey);
}

Future<bool> removeToken() async {
  return (await _instance).remove(_tokenKey);
}

Future<bool> setRefreshToken(String token) async {
  return (await _instance).setString(_refreshTokenKey, token);
}

Future<String> getRefreshToken() async {
  return (await _instance).getString(_refreshTokenKey);
}

Future<bool> removeRefreshToken() async {
  return (await _instance).remove(_refreshTokenKey);
}

Future removeAllTokens() async {
  await removeToken();
  await removeRefreshToken();
}

