import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whatsapp/model/Conversa.dart';
import 'package:whatsapp/model/Mensagem.dart';
import 'package:whatsapp/model/Usuario.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class Mensagens extends StatefulWidget {
  Usuario contato;

  Mensagens(this.contato);

  @override
  _MensagensState createState() => _MensagensState();
}

class _MensagensState extends State<Mensagens> {
  Firestore db = Firestore.instance;
  File _imagem;
  bool _subindoImagem = false;
  String _idUser;
  String _idUserDestinatario;
  TextEditingController _controllerMensagem = TextEditingController();

  final _controller = StreamController<QuerySnapshot>.broadcast();
  ScrollController _scrollController = ScrollController();

  _enviarMensagemTexo() async {
    String textoMensagem = _controllerMensagem.text;
    if (textoMensagem.isNotEmpty) {
      Mensagem mensagem = Mensagem();
      mensagem.idUsuario = _idUser;
      mensagem.mensagem = textoMensagem;
      mensagem.urlImagem = "";
      mensagem.data = Timestamp.now().toString();
      mensagem.tipo = "text";

      //salvar mensagem para remetente
      _salvarMensagem(_idUser, _idUserDestinatario, mensagem);

      //salvar mensagem para destinatario
      _salvarMensagem(_idUserDestinatario, _idUser, mensagem);

      //Salvar conversa
      _salvarConversa(mensagem);

    }
  }

  _salvarConversa(Mensagem msg){

    //salvar conversa para remetente
    Conversa cRemetente = Conversa();
    cRemetente.idRemetente = _idUser;
    cRemetente.idDestinatario= _idUserDestinatario;
    cRemetente.mensagem = msg.mensagem;
    cRemetente.nome = widget.contato.nome;
    cRemetente.caminhoFoto = widget.contato.urlImagem;
    cRemetente.tipoMensagem = msg.tipo;
    cRemetente.salvar();

    //salvar conversa para destinatario
    Conversa cDestinatario = Conversa();
    cDestinatario.idRemetente = _idUserDestinatario;
    cDestinatario.idDestinatario= _idUser ;
    cDestinatario.mensagem = msg.mensagem;
    cDestinatario.nome = widget.contato.nome;
    cDestinatario.caminhoFoto = widget.contato.urlImagem;
    cDestinatario.tipoMensagem = msg.tipo;
    cDestinatario.salvar();
  }

  _salvarMensagem(
      String idRemetente, String idDestinatario, Mensagem msg) async {
    await db
        .collection("mensagens")
        .document(idRemetente)
        .collection(idDestinatario)
        .add(msg.toMap());

    _controllerMensagem.clear();
  }

  _enviarFoto() async {
    File imagemSelecionada;
    imagemSelecionada = await ImagePicker.pickImage(source: ImageSource.gallery);

    _subindoImagem = true;

      String nomeImagem = DateTime.now().millisecondsSinceEpoch.toString();
      FirebaseStorage storage = FirebaseStorage.instance;
      StorageReference pastaRaiz = storage.ref();
      StorageReference arquivo = pastaRaiz
          .child("mensagens")
          .child(_idUser)
          .child( nomeImagem +".jpg");

      StorageUploadTask task = arquivo.putFile(imagemSelecionada);

      task.events.listen((StorageTaskEvent storageEvent){
        if( storageEvent.type == StorageTaskEventType.progress ){
          setState(() {
            _subindoImagem = true;
          });
        }else if( storageEvent.type == StorageTaskEventType.success ){
          _subindoImagem = false;

        }
      });

      task.onComplete.then((StorageTaskSnapshot snapshot){
        _recuperarUrlImagem(snapshot);
      });

  }

  Future _recuperarUrlImagem(StorageTaskSnapshot snapshot)async{
    String url = await snapshot.ref.getDownloadURL();

    Mensagem mensagem = Mensagem();
    mensagem.idUsuario = _idUser;
    mensagem.mensagem = "";
    mensagem.urlImagem = url;
    mensagem.data = Timestamp.now().toString();
    mensagem.tipo = "imagem";

    _salvarMensagem(_idUser, _idUserDestinatario, mensagem);

    //salvar mensagem para destinatario
    _salvarMensagem(_idUserDestinatario, _idUser, mensagem);
  }

  _recuperarDadosUsuario() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseUser usuarioLogado = await auth.currentUser();
    _idUser = usuarioLogado.uid;

    _idUserDestinatario = widget.contato.idUsuario;

    _adicionarListenerConversas();
  }

  Stream<QuerySnapshot> _adicionarListenerConversas(){
    final stream = db
        .collection("mensagens")
        .document(_idUser)
        .collection(_idUserDestinatario)
        .orderBy("data", descending: false )
        .snapshots();

    stream.listen((dados){
      _controller.add( dados );
      Timer(Duration(seconds: 1), (){
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _recuperarDadosUsuario();
  }

  @override
  Widget build(BuildContext context) {

    var caixaMensagem = Container(
      padding: EdgeInsets.all(8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: TextField(
                controller: _controllerMensagem,
                autofocus: true,
                keyboardType: TextInputType.text,
                style: TextStyle(fontSize: 20),
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.fromLTRB(32, 8, 32, 8),
                    hintText: "Digite uma mensagem",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    prefixIcon:
                    _subindoImagem
                        ? CircularProgressIndicator()
                        : IconButton(icon: Icon(Icons.camera_alt),onPressed: _enviarFoto)
                ),
              ),
            ),
          ),
          FloatingActionButton(
              backgroundColor: Color(0xff075E54),
              child: Icon(Icons.send, color: Colors.white),
              mini: true,
              onPressed: _enviarMensagemTexo)
        ],
      ),
    );

    var stream = StreamBuilder(
        stream: _controller.stream,
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
              QuerySnapshot querySnapshot = snapshot.data;

              if (snapshot.hasError) {
                  child: Text("Erro ao carregar os dados!");
              } else {
                return Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: querySnapshot.documents.length,
                      itemBuilder: (context, indice) {

                        //recuperar mensagem
                        List<DocumentSnapshot> mensagens = querySnapshot.documents.toList();
                        DocumentSnapshot item = mensagens[indice];
                        double larguraContainer =
                            MediaQuery.of(context).size.width * 0.8;

                        Alignment alinhamento = Alignment.centerRight;
                        Color cor = Color(0xffd2ffa5);

                        if (_idUser != item["idUsuario"]) {
                          alinhamento = Alignment.centerLeft;
                          cor = Colors.white;
                    }
                      return Align(
                        alignment: alinhamento,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Container(
                            width: larguraContainer,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: cor,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(8))),
                            child:
                            item["tipo"] == "text"
                              ? Text(item["mensagem"],style: TextStyle(fontSize: 18),)
                              : Image.network(item["urlImagem"]),
                          ),
                        ),
                      );
                  },
                ));
              }
              break;
          }
        });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            CircleAvatar(
                maxRadius: 20,
                backgroundColor: Colors.grey,
                backgroundImage: widget.contato.urlImagem != null
                    ? NetworkImage(widget.contato.urlImagem)
                    : null),
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(widget.contato.nome),
            )
          ],
        ),
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            image: DecorationImage(
                image: AssetImage("imagens/bg.png"), fit: BoxFit.cover)),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                stream,
                caixaMensagem,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
