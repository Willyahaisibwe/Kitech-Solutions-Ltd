import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/view_models/historical_view_model.dart';
import 'package:smart_crop_dryer/widgets/temperature_line_chart.dart'; // Import your new chart widget

class HistoricalDataPage extends StatelessWidget {
  const HistoricalDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Make sure your ViewModel is provided higher up in the widget tree
    final viewModel = Provider.of<HistoricalReadingViewModel>(context, listen: false);
    
    // Example call to load data when the screen is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
       // Load readings for the last 24 hours on initial screen load
      //viewModel.loadReadingsForLastHours(24);
      viewModel.loadMockData();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historical Temperature Chart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.loadReadingsForToday(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Temperature History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              // --- The Chart Widget ---
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xff232d37), // Dark background for a modern look
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8.0),
                height: 300,
                child: const TemperatureLineChart(),
              ),
              const SizedBox(height: 20),
              // Add a legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.blueAccent, 'Actual Temperature'),
                  const SizedBox(width: 20),
                  _buildLegendItem(Colors.redAccent, 'Desired Temperature (Target)'),
                ],
              ),
              // Additional information or controls here...
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}