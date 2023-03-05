import 'dart:async';
import 'dart:convert';

import 'package:jose/jose.dart';
import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:http/http.dart' as http;

Middleware createKeycloakMiddleware({
  Logger? logger,
  http.Client? client,
  required Uri configURL,
  required String kid,
}) =>
    (innerHandler) {
      return (request) async {
        var response = await client!.get(
          configURL,
        );

        logger?.d('Response config: ${response.body.toString()}');

        final certs = jsonDecode(response.body);

        final cert = (certs['keys'] as List)
            .firstWhere((element) => (element as Map)['kid'] == kid);

        final rawToken = request.headers['Authorization'];
        logger?.d('Authorization: $rawToken');

        if (rawToken == null) {
          return Response(401);
        }

        if (!rawToken.startsWith('Bearer ')) {
          return Response(401);
        }

        final token = rawToken.replaceFirst('Bearer', '').trim();

        if (token.isEmpty) {
          return Response(401);
        }
        // create a JsonWebSignature from the encoded string
        var jws = JsonWebSignature.fromCompactSerialization(token);

        // extract the payload
        var payload = jws.unverifiedPayload;

        logger?.d("content of jws: ${payload.stringContent}");
        logger?.d("protected parameters: ${payload.protectedHeader?.toJson()}");

        // create a JsonWebKey for verifying the signature
        var jwk = JsonWebKey.fromJson(cert);
        var keyStore = JsonWebKeyStore()..addKey(jwk);

        // verify the signature
        var verified = await jws.verify(keyStore);
        logger?.d("signature verified: $verified");

        if (verified == false) {
          return Response(401);
        }

        return Future.sync(() => innerHandler(request)).then((response) {
          return response;
        });
      };
    };
