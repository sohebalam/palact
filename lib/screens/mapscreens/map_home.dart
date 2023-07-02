import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:provider/provider.dart';
import 'package:palaction/screens/mapscreens/results_page.dart';
import 'package:intl/intl.dart';
import 'package:palaction/shared/auth_service.dart';

import 'package:palaction/shared/carpark_space_db_helper.dart';
import 'package:palaction/shared/functions.dart';
import 'package:palaction/shared/widgets/app_bar.dart';
import 'package:palaction/shared/widgets/drawer.dart';

class MapHome extends StatefulWidget {
  const MapHome({Key? key}) : super(key: key);

  @override
  State<MapHome> createState() => _MapHomeState();
}

class _MapHomeState extends State<MapHome> {
  late GoogleMapController mapController;
  DateTime _selectedDateTimeStart = roundToNearest15Minutes(DateTime.now());
  DateTime _selectedDateTimeEnd =
      roundToNearest15Minutes(DateTime.now().add(const Duration(hours: 1)));

  LatLng _currentPosition = const LatLng(0, 0);
  bool _isLoading = true;
  String? _selectedOption;
  final _placesApiClient =
      GoogleMapsPlaces(apiKey: 'AIzaSyCY8J7h0Q-5Q1UDP9aY0EOy_WZBPESNBBg');
  String _searchTerm = '';
  LatLng? location;

  @override
  void initState() {
    super.initState();
    getLocation();
    _selectedOption = 'Current Location';
  }

  void retrieveNearestSpaces(double? latitude, double? longitude) async {
    final nearestSpaces = await DB_CarPark.getNearestSpaces(
      latitude: latitude,
      longitude: longitude,
    );

    List<List<dynamic>> results = [];
    for (var space in nearestSpaces) {
      results.add([
        space.p_id,
        space.latitude,
        space.longitude,
        space.title,
        space.postcode,
        space.address,
        space.p_image,
        space.u_id,
      ]);
    }

    List<List<dynamic>> filteredResults = await filterBookings(
      results,
      _selectedDateTimeStart,
      _selectedDateTimeEnd,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsPage(
          location: LatLng(latitude!, longitude!),
          results: filteredResults,
          latitude: _currentPosition.latitude,
          longitude: _currentPosition.longitude,
          startdatetime: _selectedDateTimeStart,
          enddatetime: _selectedDateTimeEnd,
        ),
      ),
    );
  }

  getLocation() async {
    LocationPermission permission;
    permission = await Geolocator.requestPermission();

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    double lat = position.latitude;
    double long = position.longitude;

    LatLng location = LatLng(lat, long);

    setState(() {
      _currentPosition = location;
      _isLoading = false;
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  List<Prediction> _predictions = [];

  void _onDropdownChanged(String? value) {
    setState(() {
      _selectedOption = value;
    });

    if (_selectedOption == 'Current Location') {
      retrieveNearestSpaces(
          _currentPosition.latitude, _currentPosition.longitude);
    }
  }

  void _onSearchChanged(String value) async {
    if (value.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _searchTerm = value;
      });

      PlacesAutocompleteResponse response =
          await _placesApiClient.autocomplete(_searchTerm);

      setState(() {
        _isLoading = false;
        _predictions = response.predictions;
      });
    } else {
      setState(() {
        _predictions = [];
      });
    }
  }

  void _onPredictionSelected(Prediction prediction) async {
    PlacesDetailsResponse details =
        await _placesApiClient.getDetailsByPlaceId(prediction.placeId ?? "");

    setState(() {
      location = LatLng(
        details.result.geometry?.location.lat ?? 0.0,
        details.result.geometry?.location.lng ?? 0.0,
      );
      retrieveNearestSpaces(location?.latitude, location?.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final isLoggedInStream = authService.user!.map((user) => user != null);
    final Set<Marker> _markers = {
      Marker(
        markerId: MarkerId('current_location'),
        position: _currentPosition,
      )
    };

    return Scaffold(
      appBar: CustomAppBar(
          title: 'Map',
          isLoggedInStream: isLoggedInStream,
          padding: EdgeInsets.fromLTRB(0, 0, 1, 0)),
      drawer: AppDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition,
                zoom: 16.0,
              ),
              markers: _markers,
            ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(10.0),
        color: Colors.white,
        height: MediaQuery.of(context).size.height / 4,
        child: Column(
          children: [
            const SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: _selectedOption,
              items: <String>['Current Location'].map((String option) {
                return DropdownMenuItem(
                  value: option,
                  child: Row(
                    children: [
                      Icon(Icons.location_pin),
                      SizedBox(width: 8.0),
                      Text(option),
                    ],
                  ),
                );
              }).toList(),
              onChanged: _onDropdownChanged,
              decoration: InputDecoration(
                  // labelText: 'Select an option',
                  ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Search for another Location',
              ),
              onChanged: _onSearchChanged,
            ),
            _isLoading
                ? CircularProgressIndicator()
                : _predictions.isNotEmpty
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: _predictions.length,
                          itemBuilder: (context, index) {
                            final prediction = _predictions[index];
                            return ListTile(
                              title: Text(prediction.description ?? ""),
                              onTap: () {
                                _onPredictionSelected(prediction);
                              },
                            );
                          },
                        ),
                      )
                    : SizedBox.shrink(),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}

Future<List<List<dynamic>>> filterBookings(List<List<dynamic>> nearestSpaces,
    DateTime startDateTime, DateTime endDateTime) async {
  final bookingsSnapshot =
      await FirebaseFirestore.instance.collection('bookings').get();

  List<List<dynamic>> filteredResults = [];

  for (var space in nearestSpaces) {
    final spaceDoc = await FirebaseFirestore.instance
        .collection('parking_spaces')
        .doc(space[0])
        .get();
    final isPublished = spaceDoc.data()?['isPublished'] ?? false;

    if (isPublished) {
      filteredResults.add(space);
    }
  }

  return filteredResults;
}
