import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  final port = Random().nextInt(0xffff);
  final host = 'http://0.0.0.0';
  final baseUrl = '$host:$port';

  final token =
      'eyJhbGciOiJSUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICJYLWNabjJSa193WjJBb2hfRVN3VWsyYWFsRWVfV3pRaEItb2FRMjdpc2ZrIn0.eyJleHAiOjE2NzgwMTQ2NzcsImlhdCI6MTY3ODAxNDM3NywianRpIjoiODI3NzgxMjQtNTJjZS00MjYxLTg2YWItMzg3MGUyNDMzZmFmIiwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDo1MTUxMC9yZWFsbXMvY29kZS1mb3J0LXJlYWxtIiwiYXVkIjoiYWNjb3VudCIsInN1YiI6Ijg2YjY1OTcxLTMxNjYtNDhjOS05ZmVkLTI1NDc3YTU0ZDY2YyIsInR5cCI6IkJlYXJlciIsImF6cCI6ImNvZGUtZm9ydC1hcHAiLCJzZXNzaW9uX3N0YXRlIjoiMjNlOGJiYWQtZjMyNC00ZWFiLTgzNzktMzhjOWEwNjJjMDQ1IiwiYWNyIjoiMSIsInJlYWxtX2FjY2VzcyI6eyJyb2xlcyI6WyJvZmZsaW5lX2FjY2VzcyIsImRlZmF1bHQtcm9sZXMtY29kZS1mb3J0LXJlYWxtIiwidW1hX2F1dGhvcml6YXRpb24iXX0sInJlc291cmNlX2FjY2VzcyI6eyJhY2NvdW50Ijp7InJvbGVzIjpbIm1hbmFnZS1hY2NvdW50IiwibWFuYWdlLWFjY291bnQtbGlua3MiLCJ2aWV3LXByb2ZpbGUiXX19LCJzY29wZSI6ImVtYWlsIHByb2ZpbGUiLCJzaWQiOiIyM2U4YmJhZC1mMzI0LTRlYWItODM3OS0zOGM5YTA2MmMwNDUiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwibmFtZSI6ItCh0LXRgNCz0LXQuSDQn9C10L3RjNC60L7QstGB0LrQuNC5IiwicHJlZmVycmVkX3VzZXJuYW1lIjoidXNlciIsImdpdmVuX25hbWUiOiLQodC10YDQs9C10LkiLCJmYW1pbHlfbmFtZSI6ItCf0LXQvdGM0LrQvtCy0YHQutC40LkiLCJlbWFpbCI6InNlcmdleS5wZW5rb3Zza3lAZ21haWwuY29tIn0.2ZGTPVZeT1CKD3rPkjBAz1qUmE4648WMsXvYyjWa-q4RnkM0ARiRgrBQ0QafiiRhqqF1M3BPJccvxGM9Z4TZU08spP1wMnWsiouDmLB0SZ0SO-dp_zGDbBHuelL9hi520tLQsrlZhLErkFbKuwBlNlkgASe1CG1dmREahwoYuVtNdY3k31wbdx5k1LbC-1QPltEUIIiicG9nJFtkdBWjJRLrghGCxHwoAScfraX39gABY0HhzYDvSTljfpSpc3aLLRX_mGcEb1U8YgHkMkhLWKUF8EtLL97rus2JbCpxV0965FGmSu0lRqJ-JHFu63eKr8Cwq0swncnQAFIYy0_4yg';
  late Process p;

  setUp(() async {
    p = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {
        'ADDRESS': host,
        'PORT': port.toString(),
        'CREDENTIALS_FILE': './credentials.json',
      },
      //runInShell: true,
    );

    var stdout = p.stdout.asBroadcastStream();

    stdout.transform(utf8.decoder).forEach(print);

    // Wait for server to start and print to stdout.
    await stdout.first;
  });

  tearDown(() => p.kill());

  test('Check authentication without token - 401', () async {
    final response = await get(Uri.parse('$baseUrl/'));
    expect(response.statusCode, 401);
  });

  test('Check authentication with empty token - 401', () async {
    final response = await get(
      Uri.parse('$baseUrl/'),
      headers: {'Authorization': 'Bearer '},
    );
    expect(response.statusCode, 401);
  });

  test('Check authentication with token - 200', () async {
    final response = await get(
      Uri.parse('$baseUrl/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    expect(response.statusCode, 200);
  });

    test('Check authentication with invalid token - 500', () async {
    final response = await get(
      Uri.parse('$baseUrl/'),
      headers: {'Authorization': 'Bearer token'},
    );
    expect(response.statusCode, 500);
  });
}
