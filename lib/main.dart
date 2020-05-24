import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ntp/ntp.dart';

main() => runApp(MainWindow());

class MainWindow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MapRoute(),
    );
  }
}

class MapRoute extends StatefulWidget {
  @override
  _MapRouteState createState() => _MapRouteState();
}

class _MapRouteState extends State<MapRoute> {
  Position _position;
  DateTime _currentTime;
  List<Circle> _circles = [];
  List<Marker> _markers = [];

  final _colors = ColorSwatch(
    0xff0000,
    {
      "red": Color.fromRGBO(255, 0, 0, 0.5),
      "yellow": Color.fromRGBO(255, 255, 0, 0.5),
      "orange": Color.fromRGBO(255, 165, 0, 0.5),
    },
  );

  Future<Position> _getPositionAndTime() async {
    _position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);

    _currentTime = await NTP.now();
    return _position;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _getPositionAndTime(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return StreamBuilder(
              stream:
                  Firestore.instance.collection("patientLocations").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  _initializePatientLocations(snapshot);
                  return _getMap(context);
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      CircularProgressIndicator(),
                      Text("Fetching patient data"),
                    ],
                  ),
                );
              },
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
                Text("Fetching Location"),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getMap(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: LatLng(_position.latitude, _position.longitude),
          zoom: 18,
        ),
        circles: Set.from(_circles),
        markers: Set.from(_markers),
      ),
    );
  }

  void _initializePatientLocations(AsyncSnapshot snapshot) {
    List<DocumentSnapshot> documents = snapshot.data.documents;

    _markers.add(Marker(
      markerId: MarkerId("bishoftu"),
      position: LatLng(_position.latitude, _position.longitude),
      infoWindow: InfoWindow(title: "Your location"),
      icon: BitmapDescriptor.fromAsset("assets/icons/currentLocation.png"),
    )); //Location of user
    List<String> months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    for (int i = 0; i < snapshot.data.documents.length; i++) {
      GeoPoint location = documents[i]["location"];
      DateTime patientDiscovered = documents[i]["discovered"].toDate();
      Color color = _decideColor(patientDiscovered);
      _markers.add(
        Marker(
          markerId: MarkerId("marker$i"),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(
            title:
                "${months[patientDiscovered.month - 1]}, ${patientDiscovered.day} ${patientDiscovered.year} ",
          ),
          icon: BitmapDescriptor.fromAsset("assets/icons/patientLocation.png"),
        ),
      );
      _circles.add(Circle(
        circleId: CircleId("circle$i"),
        center: LatLng(location.latitude, location.longitude),
        radius: 50,
        fillColor: color,
        strokeColor: Colors.transparent,
      ));
    }
  }

  Color _decideColor(DateTime patientTime) {
    if (_currentTime.month - patientTime.month > 1) return _colors["yellow"];

    int dayDifference = _currentTime.day - patientTime.day;

    if (dayDifference < 0) dayDifference += 30;
    if (dayDifference <= 14) return _colors["red"];
    return _colors["orange"];
  }
}
