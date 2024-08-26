import 'package:dashboard_secureeyes/main.dart';
import 'package:dashboard_secureeyes/widgets/custom_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:typed_data'; // Importar para manejar datos binarios

class LineChartCard extends StatefulWidget {
  const LineChartCard({super.key});

  // Método para iniciar la transmisión de imágenes
  static final LineChartCardController controller = LineChartCardController();

  @override
  _LineChartCardState createState() => _LineChartCardState();
}

class _LineChartCardState extends State<LineChartCard> {
  Uint8List?
      imageData; // Variable para almacenar los datos binarios de la imagen
  late MQTTService mqttService; // Instancia del servicio MQTT

  @override
  void initState() {
    super.initState();
    mqttService = MQTTService(); // Inicializa el servicio MQTT
    LineChartCard.controller.startImageTransmission =
        _connectAndSubscribe; // Vincula el método de transmisión de imágenes
  }

  void _connectAndSubscribe() async {
    await mqttService.connect(); // Conecta al broker MQTT
    mqttService.subscribeToTopic(
        'sistema_segureye_esp2/cam_0'); // Suscribirse al tópico de imagen

    mqttService.client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;

      // Convertir el mensaje recibido a datos binarios y luego a Uint8List
      final Uint8List payload =
          Uint8List.fromList(message.payload.message.toList());

      setState(() {
        imageData = payload; // Almacenar los datos binarios de la imagen
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tarjeta para mostrar la imagen de la ESP32
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "ESP32 Camera Image",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              imageData != null
                  ? Image.memory(
                      imageData!,
                      fit: BoxFit.cover,
                      height: 200, // Ajusta el tamaño según necesites
                      width: double.infinity,
                    )
                  : const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 20), // Espacio entre la imagen y la gráfica
        // Aquí puedes agregar el widget de la gráfica de líneas
      ],
    );
  }

  @override
  void dispose() {
    mqttService.client.disconnect(); // Desconectar al salir
    super.dispose();
  }
}

class LineChartCardController {
  late VoidCallback
      startImageTransmission; // Callback para iniciar la transmisión de imágenes
}
