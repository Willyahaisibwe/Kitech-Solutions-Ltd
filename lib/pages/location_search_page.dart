import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smart_crop_dryer/models/geo_location.dart';
import 'package:smart_crop_dryer/view_models/weather_view_model.dart';

/// Lets the user search for any place in Uganda and returns the chosen
/// GeoLocation via Navigator.pop when tapped.
class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({super.key});

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<GeoLocation> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _errorMessage = null;
    });

    try {
      final viewModel = Provider.of<WeatherViewModel>(context, listen: false);
      final results = await viewModel.searchLocations(query.trim());
      setState(() {
        _results = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _isSearching = false;
        _errorMessage = 'Could not search right now. Please try again.';
      });
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
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search a place',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'e.g. Matugga, Entebbe, Mukono',
                prefixIcon: Icon(MdiIcons.magnify, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(color: Colors.blue.shade600),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    if (_hasSearched && _results.isEmpty) {
      return Center(
        child: Text(
          'No places found. Try a different spelling.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Text(
          'Search for any town, district, or place in Uganda',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade400),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _results.length,
      separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200),
      itemBuilder: (context, index) {
        final location = _results[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(MdiIcons.mapMarker, color: Colors.blue.shade600),
          title: Text(
            location.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(location.displayLabel),
          onTap: () => Navigator.pop(context, location),
        );
      },
    );
  }
}
