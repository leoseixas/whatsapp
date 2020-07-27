import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:whatsapp/model/Conversa.dart';
import 'package:whatsapp/model/Usuario.dart';

class AbaContato extends StatefulWidget {
  @override
  _AbaContatoState createState() => _AbaContatoState();
}

class _AbaContatoState extends State<AbaContato> {

  String _idUser;
  String _emailUser;

  _recuperarDadosUsuario()async{
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();
    _idUser = usuarioLogado.uid;
    _emailUser = usuarioLogado.email;

  }



  Future<List<Usuario>> _recuperarContato() async {
    Firestore db = Firestore.instance;
    QuerySnapshot querySnapshot =
        await db.collection("usuarios").getDocuments();

    List<Usuario> listaUsuario = List();
    for (DocumentSnapshot item in querySnapshot.documents) {
      var dados = item.data;
      if(dados["email"] == _emailUser) continue;

      Usuario usuario = Usuario();
      usuario.idUsuario = item.documentID;
      usuario.email = dados["email"];
      usuario.nome = dados["nome"];
      usuario.urlImagem = dados["urlImagem"];

      listaUsuario.add(usuario);
    }
    return listaUsuario;
  }


  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Usuario>>(
      future: _recuperarContato(),
      // ignore: missing_return
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
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
            break;
          case ConnectionState.active:
          case ConnectionState.done:
            return ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (_, indice) {
                  List<Usuario> listaItens = snapshot.data;
                  Usuario usuario = listaItens[indice];

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
                        backgroundImage: usuario.urlImagem != null
                            ? NetworkImage(usuario.urlImagem)
                            : null),
                    title: Text(
                      usuario.nome,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  );
                });
        }
      },
    );
  }
}
