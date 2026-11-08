import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:smart_crop_dryer/view_models/smart_home_network_view_model.dart';
import 'package:smart_crop_dryer/view_models/smart_home_sensors_view_model.dart';

class NetworkHealthPage extends StatelessWidget {
  const NetworkHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final networkVM = context.watch<SmartHomeNetworkViewModel>();
    final sensorsVM = context.watch<SmartHomeSensorsViewModel>();

    final isOnline = networkVM.isConnected;
    final isRelayed = isOnline && sensorsVM.sensors.relayed;
    final history = networkVM.history;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          "Network Health",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statusCard(
              isOnline: isOnline,
              isRelayed: isRelayed,
              signalStrength: networkVM.signalStrength,
            ),
            const SizedBox(height: 20),
            const Text(
              "Signal Strength",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              "Live, last 5 minutes",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: history.length < 2
                  ? const SizedBox(
                      height: 220,
                      child: Center(
                        child: Text(
                          "Collecting signal data...",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : SizedBox(height: 220, child: _signalChart(history)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard({
    required bool isOnline,
    required bool isRelayed,
    required double signalStrength,
  }) {
    final Color accent = !isOnline
        ? Colors.red
        : (isRelayed ? Colors.orange : Colors.green);

    final String statusText = !isOnline
        ? "Offline"
        : (isRelayed ? "Online (Relayed)" : "Online");

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOnline
                  ? (isRelayed ? Icons.wifi_tethering : Icons.wifi)
                  : Icons.wifi_off,
              color: accent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline
                      ? "${signalStrength.toStringAsFixed(0)} dBm"
                      : "No connection",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _signalChart(List<SignalSample> history) {
    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.dbm);
    }).toList();

    final values = history.map((s) => s.dbm).toList();
    final double minY = (values.reduce((a, b) => a < b ? a : b) - 5)
        .floorToDouble();
    final double maxY = (values.reduce((a, b) => a > b ? a : b) + 5)
        .ceilToDouble();
    final double maxX = (history.length - 1).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (history.length / 4).round().toDouble().clamp(
                1,
                history.length.toDouble(),
              ),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= history.length) return Container();
                final text = DateFormat('HH:mm:ss').format(history[i].time);
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return const FlLine(
              color: Color(0xff37434d),
              strokeWidth: 0.5,
              dashArray: [5, 5],
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.teal,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.teal.withValues(alpha: 0.3),
                  Colors.teal.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final i = spot.x.toInt();
                if (i < 0 || i >= history.length) return null;
                final time = DateFormat('HH:mm:ss').format(history[i].time);
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(0)} dBm\n$time',
                  const TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}
