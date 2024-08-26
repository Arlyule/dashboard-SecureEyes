import 'package:dashboard_secureeyes/const/constant.dart';
import 'package:dashboard_secureeyes/widgets/scheduled_widget.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:dashboard_secureeyes/main.dart';
import 'package:dashboard_secureeyes/widgets/line_chart_card.dart'; // Importar el archivo que contiene LineChartCard

class SummaryWidget extends StatefulWidget {
  const SummaryWidget({super.key});

  @override
  _SummaryWidgetState createState() => _SummaryWidgetState();
}

class _SummaryWidgetState extends State<SummaryWidget>
    with SingleTickerProviderStateMixin {
  double _volumeValue = 90; // Valor inicial del medidor
  late MQTTService mqttService; // Instancia del servicio MQTT
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    //mqttService = MQTTService(); // Inicializa el servicio MQTT
    //_connectAndSubscribe(); // Conecta al broker y suscríbete al tópico si es necesario

    // Configuración de la animación
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation =
        Tween<double>(begin: 0, end: _volumeValue).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ))
          ..addListener(() {
            setState(() {});
          });

    // Iniciar animación de carga
    _animationController.forward();
  }

  void _connectAndSubscribe() async {
    await mqttService.connect(); // Conectar al broker MQTT

    // Suscribirse al tópico para recibir el valor inicial
    mqttService.subscribeToTopic('sistema_segureye_esp2/gauge/Servo');

    // Obtener el valor actual del medidor desde el broker MQTT
    mqttService.client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final MqttPublishMessage recMessage =
          events[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
      final newValue = double.tryParse(payload) ?? 0;
      setState(() {
        _volumeValue = newValue;
        _animation =
            Tween<double>(begin: 0, end: _volumeValue).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ));
        _animationController.forward(from: 0.0); // Reiniciar la animación
      });
    });
  }

  void _onGaugeValueChanged(double value) {
    setState(() {
      _volumeValue = value;
      _animation = Tween<double>(begin: _animation.value, end: _volumeValue)
          .animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
      _animationController.forward(from: 0.0); // Reiniciar la animación
    });
    // Publicar el valor actualizado al tópico MQTT
    mqttService.publishMessage(
        'sistema_segureye_esp2/gauge/Servo', value.toString());
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
            GestureDetector(
              onPanUpdate: (details) {
                // Capturar la posición del toque y actualizar el medidor
                double x = details.localPosition.dx /
                    context.size!.width *
                    180; // Convertir posición X a valor de 0 a 180
                double y = details.localPosition.dy /
                    context.size!.height *
                    180; // Convertir posición Y a valor de 0 a 180
                double newValue =
                    (x + y) / 2; // Promediar X y Y para obtener el nuevo valor
                newValue = newValue.clamp(0,
                    180); // Asegurar que el valor esté dentro del rango permitido

                // Actualizar el valor del medidor
                _onGaugeValueChanged(newValue);
              },
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: 0,
                    maximum: 180,
                    showLabels: false,
                    showTicks: false,
                    radiusFactor: 0.7,
                    axisLineStyle: const AxisLineStyle(
                      cornerStyle: CornerStyle.bothCurve,
                      color: Colors.black12,
                      thickness: 25,
                    ),
                    pointers: <GaugePointer>[
                      RangePointer(
                        value: _animation.value,
                        cornerStyle: CornerStyle.bothCurve,
                        width: 25,
                        sizeUnit: GaugeSizeUnit.logicalPixel,
                        gradient: const SweepGradient(
                          colors: <Color>[Color(0xFF2196F3), Color(0xFF64B5F6)],
                          stops: <double>[0.25, 0.75],
                        ),
                      ),
                      MarkerPointer(
                        value: _animation.value,
                        enableDragging: true,
                        onValueChanged: _onGaugeValueChanged,
                        markerHeight: 34,
                        markerWidth: 34,
                        markerType: MarkerType.circle,
                        color: const Color(0xFF64B5F6),
                        borderWidth: 2,
                        borderColor: Colors.white54,
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        angle: 90,
                        axisValue: 90,
                        positionFactor: 0.2,
                        widget: Text(
                          '${_animation.value.ceil()}',
                          style: const TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
    _animationController.dispose(); // Limpiar el controlador de animación
    mqttService.client.disconnect(); // Desconectar MQTT al salir
    super.dispose();
  }
}
