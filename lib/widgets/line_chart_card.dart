import 'package:dashboard_secureeyes/const/constant.dart';
import 'package:dashboard_secureeyes/data/line_chart_data.dart';
import 'package:dashboard_secureeyes/main.dart';
import 'package:dashboard_secureeyes/widgets/custom_card_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:typed_data';

class LineChartCard extends StatefulWidget {
  const LineChartCard({super.key});

  static final LineChartCardController controller = LineChartCardController();

  @override
  _LineChartCardState createState() => _LineChartCardState();
}

class _LineChartCardState extends State<LineChartCard> {
  Uint8List? imageData;
  late MQTTService mqttService;
  late Future<void> _lineDataFuture;
  late LineData lineData;

  // Variables para la nueva gráfica de datos de luz
  List<FlSpot> lightSpots = [];
  double minX = 0;
  double maxX = 10;
  double minY = 0;
  double maxY = 10;

  @override
  void initState() {
    super.initState();
    mqttService = MQTTService();
    LineChartCard.controller.startImageTransmission = _connectAndSubscribe;
    lineData = LineData();
    _lineDataFuture =
        lineData.fetchData(); // Usa fetchData en lugar de _fetchAndProcessData
    _connectAndSubscribeLightData(); // Conecta y suscribe al tópico de datos de luz
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                  ? Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationX(3.14159),
                      child: Image.memory(
                        imageData!,
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                      ),
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
        const SizedBox(height: 20),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Steps Overview",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              FutureBuilder<void>(
                future: _lineDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return AspectRatio(
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
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                  return lineData.bottomTitle[value.toInt()] !=
                                          null
                                      ? SideTitleWidget(
                                          axisSide: meta.axisSide,
                                          child: Text(
                                              lineData
                                                  .bottomTitle[value.toInt()]
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
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                  return lineData.leftTitle[value.toInt()] !=
                                          null
                                      ? Text(
                                          lineData.leftTitle[value.toInt()]
                                              .toString(),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[400]))
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
                              spots: lineData.spots,
                            )
                          ],
                          minX: 1,
                          maxX: 12,
                          minY: 0,
                          maxY: lineData.spots.isNotEmpty
                              ? lineData.spots
                                  .map((e) => e.y)
                                  .reduce((a, b) => a > b ? a : b)
                              : 10,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Nueva tarjeta de la gráfica de datos de luz
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Light Sensor Data",
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
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                value.toString(),
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[400]),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toString(),
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[400]),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        color: Colors.blue,
                        barWidth: 2.5,
                        belowBarData: BarAreaData(show: false),
                        dotData: FlDotData(show: false),
                        spots: lightSpots,
                      ),
                    ],
                    minX: minX,
                    maxX: maxX,
                    minY: minY,
                    maxY: maxY,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Método para suscribirse y manejar datos de luz
  void _connectAndSubscribeLightData() async {
    await mqttService.connect();
    mqttService.subscribeToTopic('sensor_data/light');

    mqttService.client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final String payload =
          String.fromCharCodes(message.payload.message.toList());

      setState(() {
        // Parse the light value and update the graph
        final double lightValue = double.tryParse(payload) ?? 0.0;
        lightSpots.add(FlSpot(lightSpots.length.toDouble(), lightValue));

        // Update min/max values for the graph
        minX = 0;
        maxX = lightSpots.length.toDouble();
        minY = lightSpots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
        maxY = lightSpots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      });
    });
  }

  Future<void> _connectAndSubscribe() async {
    await mqttService.connect();
    mqttService.subscribeToTopic('secureeyes/video');

    mqttService.client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
      final Uint8List payload =
          Uint8List.fromList(message.payload.message.buffer.asUint8List());

      setState(() {
        imageData = payload;
      });
    });
  }
}

class LineChartCardController {
  late VoidCallback startImageTransmission;
}
