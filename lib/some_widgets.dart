import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const CustomElevatedButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }
}

class CustomChartWidget extends StatelessWidget {
  final List<FlSpot> points; // Input: list of points
  final Color color; // Input: color for the line
  final bool showDots;

  const CustomChartWidget({
    super.key,
    required this.points,
    required this.color,
    this.showDots = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: points,
                // Use the input points here
                isCurved: true,
                color: color,
                // Use the input color here
                barWidth: 2,
                dotData: FlDotData(show: showDots),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                  reservedSize: 50,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  // Показываем значения оси только под точками
                  getTitlesWidget: (double value, TitleMeta meta) {
                    // Преобразуем value в строку и проверяем, существует ли такое значение в points
                    for (FlSpot spot in points) {
                      if (spot.x.toInt() == value.toInt()) {
                        String formattedValue = value.toStringAsFixed(2);
                        if (value % 1 == 0) {
                          formattedValue = value.toInt().toString();
                        }
                        // Если точка существует в списке, показываем её значение
                        return Text(
                          formattedValue,
                          // Отображаем значение с точностью до двух знаков
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        );
                      }
                    }
                    // Если точки нет в points, не показываем подпись
                    return const Text('');
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}