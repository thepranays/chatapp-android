import 'dart:convert';

import 'package:chatapp/main.dart';
import 'package:chatapp/signup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

String svIp = "18.183.103.128";
class Login extends StatelessWidget{
  final TextEditingController _emailTextController = TextEditingController();
  final TextEditingController _passTextController = TextEditingController();
  var _isLoggedIn = false;
  static const _secureStorageInstance =  FlutterSecureStorage();

  Future<Map<String,String>> _loginRequest() async{
      String loginApiEndpoint = "http://$svIp:3000/api/chatv1/login";
      var response = await http.post(Uri.parse(loginApiEndpoint),headers:<String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },body: jsonEncode(<String,String>
      {"email":_emailTextController.text,"password":_passTextController.text}));

      print(json.decode(response.body));
      if(response.statusCode != 404 || response.statusCode != 500){
            _isLoggedIn = true;
      }
      Map<String,String> resBody = {"token":json.decode(response.body)["token"],"userId":json.decode(response.body)["userId"]};
      return resBody;


  }

  Future<String?> _saveTokenSecurely(Map<dynamic,dynamic> _sensiData) async{
    await _secureStorageInstance.write(key: "token", value: _sensiData["token"]);
    await _secureStorageInstance.write(key:"userId",value: _sensiData["userId"]);
    return await _secureStorageInstance.read(key:"userId"); //as i have to wait till data is saved in secure storage

  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(appBar: AppBar(title:const Text("Login"),backgroundColor: Colors.blue,),body:
      SingleChildScrollView(child: Column(children: [
        TextFormField(decoration:const InputDecoration(hintText: "Email"),controller: _emailTextController,),
        TextFormField(decoration:const InputDecoration(hintText: "Password"),controller: _passTextController,),
        Center(child:ElevatedButton(child:Icon(Icons.transit_enterexit),onPressed: (){
            _loginRequest().then((value) {
              if(_isLoggedIn){
               _saveTokenSecurely({"token": value["token"], "userId": value["userId"]}).then((_){
                 Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) =>  MyHomePage()));
               });//title:"Chat", token:value['token'], userId:value['userId']))

              }
            });
        },),),
        TextButton(onPressed: (){
          Navigator.of(context).push(MaterialPageRoute(builder: (context)=> SignUp()));
        }, child: const Text("Don't have account? Sign-up!")),

      ],),)


      );
  }
}