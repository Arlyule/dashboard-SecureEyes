import 'package:dashboard_secureeyes/main.dart';
import 'package:mqtt_client/mqtt_client.dart';

class HealthDetails {
  final MQTTService mqttService = MQTTService(); // Instancia del servicio MQTT

  HealthDetails() {
    // _connectAndSubscribe();
  }

  void _connectAndSubscribe() async {
    await mqttService.connect(); // Conectar al broker MQTT

    // Suscribirse a los tópicos para recibir datos
    mqttService.subscribeToTopic('sistema_segureye_esp2/luz');
    mqttService.subscribeToTopic('sistema_segureye_esp2/led');
    mqttService.subscribeToTopic('sistema_segureye_esp2/microfono');
    mqttService.subscribeToTopic('sistema_segureye_esp2/pir');

    mqttService.client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final MqttPublishMessage recMessage =
          events[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
      final topic = events[0].topic;

      // Actualizar los valores según el tópico recibido
      if (topic == 'sistema_segureye_esp2/luz') {
        _luzValue = payload;
      } else if (topic == 'sistema_segureye_esp2/led') {
        _ledValue = payload;
      } else if (topic == 'sistema_segureye_esp2/microfono') {
        _microfonoValue = payload;
      } else if (topic == 'sistema_segureye_esp2/pir') {
        _pirValue = payload;
      }
    });
  }

  String _luzValue = "N/A";
  String _ledValue = "N/A";
  String _microfonoValue = "N/A";
  String _pirValue = "N/A";

  List<HealthModel> get healthData => [
        HealthModel(
            icon: 'assets/icons/light_sensor.png',
            value: _luzValue,
            title: "Light Sensor"),
        HealthModel(
            icon: 'assets/icons/led.png',
            value: _ledValue,
            title: "LED Status"),
        HealthModel(
            icon: 'assets/icons/microphone.png',
            value: _microfonoValue,
            title: "Microphone"),
        HealthModel(
            icon: 'assets/icons/pir.png',
            value: _pirValue,
            title: "PIR Sensor"),
      ];
}

class HealthModel {
  final String icon;
  final String value;
  final String title;

  HealthModel({required this.icon, required this.value, required this.title});
}
