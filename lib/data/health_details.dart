class HealthDetails {
  // Valores iniciales para los sensores y el LED
  String _luzValue = "N/A";
  String _ledValue = "N/A";
  String _microfonoValue = "N/A";
  String _pirValue = "N/A";

  // Método para obtener los datos de salud en forma de lista
  List<HealthModel> get healthData => [
        HealthModel(
            icon: 'assets/icons/light_sensor.png',
            value: _luzValue,
            title: "Light Sensor"),
        HealthModel(
            icon: 'assets/icons/led.png',
            value: _ledValue,
            title: "LED Status"),
        HealthModel(
            icon: 'assets/icons/microphone.png',
            value: _microfonoValue,
            title: "Microphone"),
        HealthModel(
            icon: 'assets/icons/pir.png',
            value: _pirValue,
            title: "PIR Sensor"),
      ];

  // Métodos para actualizar los valores desde otras partes de la aplicación
  void updateLuzValue(String value) {
    _luzValue = value;
  }

  void updateLedValue(String value) {
    _ledValue = value;
  }

  void updateMicrofonoValue(String value) {
    _microfonoValue = value;
  }

  void updatePirValue(String value) {
    _pirValue = value;
  }
}

// Clase modelo para representar los datos de salud
class HealthModel {
  final String icon;
  final String value;
  final String title;

  HealthModel({required this.icon, required this.value, required this.title});
}
