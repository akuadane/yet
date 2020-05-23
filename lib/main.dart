import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  Future<Position> _getPostion() async {
    _position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
    return _position;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _getPostion(),
        builder: (context, snapshot) {
          if (snapshot.data != null) {
            return _getMap(context);
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
        markers: {
          Marker(
            markerId: MarkerId("bishoftu"),
            position: LatLng(_position.latitude, _position.longitude),
            infoWindow: InfoWindow(title: "megabit 1 2012"),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          )
        },
      ),
    );
  }
}
