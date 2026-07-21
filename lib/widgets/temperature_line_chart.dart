import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_crop_dryer/models/historical_reading.dart';
import 'package:smart_crop_dryer/view_models/historical_view_model.dart';

class TemperatureLineChart extends StatelessWidget {
  const TemperatureLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoricalReadingViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.readings.isEmpty) {
          return const Center(child: Text("No historical data available."));
        }

        // --- Data Preparation ---
        final List<HistoricalReading> readings = viewModel.readings;
        final List<FlSpot> actualTempSpots = readings.asMap().entries.map((
          entry,
        ) {
          return FlSpot(entry.key.toDouble(), entry.value.temperature);
        }).toList();

        final List<FlSpot> desiredTempSpots = readings.asMap().entries.map((
          entry,
        ) {
          return FlSpot(entry.key.toDouble(), entry.value.desiredTemp);
        }).toList();

        // Calculate Y-axis scaling
        final double minTemp = readings
            .map((r) => r.temperature)
            .reduce((a, b) => a < b ? a : b);
        final double maxTemp = readings
            .map((r) => r.temperature)
            .reduce((a, b) => a > b ? a : b);
        final double overallMinY = [
          minTemp,
          ...readings.map((r) => r.desiredTemp),
        ].reduce((a, b) => a < b ? a : b);
        final double overallMaxY = [
          maxTemp,
          ...readings.map((r) => r.desiredTemp),
        ].reduce((a, b) => a > b ? a : b);

        final double minY = (overallMinY - 2).floorToDouble();
        final double maxY = (overallMaxY + 2).ceilToDouble();
        final double maxX = (readings.length - 1).toDouble();

        return AspectRatio(
          aspectRatio: 1.5,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 18,
              left: 12,
              top: 24,
              bottom: 12,
            ),
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                titlesData: _buildTitlesData(readings),
                gridData: _buildGridData(),
                borderData: _buildBorderData(),
                lineBarsData: [
                  // Actual Temperature Line
                  _buildLineBarData(
                    spots: actualTempSpots,
                    color: Colors.blueAccent,
                  ),
                  // Desired Temperature Line
                  _buildLineBarData(
                    spots: desiredTempSpots,
                    color: Colors.redAccent,
                    isDashed: true,
                  ),
                ],
                lineTouchData: _buildLineTouchData(readings),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Corrected Chart Component Builders ---

  FlTitlesData _buildTitlesData(List<HistoricalReading> readings) {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      // X-axis (Time labels)
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          // Show ~5 labels, ensuring it's at least 1
          interval: (readings.length / 5).round().toDouble().clamp(
            1,
            readings.length.toDouble(),
          ),
          getTitlesWidget: (value, meta) {
            if (value.toInt() < 0 || value.toInt() >= readings.length) {
              return Container();
            }
            final reading = readings[value.toInt()];
            final dateTime = DateTime.fromMillisecondsSinceEpoch(
              reading.timestamp,
            );
            final text = DateFormat('H:mm').format(dateTime);

            // CORRECTED SideTitleWidget usage: Use meta.axisSide and space
            return SideTitleWidget(
              meta: meta,
              space: 8.0,
              child: Text(
                text,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            );
          },
        ),
      ),
      // Y-axis (Temperature labels)
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 2,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Text(
              '${value.toInt()}°C',
              style: const TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.left,
            );
          },
        ),
      ),
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      horizontalInterval: 2,
      verticalInterval: 1,
      getDrawingHorizontalLine: (value) {
        // CORRECTED FlLine usage: No const keyword needed when providing arguments
        return const FlLine(
          color: Color(0xff37434d),
          strokeWidth: 0.5,
          dashArray: [5, 5],
        );
      },
      getDrawingVerticalLine: (value) {
        // CORRECTED FlLine usage
        return const FlLine(color: Color(0xff37434d), strokeWidth: 0.5);
      },
    );
  }

  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(color: const Color(0xff37434d), width: 1),
    );
  }

  LineChartBarData _buildLineBarData({
    required List<FlSpot> spots,
    required Color color,
    bool isDashed = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      dashArray: isDashed ? [5, 5] : null,
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  LineTouchData _buildLineTouchData(List<HistoricalReading> readings) {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((LineBarSpot touchedSpot) {
            final readingIndex = touchedSpot.x.toInt();
            if (readingIndex < 0 || readingIndex >= readings.length) {
              return null;
            }
            final reading = readings[readingIndex];
            final dateTime = DateTime.fromMillisecondsSinceEpoch(
              reading.timestamp,
            );
            final time = DateFormat('HH:mm:ss').format(dateTime);

            final String label = touchedSpot.barIndex == 0
                ? 'Actual'
                : 'Desired';

            return LineTooltipItem(
              '$label: ${touchedSpot.y.toStringAsFixed(1)}°C\nTime: $time',
              TextStyle(
                color: touchedSpot.bar.color,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
