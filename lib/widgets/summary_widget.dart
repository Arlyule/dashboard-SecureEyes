import 'package:dashboard_secureeyes/const/constant.dart';
import 'package:dashboard_secureeyes/widgets/scheduled_widget.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:dashboard_secureeyes/main.dart';
import 'package:dashboard_secureeyes/widgets/line_chart_card.dart'; // Importar el archivo que contiene LineChartCard

class SummaryWidget extends StatefulWidget {
  const SummaryWidget({super.key});

  @override
  _SummaryWidgetState createState() => _SummaryWidgetState();
}

class _SummaryWidgetState extends State<SummaryWidget> {
  double _sliderValue = 90; // Valor inicial del slider
  late MQTTService mqttService; // Instancia del servicio MQTT

  @override
  void initState() {
    super.initState();
    mqttService = MQTTService(); // Inicializa el servicio MQTT
    _connectAndSubscribe(); // Conecta al broker y suscríbete al tópico si es necesario
  }

  void _connectAndSubscribe() async {
    await mqttService.connect(); // Conectar al broker MQTT

    // Suscribirse al tópico para recibir el valor inicial
    mqttService.subscribeToTopic('segureye/servo');

    // Obtener el valor actual del slider desde el broker MQTT
    mqttService
        .getStream()
        .listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final MqttPublishMessage recMessage =
          events[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
      final newValue = double.tryParse(payload) ?? 0;
      setState(() {
        _sliderValue = newValue;
      });
    });
  }

  void _onSliderValueChanged(double value) {
    setState(() {
      _sliderValue = value;
    });
    // Publicar el valor actualizado al tópico MQTT
    mqttService.publishMessage('segureye/servo', value.toString());
  }

  void _startImageTransmission() {
    LineChartCard.controller
        .startImageTransmission(); // Iniciar la transmisión de imágenes
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: cardBackgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              'Posición de Cámara',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Slider(
              value: _sliderValue,
              min: 0,
              max: 180,
              divisions: 180,
              onChanged: _onSliderValueChanged,
              activeColor: Colors.blue,
              inactiveColor: Colors.blueAccent.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'Valor: ${_sliderValue.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Scheduled(
              onStartVideo:
                  _startImageTransmission, // Proveer el callback necesario
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    mqttService.client.disconnect(); // Desconectar MQTT al salir
    super.dispose();
  }
}
