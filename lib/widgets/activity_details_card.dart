import 'dart:io';
import 'package:dashboard_secureeyes/util/responsive.dart';
import 'package:dashboard_secureeyes/widgets/custom_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart'; // Para grabación de audio
import 'package:dashboard_secureeyes/main.dart'; // Importar MQTTService
import 'package:mqtt_client/mqtt_client.dart';

class ActivityDetailsCard extends StatefulWidget {
  const ActivityDetailsCard({super.key});

  @override
  _ActivityDetailsCardState createState() => _ActivityDetailsCardState();
}

class _ActivityDetailsCardState extends State<ActivityDetailsCard> {
  FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  final MQTTService mqttService = MQTTService(); // Instancia de MQTTService

  // Variables para almacenar los estados de los sensores y el LED
  String _luzValue = "N/A";
  String _ledValue = "N/A";
  String _microfonoValue = "N/A";
  String _pirValue = "N/A";

  @override
  void initState() {
    super.initState();
    _initAudioRecorder();
    _setupMQTT();
  }

  void _initAudioRecorder() async {
    await _audioRecorder.openRecorder();
  }

  void _setupMQTT() {
    mqttService.connect().then((_) {
      // Suscribirse a tópicos de sensor de luz, PIR, y LED
      mqttService.subscribeToTopic('sistema_segureye_esp2/sensor_luz');
      mqttService.subscribeToTopic('sistema_segureye_esp2/sensor_pir');
      mqttService.subscribeToTopic('sistema_segureye_esp2/led');

      // Escuchar actualizaciones de los tópicos
      mqttService
          .getStream()
          .listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final MqttPublishMessage recMessage =
            messages[0].payload as MqttPublishMessage;
        final String message = MqttPublishPayload.bytesToStringAsString(
            recMessage.payload.message);

        switch (messages[0].topic) {
          case 'sistema_segureye_esp2/sensor_luz':
            setState(() {
              _luzValue = message;
            });
            break;
          case 'sistema_segureye_esp2/sensor_pir':
            setState(() {
              _pirValue = message;
            });
            break;
          case 'sistema_segureye_esp2/led':
            setState(() {
              _ledValue = message;
            });
            break;
        }
      });
    });
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount:
          5, // Número de ítems a mostrar (sensor de luz, LED, micrófono, botón de reproducir, PIR)
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
          // LED
          return CustomCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/icons/led.png', width: 30, height: 30),
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 4),
                  child: Text(
                    _ledValue == "1" ? "Encendido" : "Apagado",
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Text(
                  "LED Status",
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal),
                ),
              ],
            ),
          );
        } else if (index == 2) {
          // Micrófono (Grabación de audio)
          return CustomCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onLongPress: () async {
                    if (!_isRecording) {
                      setState(() {
                        _isRecording = true;
                      });
                      await _audioRecorder.startRecorder();
                      mqttService.publishMessage(
                          'segureye/control/grabar', '{"msg": "on"}');
                    }
                  },
                  onLongPressUp: () async {
                    if (_isRecording) {
                      String? path = await _audioRecorder.stopRecorder();
                      setState(() {
                        _isRecording = false;
                      });
                      if (path != null) {
                        final file = File(path);
                        final fileBytes = await file.readAsBytes();
                        mqttService.publishMessage(
                            'sensor/microfono', fileBytes.toString());
                      }
                      mqttService.publishMessage(
                          'segureye/control/grabar', '{"msg": "off"}');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isRecording ? Icons.stop : Icons.mic,
                            color: Colors.white, size: 30),
                        SizedBox(height: 10),
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
                  icon: Icon(Icons.play_arrow, color: Colors.white, size: 30),
                  onPressed: () {
                    mqttService.publishMessage(
                        'segureye/control/reproducir', '{"msg": "on"}');
                  },
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
                Image.asset('assets/icons/pir.png', width: 30, height: 30),
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 4),
                  child: Text(
                    _pirValue == "1" ? "Objeto detectado" : "Nada",
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Text(
                  "PIR Sensor",
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal),
                ),
              ],
            ),
          );
        } else {
          // Otros ítems
          return CustomCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/icons/default.png', width: 30, height: 30),
                const Padding(
                  padding: EdgeInsets.only(top: 15, bottom: 4),
                  child: Text(
                    "N/A",
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Text(
                  "Not Available",
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.normal),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
