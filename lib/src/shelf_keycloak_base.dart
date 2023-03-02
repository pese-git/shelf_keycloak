import 'package:shelf/shelf.dart';

Middleware createKeycloakMiddleware() => (innerHandler) {
      return (request) {
        print('Authorization: ${request.headers['Authorization']}');
        return Future.sync(() => innerHandler(request)).then((response) {
          return response;
        }, onError: (Object error, StackTrace stackTrace) {
          if (error is HijackException) throw error;

          throw error;
        });
      };
    };
