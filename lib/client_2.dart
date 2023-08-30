import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rsocket/metadata/composite_metadata.dart';
import 'package:rsocket/payload.dart';
import 'package:rsocket/rsocket_connector.dart';
import 'package:rsocket_demo/const.dart';
import 'package:rsocket_demo/utils.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Payload routeAndDataPayload(String route, String data) {
    var compositeMetadata =
        CompositeMetadata.fromEntries([RoutingMetadata(route, List.empty())]);
    var metadataBytes = compositeMetadata.toUint8Array();
    var dataBytes = Uint8List.fromList(utf8.encode(data));
    return Payload.from(metadataBytes, dataBytes);
  }

  Stream<Payload> streamRouteAndDataPayload(String route, String data) {
    var compositeMetadata =
        CompositeMetadata.fromEntries([RoutingMetadata(route, List.empty())]);
    var metadataBytes = compositeMetadata.toUint8Array();
    var dataBytes = Uint8List.fromList(utf8.encode(data));
    return Stream.value(Payload.from(metadataBytes, dataBytes));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('RSocket Flutter Example'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            optionCard(
                value: RSocketInteractionType.requestResponse,
                text: 'Request-Response'),
            optionCard(
                value: RSocketInteractionType.fireAndForget,
                text: 'Fire and Forget'),
            optionCard(
                value: RSocketInteractionType.requestStream, text: 'Stream'),
            optionCard(value: RSocketInteractionType.channel, text: 'Channel'),
          ],
        ),
      ),
    );
  }

  Widget optionCard(
      {required RSocketInteractionType value, required String text}) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _sendMessage(value),
            child: Text(text),
          ),
        ),
      ],
    );
  }

  _sendMessage(RSocketInteractionType interactionType) async {
    try {
      final rSocket =
          await RSocketConnector.create().connect('tcp://$ip_address:8888');

      switch (interactionType) {
        case RSocketInteractionType.requestResponse:
          final result = await rSocket.requestResponse!(
              routeAndDataPayload('/request-response', 'John'));
          print('Response: ${result.getDataUtf8()}');
          break;

        case RSocketInteractionType.fireAndForget:
          await rSocket
              .fireAndForget!(routeAndDataPayload('/fireAndForget', 'John'));
          print('Fire-and-forget message sent');
          break;

        case RSocketInteractionType.requestStream:
          final stream =
              rSocket.requestStream!(routeAndDataPayload('/stream', ''));
          await for (var payload in stream) {
            print('Stream Item: ${payload?.getDataUtf8()}');
          }
          break;

        default:
          print('Unknown interaction type');
          break;
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }
}
