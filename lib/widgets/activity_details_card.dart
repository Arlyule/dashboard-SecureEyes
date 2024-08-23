import 'dart:io';
import 'package:dashboard_secureeyes/data/health_details.dart';
import 'package:dashboard_secureeyes/util/responsive.dart';
import 'package:dashboard_secureeyes/widgets/custom_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart'; // Para grabación de audio

class ActivityDetailsCard extends StatefulWidget {
  const ActivityDetailsCard({super.key});

  @override
  _ActivityDetailsCardState createState() => _ActivityDetailsCardState();
}

class _ActivityDetailsCardState extends State<ActivityDetailsCard> {
  FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  final HealthDetails healthDetails =
      HealthDetails(); // Instancia de HealthDetails

  @override
  void initState() {
    super.initState();
    _initAudioRecorder();
  }

  void _initAudioRecorder() async {
    await _audioRecorder.openRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: healthDetails.healthData.length,
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
        crossAxisSpacing: Responsive.isMobile(context) ? 12 : 15,
        mainAxisSpacing: 12.0,
      ),
      itemBuilder: (context, index) {
        final item = healthDetails.healthData[index];

        if (index == 0) {
          // Sensor de luz
          return CustomCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  item.value == "alto"
                      ? 'assets/icons/sun.png'
                      : 'assets/icons/sleep.png',
                  width: 30,
                  height: 30,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 4),
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
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
                Image.asset(
                  'assets/icons/led.png',
                  width: 30,
                  height: 30,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 4),
                  child: Text(
                    item.value == "1" ? "Encendido" : "Apagado",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        } else if (index == 2) {
          // Micrófono
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
                    }
                  },
                  onLongPressUp: () async {
                    if (_isRecording) {
                      String? path = await _audioRecorder.stopRecorder();
                      setState(() {
                        _isRecording = false;
                      });
                      if (path != null) {
                        // Enviar archivo grabado a MQTT
                        final file = File(path);
                        final fileBytes = await file.readAsBytes();
                        healthDetails.mqttService.publishMessage(
                            'sensor/microfono', fileBytes.toString());
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 30,
                        ),
                        SizedBox(height: 10),
                        Text(
                          _isRecording ? "Grabando..." : "Grabar Audio",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        } else if (index == 3) {
          // Sensor PIR
          return CustomCard(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/pir.png',
                  width: 30,
                  height: 30,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 4),
                  child: Text(
                    item.value == "1" ? "Objeto detectado" : "Nada",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
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
                Image.asset(
                  item.icon,
                  width: 30,
                  height: 30,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 15, bottom: 4),
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
