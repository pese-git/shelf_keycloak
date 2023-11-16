import 'dart:async';
import 'dart:convert';
import 'package:jose/jose.dart';
import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:http/http.dart' as http;

/*
Code	Name	Description
Standard claim fields,	The internet drafts define the following standard fields ("claims") that can be used inside a JWT claim set.

iss,	Issuer	Identifies principal that issued the JWT.
sub,	Subject	Identifies the subject of the JWT.
aud,	Audience	Identifies the recipients that the JWT is intended for. Each principal intended to process the JWT must identify itself with a value in the audience claim. If the principal processing the claim does not identify itself with a value in the aud claim when this claim is present, then the JWT must be rejected.
exp,	Expiration Time	Identifies the expiration time on and after which the JWT must not be accepted for processing. The value must be a NumericDate: either an integer or decimal, representing seconds past 1970-01-01 00:00:00Z.
nbf,	Not Before	Identifies the time on which the JWT will start to be accepted for processing. The value must be a NumericDate.
iat,	Issued at	Identifies the time at which the JWT was issued. The value must be a NumericDate.
jti,	JWT ID	Case-sensitive unique identifier of the token even among different issuers.

iss (issuer) - идентификатор, выдавшего токен
sub (subject) - идентификатор, кто выпустил токен
aud (audience) - идентификатор, для кого предназначен токен
exp (expiration time) - время, после которого токен станет недействительным
nbf (not before) - время, до которого токен не действителен
iat (issued at) - время, когда был выдан токен
jti (JWT ID) - уникальный идентификатор токена

Commonly-used header fields	The following fields are commonly used in the header of a JWT
typ	Token type	If present, it must be set to a registered IANA Media Type.
cty,	Content type	If nested signing or encryption is employed, it is recommended to set this to JWT; otherwise, omit this field.
alg	Message authentication code algorithm	The issuer can freely set an algorithm to verify the signature on the token. However, some supported algorithms are insecure.
kid	Key ID	A hint indicating which key the client used to generate the token signature. The server will match this value to a key on file in order to verify that the signature is valid and the token is authentic.
x5c	x.509 Certificate Chain	A certificate chain in RFC4945 format corresponding to the private key used to generate the token signature. The server will use this information to verify that the signature is valid and the token is authentic.
x5u	x.509 Certificate Chain URL	A URL where the server can retrieve a certificate chain corresponding to the private key used to generate the token signature. The server will retrieve and use this information to verify that the signature is authentic.
crit	Critical	A list of headers that must be understood by the server in order to accept the token as valid

"alg" - алгоритм подписи JWT.
"typ" - тип токена, который в данном случае является JWT.
"kid" - идентификатор ключа, используемый для подписи JWT.
"jku" - URL-адрес, по которому можно получить JWK-ключи.
"x5u" - URL-адрес, по которому можно получить открытый ключ X.509.
"x5t" - отпечаток открытого ключа X.509.
"x5t#S256" - отпечаток открытого ключа X.509, вычисленный по алгоритму SHA-256.
"crit" - список критических заголовков, которые должны быть обработаны до декодирования JWT.

*/

Middleware checkJwtMiddleware({
  Logger? logger,
  http.Client? client,
  required Uri certsUri,
}) {
  return (innerHandler) {
    return (request) async {
      final certBody = await http.get(certsUri).then((value) => value.body);

      logger?.d('Response config: $certBody');

      final cert = jsonDecode(certBody);

      final rawToken = request.headers['Authorization'];
      logger?.d('Authorization: $rawToken');

      if (rawToken == null) {
        return Response(401, body: 'Empty token');
      }

      if (!rawToken.startsWith('Bearer ')) {
        return Response(401, body: 'Invalid presenter');
      }

      final token = rawToken.replaceFirst('Bearer', '').trim();

      if (token.isEmpty) {
        return Response(401, body: 'Empty token');
      }
      // create a JsonWebSignature from the encoded string
      var jws = JsonWebSignature.fromCompactSerialization(token);

      // extract the payload
      var payload = jws.unverifiedPayload;
      var protectedHeader = payload.protectedHeader?.toJson() ?? {};

      logger?.d("content of jws: ${payload.stringContent}");
      logger?.d("protected parameters: $protectedHeader");

      final key = (cert['keys'] as List)
          .firstWhere(((element) => element['kid'] == protectedHeader['kid']));

      // create a JsonWebKey for verifying the signature
      var jwk = JsonWebKey.fromJson(key);
      var keyStore = JsonWebKeyStore()..addKey(jwk);

      // verify the signature
      var verified = await jws.verify(keyStore);
      logger?.d("signature verified: $verified");

      if (verified == false) {
        return Response(401, body: 'Invalid signature');
      }

      return Future.sync(() => innerHandler(request)).then((response) {
        return response;
      });
    };
  };
}
