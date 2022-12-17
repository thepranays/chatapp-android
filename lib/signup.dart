import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'main.dart';
String svIp = "18.183.103.128";

class SignUp extends StatelessWidget {
  final TextEditingController _emailTextController =  TextEditingController();
  final TextEditingController _passTextController =  TextEditingController();
  final TextEditingController _nameTextController =  TextEditingController();
  var _isLoggedIn = false;
  static const _secureStorageInstance =  FlutterSecureStorage();



  Future<Map<String,String>> _signupRequest() async{
    String loginApiEndpoint = "http://$svIp:3000/api/chatv1/sign-up";
    var response = await http.post(Uri.parse(loginApiEndpoint),headers:<String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },body: jsonEncode(<String,String>
    {"email":_emailTextController.text,"password":_passTextController.text,"name":_nameTextController.text}));

    print(json.decode(response.body));
    if(response.statusCode != 404 || response.statusCode != 500){
      _isLoggedIn= true;
    }
    Map<String,String> resBody = {"token":json.decode(response.body)["token"],"userId":json.decode(response.body)["userId"]};
    return resBody;


  }

  void _saveTokenSecurely(Map<dynamic,dynamic> _sensiData) async{
    await _secureStorageInstance.write(key: "token", value: _sensiData["token"]);
    await _secureStorageInstance.write(key:"userId",value: _sensiData["userId"]);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title:const Text("Sign-up"),backgroundColor: Colors.blue,),body:
    SingleChildScrollView(child: Column(children: [
      TextFormField(decoration:const InputDecoration(hintText: "Email"),controller: _emailTextController,),
      TextFormField(decoration:const InputDecoration(hintText: "Password"),controller: _passTextController,),
      TextFormField(decoration: const InputDecoration(hintText: "Name"),controller:_nameTextController,),
      Center(child:ElevatedButton(child:const Icon(Icons.transit_enterexit),onPressed: (){
        _signupRequest().then((value){
          if(_isLoggedIn){
            _saveTokenSecurely({"token": value["token"], "userId": value["userId"]});
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) =>  MyHomePage()));
          }
        });
      },),)
    ],),)


    );
  }
}
