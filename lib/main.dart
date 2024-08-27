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
  // Configuración del cliente MQTT
  final MqttServerClient client = MqttServerClient('broker.hivemq.com', '')
    ..port = 1883
    ..logging(on: true)
    ..keepAlivePeriod = 20
    ..onDisconnected = onDisconnected
    ..onConnected = onConnected
    ..onSubscribed = onSubscribed;

  MQTTService() {
    client.setProtocolV311();
  }

  // Método para conectar al broker MQTT
  Future<void> connect() async {
    final MqttConnectMessage connMessage = MqttConnectMessage()
        .withClientIdentifier('sistema_segureye_esp3')
        .keepAliveFor(20)
        .startClean()
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMessage;

    try {
      print('Conectando al broker MQTT...');
      await client.connect();
    } catch (e) {
      print('Excepción durante la conexión: $e');
      client.disconnect();
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('Cliente MQTT conectado exitosamente');
    } else {
      print(
          'ERROR: La conexión del cliente MQTT falló - desconectando, estado: ${client.connectionStatus?.state}');
      client.disconnect();
    }
  }

  // Callback al conectar exitosamente
  static void onConnected() {
    print('Conectado al broker MQTT');
  }

  // Callback al desconectar
  static void onDisconnected() {
    print('Desconectado del broker MQTT');
  }

  // Callback al suscribirse exitosamente a un tópico
  static void onSubscribed(String topic) {
    print('Suscrito al tópico: $topic');
  }

  // Método para suscribirse a un tópico específico
  void subscribeToTopic(String topic) {
    print('Suscribiéndose al tópico: $topic');
    client.subscribe(topic, MqttQos.atMostOnce);
  }

  // Método para publicar un mensaje en un tópico
  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  // Método para obtener el stream de actualizaciones de MQTT
  Stream<List<MqttReceivedMessage<MqttMessage>>> getStream() {
    return client.updates!;
  }

  // Método para desuscribirse de un tópico específico
  void unsubscribeFromTopic(String topic) {
    print('Desuscribiéndose del tópico: $topic');
    client.unsubscribe(topic);
  }
}
