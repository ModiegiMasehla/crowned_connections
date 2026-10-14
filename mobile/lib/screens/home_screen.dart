import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/salon.dart';
import '../services/api_service.dart';
import 'salon_screen.dart';
import 'owner_dashboard.dart';
import 'map_screen.dart';
import 'appointments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState()=>_HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  final q=TextEditingController();
  List<Salon> salons=[];
  bool loading=false;
  Position? position;
  String? error;
  String? role;

  Future<void> loadUser() async {
    try {
      final data=await ApiService.get('/auth/me');
      role=data['user']['role'];
      if(mounted)setState((){});
    } catch (_) {}
  }

  Future<void> locate() async{
    try{
      if(!await Geolocator.isLocationServiceEnabled())throw Exception('Please enable location services or search without location.');
      var permission=await Geolocator.checkPermission();
      if(permission==LocationPermission.denied)permission=await Geolocator.requestPermission();
      if(permission==LocationPermission.denied||permission==LocationPermission.deniedForever)throw Exception('Location permission was not granted. You can still search manually.');
      position=await Geolocator.getCurrentPosition();
    }catch(e){error=e.toString();}
  }

  Future<void> search() async{
    setState(()=>loading=true);
    try{
      await locate();
      var path='/search?q=${Uri.encodeQueryComponent(q.text)}&radiusKm=25';
      if(position!=null)path+='&lat=${position!.latitude}&lng=${position!.longitude}';
      final d=await ApiService.get(path);
      salons=(d['results'] as List).map((e)=>Salon.fromJson(e)).toList();
      error=null;
    }catch(e){error=e.toString();}
    finally{if(mounted)setState(()=>loading=false);}
  }

  @override void initState(){super.initState();loadUser();}

  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(
      title:const Text('Crowned Connections'),
      actions:[
        if(role=='SALON_OWNER')
          IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const OwnerDashboard())),icon:const Icon(Icons.storefront)),
        IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const AppointmentsScreen())),icon:const Icon(Icons.calendar_month))
      ],
    ),
    body:Column(children:[
      Padding(padding:const EdgeInsets.all(16),child:Column(children:[
        TextField(controller:q,onSubmitted:(_)=>search(),decoration:InputDecoration(
          hintText:'Search hairstyle or service',
          prefixIcon:const Icon(Icons.search),
          suffixIcon:IconButton(onPressed:search,icon:const Icon(Icons.arrow_forward))
        )),
        const SizedBox(height:8),
        Row(children:[
          const Icon(Icons.location_on_outlined), const SizedBox(width:4),
          Text(position==null?'Near my location':'Using current location'),
          const Spacer(),
          TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>MapScreen(salons:salons))),child:const Text('Map'))
        ])
      ])),
      if(error!=null)Padding(padding:const EdgeInsets.all(12),child:Text(error!,style:const TextStyle(color:Colors.red))),
      if(loading)const LinearProgressIndicator(),
      Expanded(child:salons.isEmpty&&!loading
        ?const Center(child:Text('Search for a hairstyle, e.g. “Knotless Braids”.'))
        :ListView.builder(itemCount:salons.length,itemBuilder:(c,i){
          final s=salons[i];
          return ListTile(
            leading:const CircleAvatar(child:Icon(Icons.content_cut)),
            title:Text(s.name),
            subtitle:Text('${s.city}, ${s.province}  •  ${s.distanceKm?.toStringAsFixed(1) ?? "—"} km  •  ★ ${s.rating.toStringAsFixed(1)}'),
            onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SalonScreen(salonId:s.id)))
          );
        }))
    ])
  );
}
