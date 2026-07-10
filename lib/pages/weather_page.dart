import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/models/weather.dart';
import 'package:smart_crop_dryer/view_models/weather_view_model.dart';


class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool isLoading = false;

  // Mock data - replace with actual API call
  Weather? currentWeather;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _slideController.forward();
    _loadWeather();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _loadWeather() {
    setState(() {
      isLoading = true;
    });

    Provider.of<WeatherViewModel>(context, listen: false)
        .fetchWeather('Kampala')
        .then((_) {
      setState(() {
        currentWeather =
            Provider.of<WeatherViewModel>(context, listen: false).weather;
        isLoading = false;
      });
    });
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return MdiIcons.weatherSunny;
      case 'clouds':
        return MdiIcons.weatherCloudy;
      case 'rain':
        return MdiIcons.weatherRainy;
      case 'drizzle':
        return MdiIcons.weatherPartlyRainy;
      case 'thunderstorm':
        return MdiIcons.weatherLightning;
      case 'snow':
        return MdiIcons.weatherSnowy;
      case 'mist':
      case 'fog':
        return MdiIcons.weatherFog;
      default:
        return MdiIcons.weatherPartlyCloudy;
    }
  }

  Color _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Colors.orange.shade600;
      case 'clouds':
        return Colors.blue.shade400;
      case 'rain':
      case 'drizzle':
        return Colors.blue.shade700;
      case 'thunderstorm':
        return Colors.purple.shade600;
      default:
        return Colors.blue.shade500;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back, color: Colors.grey.shade700),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Weather Conditions",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                MdiIcons.refresh,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ),
            onPressed: isLoading ? null : _loadWeather,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.blue.shade600,
              ),
            )
          : currentWeather == null
              ? _buildErrorState()
              : SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Main Weather Card
                        _buildMainWeatherCard(),
                        const SizedBox(height: 16),

                        // Weather Details Grid
                        _buildWeatherDetailsGrid(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildMainWeatherCard() {
    final weatherColor = _getWeatherColor(currentWeather!.conditionMain);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            weatherColor.withValues(alpha: 0.1),
            weatherColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                MdiIcons.mapMarker,
                color: weatherColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                currentWeather!.cityName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Weather Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: weatherColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _getWeatherIcon(currentWeather!.conditionMain),
              size: 80,
              color: weatherColor,
            ),
          ),
          const SizedBox(height: 24),

          // Temperature
          Text(
            '${currentWeather!.temperatureCelsius.round()}°C',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: weatherColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),

          // Condition Description
          Text(
            currentWeather!.conditionDescription.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildWeatherDetailsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                icon: MdiIcons.waterPercent,
                label: 'Humidity',
                value: '${currentWeather!.humidityPercent}%',
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailCard(
                icon: MdiIcons.weatherWindy,
                label: 'Wind Speed',
                value: '${currentWeather!.windSpeedMps} m/s',
                color: Colors.teal.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                icon: MdiIcons.thermometer,
                label: 'Feels Like',
                value: '${(currentWeather!.temperatureCelsius - 2).round()}°C',
                color: Colors.orange.shade600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailCard(
                icon: MdiIcons.eye,
                label: 'Conditions',
                value: currentWeather!.conditionMain,
                color: Colors.purple.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              MdiIcons.weatherCloudy,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load weather',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}