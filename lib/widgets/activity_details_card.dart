import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dashboard_secureeyes/util/responsive.dart';
import 'package:dashboard_secureeyes/widgets/custom_card_widget.dart';
import 'package:dashboard_secureeyes/main.dart'; // Importar MQTTService
import 'package:mqtt_client/mqtt_client.dart';

class ActivityDetailsCard extends StatefulWidget {
  const ActivityDetailsCard({super.key});

  @override
  _ActivityDetailsCardState createState() => _ActivityDetailsCardState();
}

class _ActivityDetailsCardState extends State<ActivityDetailsCard> {
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isAlarmActive = false;
  bool _isButtonVisible = true;
  late MQTTService mqttService;

  String _luzValue = "N/A";
  String _ledValue = "N/A";
  String _microfonoValue = "N/A";
  String reproduccion = "N/A";
  String _pirValue = "N/A";
  Timer? _playbackTimer; // Timer para el control de reproducción
  Timer? _alarmTimer; // Timer para el control de alarma

  @override
  void initState() {
    super.initState();
    mqttService = MQTTService();
    _setupMQTT();
  }

  void _setupMQTT() async {
    await mqttService.connect();

    mqttService.subscribeToTopic('sensor_data/light');
    mqttService.subscribeToTopic('sensor_data/pir');
    mqttService.subscribeToTopic('segureye/control/grabar');
    mqttService.subscribeToTopic('segureye/control/reproducir');
    mqttService.subscribeToTopic('segureye/buzzer/control');

    mqttService.client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final MqttPublishMessage recMessage =
          events[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
      final topic = events[0].topic;

      if (topic == 'sensor_data/light') {
        setState(() {
          _luzValue = payload;
        });
      } else if (topic == 'sensor_data/pir') {
        setState(() {
          _pirValue = payload == '1' ? '¡Movimiento Detectado!' : 'Nada';
        });
      } else if (topic == 'segureye/control/grabar') {
        setState(() {
          _microfonoValue = payload;
        });
      } else if (topic == 'segureye/control/reproducir') {
        setState(() {
          reproduccion = payload;
        });
      } else if (topic == 'segureye/buzzer/control') {
        setState(() {
          _ledValue = payload; // Ajuste el valor del LED si es necesario
        });
      }
    });
  }

  void _handlePlayback() {
    if (_isPlaying) {
      mqttService.publishMessage('segureye/control/reproducir', 'stop');
      _playbackTimer?.cancel();
      setState(() {
        _isPlaying = false;
      });
    } else {
      mqttService.publishMessage('segureye/control/reproducir', 'start');
      setState(() {
        _isPlaying = true;
      });

      _playbackTimer = Timer(Duration(seconds: 10), () {
        mqttService.publishMessage('segureye/control/reproducir', 'stop');
        setState(() {
          _isPlaying = false;
        });
      });
    }
  }

  void _handleAlarm() {
    if (_isAlarmActive) {
      // Si la alarma ya está activa, no hacer nada
      return;
    }
    mqttService.publishMessage('segureye/buzzer/control', 'on');
    setState(() {
      _isAlarmActive = true;
      _isButtonVisible = false;
    });

    // Temporizador para desactivar la alarma después de 6 segundos
    _alarmTimer = Timer(Duration(seconds: 6), () {
      setState(() {
        _isAlarmActive = false;
        _isButtonVisible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 5,
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
        crossAxisSpacing: Responsive.isMobile(context) ? 12 : 15,
        mainAxisSpacing: 12.0,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          // Sensor de luz
          return CustomCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  _luzValue == "alto"
                      ? 'assets/icons/sun.png'
                      : 'assets/icons/sleep.png',
                  width: 30,
                  height: 30,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 4),
                  child: Text(
                    _luzValue,
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Text(
                  "Light Sensor",
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal),
                ),
              ],
            ),
          );
        } else if (index == 1) {
          // Alarma
          return CustomCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_isButtonVisible)
                  ElevatedButton(
                    onPressed: _handleAlarm,
                    child: Text("Activar Alarma"),
                  ),
                if (_isAlarmActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 4),
                    child: Text(
                      "Sonando",
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                if (!_isAlarmActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 4),
                    child: Text(
                      "Alarma",
                      style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                const Text(
                  "Alarma",
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal),
                ),
              ],
            ),
          );
        } else if (index == 2) {
          // Micrófono (Botón de grabación de audio)
          return CustomCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onLongPress: () {
                    setState(() {
                      _isRecording = true;
                    });
                    mqttService.publishMessage(
                        'segureye/control/grabar', 'start');
                  },
                  onLongPressUp: () {
                    setState(() {
                      _isRecording = false;
                    });
                    mqttService.publishMessage(
                        'segureye/control/grabar', 'stop');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white, size: 30),
                        const SizedBox(height: 10),
                        Text(
                          _isRecording ? "Grabando..." : "Grabar Audio",
                          style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const Text(
                  "Micrófono",
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal),
                ),
              ],
            ),
          );
        } else if (index == 3) {
          // Botón de reproducir audio
          return CustomCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: _handlePlayback,
                ),
                const Text(
                  "Reproducir Audio",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        } else if (index == 4) {
          // Sensor PIR
          return CustomCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  _pirValue == '¡Movimiento Detectado!'
                      ? Icons.directions_run
                      : Icons.remove_red_eye,
                  color: Colors.white,
                  size: 30,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 4),
                  child: Text(
                    _pirValue,
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Text(
                  "Sensor PIR",
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal),
                ),
              ],
            ),
          );
        } else {
          return Container(); // Just in case of an invalid index
        }
      },
    );
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _alarmTimer?.cancel();
    super.dispose();
  }
}
