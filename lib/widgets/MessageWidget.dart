import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';
import 'package:intl/date_time_patterns.dart';

class MessageWidget extends StatelessWidget{
  Message message;
  String type;

  MessageWidget({required this.message,required this.type});


  @override
  Widget build(BuildContext context) {
     return Column(
       children: [
         Align(alignment: (type == "receiver"?Alignment.topLeft:Alignment.topRight),child: Text(message.name)),
         Container(
          padding: const EdgeInsets.only(left: 14,right: 14,top: 5,bottom: 5),
          child: Align(
            alignment: (type == "receiver"?Alignment.topLeft:Alignment.topRight),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (type  == "receiver"?Colors.grey.shade200:Colors.blue[200]),
              ),
              padding: const EdgeInsets.all(16),
              child: Text(message.content, style: const TextStyle(fontSize: 15),),
            ),
          ),
    ),
         Align(alignment: (type == "receiver"?Alignment.topLeft:Alignment.topRight),child: Text(DateFormat.yMd().add_jm().format(message.atTime))),
      const SizedBox(height: 30,)
       ],
     );
  }
}