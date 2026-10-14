import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class SalonScreen extends StatefulWidget{
  final String salonId;
  const SalonScreen({super.key,required this.salonId});
  @override State<SalonScreen> createState()=>_SalonScreenState();
}
class _SalonScreenState extends State<SalonScreen>{
  Map<String,dynamic>? data; String? selectedService; String? selectedStylist; List<dynamic> slots=[]; bool loading=true;
  DateTime date=DateTime.now().add(const Duration(days:1));

  Future<void> load()async{
    try{data=await ApiService.get('/salons/${widget.salonId}');}catch(e){}
    if(mounted)setState(()=>loading=false);
  }
  Future<void> availability()async{
    if(selectedService==null)return;
    final d=await ApiService.get('/availability?salonId=${widget.salonId}&serviceId=$selectedService&date=${DateFormat('yyyy-MM-dd').format(date)}${selectedStylist==null?'':'&stylistId=$selectedStylist'}');
    setState(()=>slots=d['slots'] as List);
  }
  Future<void> book(Map slot)async{
    try{
      final r=await ApiService.post('/appointments',{
        'salonId':widget.salonId,'serviceId':selectedService,'stylistId':slot['stylistId'],'startTime':slot['startTime']
      });
      if(mounted)showDialog(context:context,builder:(_)=>AlertDialog(title:const Text('Booking requested'),content:Text('Status: ${r['appointment']['status']}. The salon owner must accept it.'),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('OK'))]));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(e.toString())));}
  }
  @override void initState(){super.initState();load();}
  @override Widget build(BuildContext context){
    if(loading)return const Scaffold(body:Center(child:CircularProgressIndicator()));
    final salon=data?['salon']; final services=data?['services'] as List? ?? []; final staff=data?['staff'] as List? ?? [];
    return Scaffold(appBar:AppBar(title:Text(salon?['name']??'Salon')),body:ListView(padding:const EdgeInsets.all(16),children:[
      Text(salon?['description']??'',style:Theme.of(context).textTheme.bodyLarge),
      Text('${salon?['city']}, ${salon?['province']}  •  ★ ${salon?['rating_avg']??0}'),
      const SizedBox(height:20),
      const Text('Choose a service',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),
      ...services.map((s)=>RadioListTile<String>(value:s['id'],groupValue:selectedService,title:Text(s['name']),subtitle:Text('R${(s['price_cents']/100).toStringAsFixed(2)} • ${s['duration_minutes']} min'),onChanged:(v){setState(()=>selectedService=v);availability();})),
      if(selectedService!=null)...[
        const Divider(),
        Row(children:[const Text('Stylist:'),const SizedBox(width:8),DropdownButton<String?>(
          value:selectedStylist,hint:const Text('Any available'),items:[const DropdownMenuItem<String?>(value:null,child:Text('Any available')),...staff.map<DropdownMenuItem<String?>>((s)=>DropdownMenuItem(value:s['id'],child:Text(s['display_name'])))],
          onChanged:(v){setState(()=>selectedStylist=v);availability();}
        )]),
        ListTile(title:const Text('Date'),subtitle:Text(DateFormat('EEE, d MMM yyyy').format(date)),trailing:IconButton(icon:const Icon(Icons.calendar_month),onPressed:()async{
          final picked=await showDatePicker(context:context,firstDate:DateTime.now(),lastDate:DateTime.now().add(const Duration(days:90)),initialDate:date);
          if(picked!=null){setState(()=>date=picked);availability();}
        })),
        const Text('Available times',style:TextStyle(fontWeight:FontWeight.bold)),
        if(slots.isEmpty)const Padding(padding:EdgeInsets.all(12),child:Text('No available slots for this date.')),
        ...slots.map((slot)=>ListTile(leading:const Icon(Icons.schedule),title:Text(DateFormat('HH:mm').format(DateTime.parse(slot['startTime']).toLocal())),subtitle:Text(slot['stylistName']),trailing:FilledButton(onPressed:()=>book(slot),child:const Text('Book'))))
      ]
    ]));
  }
}
