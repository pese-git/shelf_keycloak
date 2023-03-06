import 'dart:io';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;

import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_keycloak/shelf_keycloak.dart';
import 'package:shelf_router/shelf_router.dart';

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
  var parser = ArgParser();
  parser.addOption('credentialsFile',
      help:
          '--credentialsFile - param for OpenConnect certificate config file');

  parser.addOption('address',
      mandatory: false, help: '--address -  listener <dns|ip>');
  parser.addOption('port', mandatory: false, help: '--port -  listener <port>');
  parser.addFlag('verbose', defaultsTo: false);

  final result = parser.parse(args);

  if (!result.wasParsed('credentialsFile')) {
    print(parser.options['credentialsFile']?.help);
    return;
  }

  print(result['verbose']); // true

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(
        checkJwtMiddleware(
          logger: result['verbose'] == true ? Logger() : null,
          client: http.Client(),
          credentialsFile: File(result['credentialsFile'] ??
              Platform.environment['CREDENTIALS_FILE']),
        ),
      )
      .addHandler(_router);

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.tryParse(result.wasParsed('address') == true
          ? result['address']
          : Platform.environment['ADDRESS']) ??
      InternetAddress.anyIPv4;

  // For running in containers, we respect the PORT environment variable.

  final port = int.parse(result.wasParsed('port') == true
      ? result['port']
      : Platform.environment['PORT']);
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
