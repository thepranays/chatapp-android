import 'dart:convert';

import 'package:chatapp/widgets/MessageWidget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'login.dart';
import 'models/User.dart';
import 'models/message.dart';

String svIp = "18.183.103.128";
void main() {

  runApp(MyApp());


}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatV1',
      theme: ThemeData(


        primarySwatch: Colors.blue,
      ),
      home:MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();





}

class _MyHomePageState extends State<MyHomePage> {
  IO.Socket ?socket;
  final TextEditingController ?_myMessageController = TextEditingController();
  final TextEditingController ?_testSessionController = TextEditingController();
  List<Message> messagesList = [];
  List<User> usersList = [];
  static const _secureStorageInstance =  FlutterSecureStorage();
   bool isSession = false;
    bool isConnectedSocket =false;
   String? userId;
   String? token;
   String _sessionId="ChatV1";
   User user=  User(email: "404",name:"404",userId: "404",token: "404");


   Future<bool> _isLoggedIn() async {
     token = await _secureStorageInstance.read(key:"token");
     if(token==null){
       return false;
     }
     return true;
   }

  Future<User> _getUserDataFromDB() async{
      userId = await _secureStorageInstance.read(key: "userId");
      token = await _secureStorageInstance.read(key: "token");

      String url = "http://$svIp:3000/api/chatv1/data/find-user-by-id/";
      var res = await http.post(Uri.parse(url),headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization':'Bearer $token',
      },body:json.encode(<String,String?>{"userId":userId}));
      if(res.statusCode != 500){
        var decoded =  json.decode(res.body)["user"];
        print(decoded);
        setState(() {
          user =  User(email:decoded["email"],userId:decoded["id"] ,name:decoded["name"],token:token);
        });

      }

      return user;
  }
  Future<List<Message>> _getMessageOfCurrentSession () async {
      String url = "http://$svIp:3000/api/chatv1/data/session/messages/";
      var response = await http.post(Uri.parse(url),headers: {
        "Content-Type":"application/json; charset=UTF-8",
        "Authorization":"Bearer $token",

      },body:
        json.encode(<String,String?>{"sessionId":_sessionId}));
      // print(json.decode(response.body)["messagesList"]);

      List<Message> sessionMessages=[];
      print(response.statusCode);
      if(response.statusCode==404 || response.statusCode==502 || response.statusCode == 500){
        return sessionMessages;
      }

      json.decode(response.body)["messagesList"].forEach((val)=>{
          sessionMessages.add(Message(name:val["name"],email:val["email"]
          ,atTime:DateTime.parse(val["atTime"]),content:val["content"]))
      });
      print(sessionMessages);
      return sessionMessages;
  }
  Future<void> _getAllUsers () async {
    String url = "http://$svIp:3000/api/chatv1/data/users";
    var response = await http.get(Uri.parse(url),headers: {
      "Content-Type":"application/json; charset=UTF-8",
      "Authorization":"Bearer $token",

    },);
    print(json.decode(response.body));

    List<User> list=[];
    if(response.statusCode==404 || response.statusCode==502){
      return ;
    }
    //
    json.decode(response.body).forEach((val)=>{
      list.add(User(userId: val["_id"],email: val["email"],name:val["name"],token:""))
    });

    setState(() {
        usersList = list;
    });
  }


  void _sendMessageOnSocket(){
     // sessionName ??= "#general"; //if null then assign this
    String content =_myMessageController?.text as String;
    if(content == ""){
      return ;
    }

    Message message =  Message(name:user.name,content: content,atTime:DateTime.now(),email: user.email);
    socket!.emit("send-message",{"message":{
      "name":message.name,
      "content":message.content,
      "atTime":message.atTime.toString(),
      "email":message.email,
      "sessionId":_sessionId,

    },
      "isSession":true,
      "sessionId":_sessionId,
      "sender":user.name,

    });

    setState(() {
      _myMessageController?.clear();
      if(!isSession){
        messagesList.add(message);
      }
    });



  }

  void _joinSocketRoom(String sessionId){

     socket!.emit("join-session","#"+sessionId);
     print(sessionId);

     setState(() {
       isConnectedSocket = true;
       isSession = true;
       _sessionId = "#"+ sessionId;

     });

     _setSocketEvents();
    _getMessageOfCurrentSession().then((val)=>{
          setState(() {
          messagesList = val;

          })
    });

  }

  void _setSocketEvents(){
    socket!.on("new-message",(metaData){
        print(metaData);
        Map<String,dynamic> newMessage = metaData["payload"];
        print(newMessage);
        Message receivedMessage
        = Message(name: isSession ? newMessage["name"]:"", content:  newMessage["content"], atTime:DateTime.parse( newMessage["atTime"]), email: newMessage["email"]);
        setState(() {
          messagesList.add(receivedMessage);

        });


    });

  }
  void _connectSocket(){
     socket = IO.io('http://$svIp:3000',
         IO.OptionBuilder().setTransports(["websocket"]).disableAutoConnect().setQuery({"auth":user.token}).build()

    );


     socket!.connect();

     socket!.onConnectError((data) => print(data));
    socket!.onConnect((data) {
      print(socket!.id);

    });
     print(socket!.connected);

  }

  void _disconnectSocket(){
     socket!.emit("leave-session",_sessionId);
     setState(() {
       isConnectedSocket = false;
       isSession = false;
       _sessionId = "ChatV1";
       messagesList = [];
     });
  }

  @override
  void initState() {
      super.initState();
      print(":yo");
      _isLoggedIn().then((val)=>{
        if(!val){
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context)=>Login()))
      }else{
          _getUserDataFromDB().then((user){
             _connectSocket();
             _getAllUsers();

         })
    }});


  }

  Widget _homeWidget(){
    return Column(mainAxisAlignment: MainAxisAlignment.end,
        children:[

          Expanded(
            child: TextFormField(controller: _testSessionController,decoration: InputDecoration(
              hintText: "SessionId",
              suffix:IconButton(icon: const Icon(Icons.arrow_forward_outlined), onPressed: ()=>

                  _joinSocketRoom(_testSessionController!.text),

              ),


            ),),
          ),
        ],

    );
  }

  Widget _connectedSessionWidget(){
     return Column(mainAxisAlignment:MainAxisAlignment.end,
       children:[
         SizedBox(height: MediaQuery.of(context).size.height*0.85,
           child: SingleChildScrollView(reverse: true,
              child:  ListView.builder(itemCount: messagesList.length,
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(top: 10,bottom: 10),

                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index){
                      return MessageWidget(message: messagesList[index], type: messagesList[index].email == user.email ? "sender": "receiver");
                    }),
              ),
         ),


      Container(padding: const EdgeInsets.symmetric(horizontal: 6),height:  MediaQuery.of(context).size.height*0.06,
                child:TextFormField(controller: _myMessageController,decoration: InputDecoration(
                    hintText: 'type your message',
                    fillColor:const Color.fromARGB(200, 230, 242, 255),
                    filled: true,
                    suffix:IconButton(icon: const Icon(Icons.arrow_forward_outlined), onPressed: ()=>

                        _sendMessageOnSocket(),
                    ),


                  ),)),



        








       ],
     );
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(resizeToAvoidBottomInset: true,appBar: AppBar(title:  Text(_sessionId), backgroundColor: Colors.blue,
      actions: [
        IconButton(onPressed: ()=>{
            _disconnectSocket()
        }, icon:const Icon(Icons.power_settings_new))
      ],),
        body: isConnectedSocket ? SingleChildScrollView(child: _connectedSessionWidget()) : _homeWidget(),

        drawer:Drawer(
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children:
            [
               DrawerHeader(
                decoration:const BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(user.name),
              ),

              ...usersList.map((e) => ListTile(title:Text(e.name),onTap:(){
                  _disconnectSocket();
                  _joinSocketRoom(user.name);
                  setState(() {
                    isSession = false;
                  });
                  _sendMessageOnSocket();

              },)).toList()


            ],
          ),
        )
      );
  }


}
