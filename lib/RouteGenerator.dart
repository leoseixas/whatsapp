import 'package:flutter/material.dart';
import 'package:whatsapp/Cadastro.dart';
import 'package:whatsapp/Configuracoes.dart';
import 'package:whatsapp/Home.dart';
import 'package:whatsapp/Mensagens.dart';

import 'Login.dart';

class RouteGenerator{

  static Route<dynamic> generateRoute(RouteSettings settings){

    final args = settings.arguments;

    switch(settings.name){
      case "/":
        return MaterialPageRoute(
            builder: (_)=> Login()
        );
//        break;
      case "/login":
        return MaterialPageRoute(
            builder: (_)=> Login()
        );
//        break;
      case "/cadastro":
        return MaterialPageRoute(
            builder: (_)=> Cadastro()
        );
//        break;
      case "/home":
        return MaterialPageRoute(
            builder: (_)=> Home()
        );
//        break;
      case "/configuracoes":
        return MaterialPageRoute(
            builder: (_)=> Configuracoes()
        );
      case "/mensagens":
        return MaterialPageRoute(
            builder: (_)=> Mensagens(args)
        );
      default:
        _erroRota();

    }
  }

  static Route<dynamic> _erroRota(){
    return MaterialPageRoute(
        builder: (_){
          return Scaffold(
            appBar: AppBar(
              title: Text("Tela nao encontrada"),
            ),
            body: Center(
              child: Text("Tela nao encontrada"),
            ),
          );
        }
    );
  }
}
