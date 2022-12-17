
class Message {
  final String name;
  final String content;
  final DateTime atTime;
  final String email;

  Message({required this.name,required this.content,required this.atTime,required this.email});


  factory Message.fromJson(Map<String,dynamic> data){
      return Message(name:data["name"],content:data["content"],atTime:data["atTime"],email: data["email"]);

  }
}