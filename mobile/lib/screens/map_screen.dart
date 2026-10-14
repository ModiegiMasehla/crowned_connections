import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/salon.dart';

class MapScreen extends StatelessWidget{
  final List<Salon> salons;
  const MapScreen({super.key,required this.salons});
  @override Widget build(BuildContext context){
    final points=salons.where((s)=>s.latitude!=null&&s.longitude!=null).toList();
    final center=points.isNotEmpty?LatLng(points.first.latitude!,points.first.longitude!):const LatLng(-25.7479,28.2293);
    return Scaffold(appBar:AppBar(title:const Text('Nearby salons')),body:GoogleMap(
      initialCameraPosition:CameraPosition(target:center,zoom:11),
      markers:points.map((s)=>Marker(markerId:MarkerId(s.id),position:LatLng(s.latitude!,s.longitude!),infoWindow:InfoWindow(title:s.name))).toSet(),
      myLocationEnabled:false,
    ));
  }
}
