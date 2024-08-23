import 'package:dashboard_secureeyes/const/constant.dart';
import 'package:dashboard_secureeyes/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: backgroundColor,
        brightness: Brightness.dark,
      ),
      home: const MainScreen(),
    );
  }
}

class MQTTService {
  final MqttServerClient client = MqttServerClient('broker.hivemq.com', '');

  MQTTService() {
    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.onConnected = onConnected;
    client.onSubscribed = onSubscribed;
  }

  Future<void> connect() async {
    final MqttConnectMessage connMessage = MqttConnectMessage()
        .withClientIdentifier('SecureEyes')
        .keepAliveFor(20)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMessage;

    try {
      print('Connecting to the MQTT broker...');
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT client connected');
    } else {
      print(
          'ERROR: MQTT client connection failed - disconnecting, state is ${client.connectionStatus!.state}');
      client.disconnect();
    }
  }

  void onConnected() {
    print('Connected to the MQTT broker');
  }

  void onDisconnected() {
    print('Disconnected from the MQTT broker');
  }

  void onSubscribed(String topic) {
    print('Subscribed to the topic: $topic');
  }

  void subscribeToTopic(String topic) {
    client.subscribe(topic, MqttQos.atMostOnce);
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  Stream<List<MqttReceivedMessage<MqttMessage>>> getStream() {
    return client.updates!;
  }
}
