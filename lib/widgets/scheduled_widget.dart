import 'package:flutter/material.dart';
import 'package:dashboard_secureEyes/data/schedule_task_data.dart';
import 'package:dashboard_secureEyes/widgets/custom_card_widget.dart';
import 'package:dashboard_secureEyes/main.dart';
import 'package:mqtt_client/mqtt_client.dart';

class Scheduled extends StatefulWidget {
  const Scheduled({super.key});

  @override
  _ScheduledState createState() => _ScheduledState();
}

class _ScheduledState extends State<Scheduled> {
  bool _ledStatus = false;
  bool _buzzerStatus = false;

  late MQTTService mqttService;

  @override
  void initState() {
    super.initState();
    mqttService = MQTTService();
    _connectAndSubscribe();
  }

  void _connectAndSubscribe() async {
    await mqttService.connect();

    mqttService.subscribeToTopic('sensor/status/led');
    mqttService.subscribeToTopic('sensor/status/buzzer');

    mqttService.client.updates!
        .listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final MqttPublishMessage recMessage =
          events[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);
      final topic = events[0].topic;

      if (topic == 'sensor/status/led') {
        setState(() {
          _ledStatus = payload == '1';
        });
      } else if (topic == 'sensor/status/buzzer') {
        setState(() {
          _buzzerStatus = payload == '1';
        });
      }
    });
  }

  void _toggleLed(bool value) {
    mqttService.publishMessage('sensor/control/led', value ? '1' : '0');
  }

  void _toggleBuzzer(bool value) {
    mqttService.publishMessage('sensor/control/buzzer', value ? '1' : '0');
  }

  @override
  Widget build(BuildContext context) {
    final data = ScheduleTasksData();

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
                    "Buzzer",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  Switch(
                    value: _buzzerStatus,
                    onChanged: _toggleBuzzer,
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
