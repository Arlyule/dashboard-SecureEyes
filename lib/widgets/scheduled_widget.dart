import 'package:flutter/material.dart';
import 'package:dashboard_secureeyes/widgets/custom_card_widget.dart';
import 'package:dashboard_secureeyes/main.dart';
import 'package:mqtt_client/mqtt_client.dart';

class Scheduled extends StatefulWidget {
  final VoidCallback onStartVideo;

  const Scheduled({super.key, required this.onStartVideo});

  @override
  _ScheduledState createState() => _ScheduledState();
}

class _ScheduledState extends State<Scheduled> {
  bool _ledStatus = false;
  bool _videoStatus = false;

  late MQTTService mqttService;

  @override
  void initState() {
    super.initState();
    mqttService = MQTTService();
    _connectAndSubscribe();
  }

  void _connectAndSubscribe() async {
    await mqttService.connect();

    mqttService.subscribeToTopic('sistema_segureye_esp2/led');
    mqttService.subscribeToTopic('sistema_segureye_esp2/video');

    mqttService.client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final MqttPublishMessage recMessage =
          events[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
      final topic = events[0].topic;

      if (topic == 'sistema_segureye_esp2/led') {
        setState(() {
          _ledStatus = payload == '{"msg": "on"}';
        });
      } else if (topic == 'sistema_segureye_esp2/video') {
        setState(() {
          _videoStatus = payload == '{"msg": "on"}';
        });
      }
    });
  }

  void _toggleLed(bool value) {
    mqttService.publishMessage('sistema_segureye_esp2/led',
        value ? '{"msg": "on"}' : '{"msg": "off"}');
  }

  void _toggleVideo(bool value) {
    mqttService.publishMessage('sistema_segureye_esp2/video',
        value ? '{"msg": "on"}' : '{"msg": "off"}');

    if (value) {
      widget.onStartVideo();
    } else {
      mqttService.unsubscribeFromTopic('sistema_segureye_esp2/cam_0');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Control Sensores",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        CustomCard(
          color: Colors.black,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "LED",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: _ledStatus,
                    onChanged: _toggleLed,
                    activeColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Video",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: _videoStatus,
                    onChanged: _toggleVideo,
                    activeColor: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
