<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages). 
-->

The middleware for shelf_server that checks JWT tokens. The middleware works in conjunction with keycloak.

## Features

Features list:

- [x] Verification of JWT signature;
- [] Verification of Issuer;
- [] Verification of Subject;
- [] Verification of Audience;
- [] Verification of Expiration Time;
- [] Verification of Not Before Time;
- [] Verification of Issued at Time;

## Getting started

Added to pubspec dependency:

```yaml
dependencies:
  shelf_keycloak: <version>
```

## Usage

You can study a simple sample in the directory called "example".




`credentials.json` - this file you can get by link: `http://<your keycloak server>/auth/realms/<your realm name>/protocol/openid-connect/certs`

```json
{
    "kid": "X-cZn2Rk_wZ2Aoh_ESwUk2aalEe_WzQhB-oaQ27isfk",
    "kty": "RSA",
    "alg": "RS256",
    "use": "sig",
    "n": "2dFYbBnVwjDNrtby2UCPsNwVaTt-WgRYGqpPHsD9lQdTLmHshCqVtKXsLEflZInzIW65fg5JP2eIfEMJezkbSI7D0l8rRWvJqOklakyQHsK_IssuR5SVr-smya048BR3gUIPCg4L0IaPkQ50900vMUSy3Xkx4_k9oll6o_rRYvUwydD6ZPGFCr5J6nc2hQcEA4Vs_MRrK_xbkoHFvxrdE07bwETCxdyY2f6q23DQIJ7oKXEgaKwsZbAEmUS7RLkiqf9HG7Tg3DRlQShLZzo11OpuNziHWWS2MdFXBUwRtojrmpy4w4H83fFEQtzhLpvu1c5Oa3qE9dnppX330XdZZw",
    "e": "AQAB",
    "x5c": [
        "MIICrTCCAZUCBgGGsXCMsTANBgkqhkiG9w0BAQsFADAaMRgwFgYDVQQDDA9jb2RlLWZvcnQtcmVhbG0wHhcNMjMwMzA1MTEwMTI4WhcNMzMwMzA1MTEwMzA4WjAaMRgwFgYDVQQDDA9jb2RlLWZvcnQtcmVhbG0wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDZ0VhsGdXCMM2u1vLZQI+w3BVpO35aBFgaqk8ewP2VB1MuYeyEKpW0pewsR+VkifMhbrl+Dkk/Z4h8Qwl7ORtIjsPSXytFa8mo6SVqTJAewr8iyy5HlJWv6ybJrTjwFHeBQg8KDgvQho+RDnT3TS8xRLLdeTHj+T2iWXqj+tFi9TDJ0Ppk8YUKvknqdzaFBwQDhWz8xGsr/FuSgcW/Gt0TTtvARMLF3JjZ/qrbcNAgnugpcSBorCxlsASZRLtEuSKp/0cbtODcNGVBKEtnOjXU6m43OIdZZLYx0VcFTBG2iOuanLjDgfzd8URC3OEum+7Vzk5reoT12emlfffRd1lnAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAItmLBH+XJI05PvDK1Sv4PXAXrcHODYRdukisI2bXGgvCH7HvIk/3T91RCVndfBFqy9eYtCWXFTyH0W1ni6iFUr3UEuveL5JxjUe+oehUFeXqleM3L9PjnFwDuKexuzfanfiQUB93j4nmAbc0Kw7a8oveZ/qiEeJWOot13MC4ZFC4jONvatq5nXWnKJY4fs1FxxGze6q1nifO5IuResmTjEEIvmCPcm77M1S3z7gGfKxmfJpXrdVxZUM8RTYywJDEnls1+fOnIotk8zv8M9LAVfb6GckgNURK2rUyfKeCEZXl0VtHZUHzU+kVUcZ+/imEdsfXGxnh4Uikam4z6c7JeM="
    ],
    "x5t": "7HZw8pfbDz4t1hFDNOGtejG3U2s",
    "x5t#S256": "RsJ6ei7WoKB-EWTFIK6LUKTvs-KfY3jxKD9WKNaV4gE"
}
```

bin/server.dart

```dart
import 'dart:io';
import 'package:args/args.dart';
import 'package:http/http.dart' as http;

import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_keycloak/shelf_keycloak.dart';
import 'package:shelf_router/shelf_router.dart';

var logger = Logger();

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
  logger.i('Start example');

  var parser = ArgParser();
  parser.addOption('credentialsFile',
      help:
          '--credentialsFile - param for OpenConnect certificate config file');

  parser.addOption('address',
      mandatory: false, help: '--address -  listener <dns|ip>');
  parser.addOption('port', mandatory: false, help: '--port -  listener <port>');
  parser.addFlag('verbose', defaultsTo: false);

  final result = parser.parse(args);

  logger.i('Verbose: ${result['verbose']}'); // true

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(
        checkJwtMiddleware(
          logger: result['verbose'] == true ? Logger() : null,
          client: http.Client(),
          credentialsFile: File(result.wasParsed('credentialsFile') == true
              ? result['credentialsFile']
              : getEnvironmentValue('CREDENTIALS_FILE') ?? ''),
        ),
      )
      .addHandler(_router);

  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.tryParse(result.wasParsed('address') == true
          ? result['address']
          : getEnvironmentValue('ADDRESS') ?? '') ??
      InternetAddress.anyIPv4;

  // For running in containers, we respect the PORT environment variable.

  final port = int.tryParse(result.wasParsed('port') == true
      ? result['port']
      : getEnvironmentValue('PORT') ?? '');

  logger.i('IP: ${ip.address}');
  logger.i('PORT: ${port ?? 8080}');

  final server = await serve(handler, ip, port ?? 8080);
  print('Server listening on port ${server.port}');
}

String? getEnvironmentValue(String key, [String? defaultValue]) {
  try {
    return Platform.environment[key];
  } catch (e) {
    return defaultValue;
  }
}
```

Run example:

```sh
$ dart run server.dart
Server listening on port 8080
```

## Additional information

Before running the example or using the library in your project, you need to install the Keycloak server.
