import 'package:dashboard_secureeyes/const/constant.dart';
import 'package:dashboard_secureeyes/data/line_chart_data.dart';
import 'package:dashboard_secureeyes/main.dart';
import 'package:dashboard_secureeyes/widgets/custom_card_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';

class LineChartCard extends StatefulWidget {
  const LineChartCard({super.key});

  @override
  _LineChartCardState createState() => _LineChartCardState();
}

class _LineChartCardState extends State<LineChartCard> {
  String imageUrl = ''; // Variable para almacenar la URL de la imagen recibida
  late MQTTService mqttService; // Instancia del servicio MQTT

  @override
  void initState() {
    super.initState();
    mqttService = MQTTService(); // Inicializa el servicio MQTT
    _connectAndSubscribe(); // Conecta al broker y suscríbete al tópico
  }

  void _connectAndSubscribe() async {
    await mqttService.connect(); // Conecta al broker MQTT
    mqttService.subscribeToTopic(
        'SecureEyes/image'); // Suscribirse al tópico de imagen

    mqttService.client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final String payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      setState(() {
        imageUrl = payload; // Asigna la URL recibida a la variable imageUrl
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = LineData(); // Datos para la gráfica de líneas

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
              imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
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

        // Tarjeta para mostrar la gráfica de líneas
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Steps Overview",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              AspectRatio(
                aspectRatio: 16 / 6,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                    ),
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return data.bottomTitle[value.toInt()] != null
                                ? SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                        data.bottomTitle[value.toInt()]
                                            .toString(),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[400])),
                                  )
                                : const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          getTitlesWidget: (double value, TitleMeta meta) {
                            return data.leftTitle[value.toInt()] != null
                                ? Text(data.leftTitle[value.toInt()].toString(),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[400]))
                                : const SizedBox();
                          },
                          showTitles: true,
                          interval: 1,
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        color: selectionColor,
                        barWidth: 2.5,
                        belowBarData: BarAreaData(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              selectionColor.withOpacity(0.5),
                              Colors.transparent
                            ],
                          ),
                          show: true,
                        ),
                        dotData: FlDotData(show: false),
                        spots: data.spots,
                      )
                    ],
                    minX: 0,
                    maxX: 120,
                    maxY: 105,
                    minY: -5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    mqttService.client.disconnect(); // Desconectar al salir
    super.dispose();
  }
}
