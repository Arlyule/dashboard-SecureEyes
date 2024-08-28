import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class LineData {
  List<FlSpot> spots = [];

  // Títulos para los ejes
  final leftTitle = {
    0: '0',
    5: '5',
    10: '10',
    15: '15',
    20: '20',
    25: '25',
  };

  final bottomTitle = {
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'May',
    6: 'Jun',
    7: 'Jul',
    8: 'Aug',
    9: 'Sep',
    10: 'Oct',
    11: 'Nov',
    12: 'Dec',
  };

  // Constructor que inicializa la obtención y procesamiento de datos
  LineData() {
    _fetchAndProcessData();
  }

  Future<void> _fetchAndProcessData() async {
    final url = Uri.parse('https://segureye-server.onrender.com/get-events');

    final body = json.encode({
      "data": {"tiposensor": "PIR Sensor"},
      "accion": 2
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final info = data['info'] as List;

      print('Datos recuperados: $info'); // Verifica los datos obtenidos

      final movementCounts = <int, int>{}; // Contador de movimientos por mes

      for (var entry in info) {
        if (entry['tiposensor'] == 'PIR Sensor' &&
            entry['valorestado'] == "1") {
          final date = DateTime.parse(entry['fechahora']);
          final month = date.month;

          // Contar los movimientos por mes
          movementCounts.update(month, (value) => value + 1, ifAbsent: () => 1);
        }
      }

      print('Movimientos por mes: $movementCounts'); // Verifica el conteo

      // Convertir los datos en puntos para el gráfico
      spots = List.generate(
        12,
        (i) => FlSpot(
          (i + 1).toDouble(), // Mes en el eje X
          movementCounts[i + 1]?.toDouble() ?? 0.0, // Cantidad en el eje Y
        ),
      );

      print('Puntos para el gráfico: $spots'); // Verifica los puntos
    } else {
      throw Exception('Failed to load sensor data');
    }
  }

  // Método público para obtener datos
  Future<void> fetchData() async {
    await _fetchAndProcessData();
  }
}
