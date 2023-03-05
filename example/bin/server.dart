import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_keycloak/shelf_keycloak.dart';
import 'package:shelf_router/shelf_router.dart';

const clientID = 'own-pub-server-backend';
const clientSecret = '062WkWIsQz8TwEDaOYk9KwcdM8tT3VqU';
const configURL =
    'http://localhost:51510/realms/own-pub-server/.well-known/openid-configuration';
const redirectURL = 'http://localhost:8080/callback';
const scopes = ["openid", "profile", "email"];

final authorizationEndpoint = Uri.parse(
    'http://localhost:51510/realms/own-pub-server/protocol/openid-connect/auth');
final tokenEndpoint = Uri.parse(
    'http://localhost:51510/realms/own-pub-server/protocol/openid-connect/token');

final redirectUrl = Uri.parse('http://localhost:8080');

final issuer = 'http://localhost:51510/realms/own-pub-server';

final credentialsFile = File('~/.myapp/credentials.json');

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler);

Response _rootHandler(Request req) {
  return Response.ok('Hello, World!\n');
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(
        createKeycloakMiddleware(
          logger: Logger(),
          client: http.Client(),
          //clientID: clientID,
          //clientSecret: clientSecret,
          configURL: Uri.parse(
              'http://localhost:51510/realms/code-fort-realm/protocol/openid-connect/certs'),
          kid: "X-cZn2Rk_wZ2Aoh_ESwUk2aalEe_WzQhB-oaQ27isfk",
          //redirectURL: redirectURL,
          //issuer: issuer,
          //scopes: scopes,
        ),
      )
      .addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
