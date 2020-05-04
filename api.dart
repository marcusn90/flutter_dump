import 'dart:convert';

import 'package:http/http.dart' as http;

import 'storage.dart';

const _baseUrl = 'http://localhost:8080/';

String getUrl(String path) {
  return '$_baseUrl$path';
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  Map details;

  ApiException({this.message, details, this.statusCode}) {
    this.details = details ?? {};
  }

  String toString() {
    return 'Api Exception: $statusCode\n$message\n$details\n';
  }
}

class InvalidRefreshTokenException extends ApiException {}

class ApiRequest {
  final String method;
  final dynamic body;
  final bool bytesResponse;
  final String path;
  Map<String, String> headers;

  ApiRequest({
    this.method = 'GET',
    this.path,
    this.body,
    this.bytesResponse = false,
    headers,
  }) {
    this.headers = headers ?? {};
    this.headers.putIfAbsent('Content-Type', () => 'application/json');
  }

  Future send() {
    var url = getUrl(path);
    print('${method.toUpperCase()} $url');
    var bodyEncoded = jsonEncode(body);
    switch (method.toLowerCase()) {
      case 'post':
        return http.post(url, body: bodyEncoded, headers: headers);
      case 'put':
        return http.put(url, body: bodyEncoded, headers: headers);
      case 'patch':
        return http.patch(url, body: bodyEncoded, headers: headers);
      case 'delete':
        return http.delete(url, headers: headers);
      case 'head':
        return http.head(url, headers: headers);
      case 'get':
      default:
        return http.get(url, headers: headers);
    }
  }

  updateAuthorizationHeader(token) async {
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      headers.remove('Authorization');
    }
  }
}

Future<http.MultipartRequest> createMultipartRequest(String path) async {
  print(getUrl(path));
  var token = await storage.getToken();
  Uri uri = Uri.parse(getUrl(path));
  var req = http.MultipartRequest("POST", uri);
  req.headers.putIfAbsent('Authorization', () => 'Bearer $token');

  return req;
}

_tryDecodeResponse(http.Response response) {
  var body;
  try {
    body = jsonDecode(response.body);
  } catch (err) {
    print(err);
    body = response.body;
  }
  return body;
}

Future _retry(ApiRequest request) async {
  var refreshToken = await storage.getRefreshToken();
  print('retrying with refresh token: ${refreshToken != null}');
  if (refreshToken == null) {
    throw InvalidRefreshTokenException();
  }
  try {
    var res = await http.put(
      getUrl('auth/token'),
      body: jsonEncode({'refreshToken': refreshToken}),
      headers: {'Content-Type': ' application/json'},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) throw ApiException();
    var refreshRes = _tryDecodeResponse(res);
    print(
        "New tokens: \naccessToken ${refreshRes['accessToken'] != null}\nrefreshToken: ${refreshRes['refreshToken'] != null}\n");
    if (refreshRes != null) {
      await storage.setToken(refreshRes['accessToken']);
      request.updateAuthorizationHeader(refreshRes['accessToken']);
    }
  } catch (err) {
    throw InvalidRefreshTokenException();
  }
  return request.send();
}

Future _tryRequest(ApiRequest request) async {
  try {
    http.Response res = await request.send();
    var forceRetry = false; // for debugging
    if (forceRetry || res.statusCode == 401) {
      // unauthorized, try refresh token and re-send request
      print('API 401: will retry...');
      print(res.body);
      res = await _retry(request);
    }
    var body = request.bytesResponse ? res.bodyBytes : _tryDecodeResponse(res);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
          statusCode: res.statusCode,
          details: request.bytesResponse || body == '' ? {} : body);
    }
    return body;
  } on ApiException catch (err) {
    if (err.statusCode == 401 || err is InvalidRefreshTokenException) {
      // at this point we've already re-tried request and still getting 401 or failed to refresh access token
      await storage.removeAllTokens();
    }
    rethrow;
  } catch (e) {
    print('Error performing request: $e');
    throw ApiException(message: 'Request failed');
  }
}

Future get(String path,
    {Map headers, bool auth = true, bool asBytes = false}) async {
  ApiRequest req =
      ApiRequest(method: 'get', path: path, bytesResponse: asBytes);
  if (auth) {
    var token = await storage.getToken();
    req.updateAuthorizationHeader(token);
  }
  return _tryRequest(req);
}

Future post(String path,
    {dynamic body, Map<String, String> headers, bool auth = true}) async {
  ApiRequest req =
      ApiRequest(method: 'post', path: path, headers: headers, body: body);
  if (auth) {
    var token = await storage.getToken();
    req.updateAuthorizationHeader(token);
  }
  return _tryRequest(req);
}

Future patch(String path,
    {dynamic body, Map<String, String> headers, bool auth = true}) async {
  ApiRequest req =
      ApiRequest(method: 'patch', path: path, headers: headers, body: body);
  if (auth) {
    var token = await storage.getToken();
    req.updateAuthorizationHeader(token);
  }
  return _tryRequest(req);
}

Future put(String path,
    {dynamic body, Map<String, String> headers, bool auth = true}) async {
  ApiRequest req =
      ApiRequest(method: 'put', path: path, headers: headers, body: body);
  if (auth) {
    var token = await storage.getToken();
    req.updateAuthorizationHeader(token);
  }
  return _tryRequest(req);
}

Future head(String path) {
  return _tryRequest(ApiRequest(method: 'head', path: path));
}

Future delete(String path,
    {Map<String, String> headers, bool auth = true}) async {
  ApiRequest req = ApiRequest(method: 'delete', path: path, headers: headers);
  if (auth) {
    var token = await storage.getToken();
    req.updateAuthorizationHeader(token);
  }
  return _tryRequest(req);
}

