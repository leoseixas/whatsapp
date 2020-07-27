import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp/model/Conversa.dart';
import 'package:whatsapp/model/Usuario.dart';

class AbaConversa extends StatefulWidget {
  @override
  _AbaConversaState createState() => _AbaConversaState();
}

class _AbaConversaState extends State<AbaConversa> {

  List<Conversa> _listaConversas = List();
  final _controller = StreamController<QuerySnapshot>.broadcast();
  Firestore db = Firestore.instance;

  String _idUser;


  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();

    Conversa conversa = Conversa();

    _listaConversas.add(conversa);
  }

  Stream<QuerySnapshot> _adicionarListenerConversas(){
    final stream = db.collection("conversas")
        .document(_idUser)
        .collection("ultima_conversa")
        .snapshots();

    stream.listen((dados){
      _controller.add( dados );
    });
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();
    _idUser = usuarioLogado.uid;

    _adicionarListenerConversas();

  }

  @override
  void dispose() {
    super.dispose();
    _controller.close();
  }
  @override
  Widget build(BuildContext context) {

    return StreamBuilder<QuerySnapshot>(
      stream: _controller.stream,
      // ignore: missing_return
      builder: (context, snapshot){
        switch(snapshot.connectionState){
          case ConnectionState.none:
          case ConnectionState.waiting:
          return Center(
            child: Column(
              children: <Widget>[
                Text("Carregando contatos"),
                CircularProgressIndicator()
              ],
            ),
          );
          case ConnectionState.active:
          case ConnectionState.done:
            if(snapshot.hasError){
              return Text("Error ao carregar os dados!");
            }else{

              QuerySnapshot querySnapshot = snapshot.data;

              if( querySnapshot.documents.length == 0 ){
                Center(
                  child: Text(
                      "Carregando contatos",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                );
              }
              return ListView.builder(
                  itemCount: _listaConversas.length,
                  itemBuilder: (context, indice){

                    List<DocumentSnapshot> conversas = querySnapshot.documents.toList();
                    DocumentSnapshot item = conversas[indice];

                    String urlImagem = item ["caminhoFoto"];
                    String tipo      = item ["tipo"];
                    String mensagem  = item ["mensagem"];
                    String nome      = item ["nome"];
                    String idDestinatario      = item ["idDestinatario"];

                    Usuario usuario = Usuario();

                    usuario.nome = nome;
                    usuario.urlImagem = urlImagem;
                    usuario.idUsuario =  idDestinatario;

                    return ListTile(
                      onTap: (){
                        Navigator.pushNamed(
                            context,
                            "/mensagens",
                            arguments: usuario
                        );
                      },
                      contentPadding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                      leading: CircleAvatar(
                        maxRadius: 30,
                        backgroundColor: Colors.grey,
                        backgroundImage: urlImagem!= null
                            ? NetworkImage(urlImagem)
                             : null
                      ),
                      title: Text(
                          nome,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                        ),
                      ),
                      subtitle: Text(
                      tipo == "texto"
                      ? mensagem
                          : "imagem...",
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14
                        ),
                      ),
                    );
                  }
              );
            }
        }
      },
    );


  }
}
