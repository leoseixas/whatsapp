
import 'package:cloud_firestore/cloud_firestore.dart';

class Conversa{

  String _idRemetente;
  String _idDestinatario;
  String _nome;
  String _mensagem;
  String _caminhoFoto;
  String _tipoMensagem;


  Conversa();

  salvar()async{
    Firestore db = Firestore.instance;
    await db.collection("conversas")
    .document(this.idRemetente)
    .collection("ultima_conversa")
    .document(this.idDestinatario)
    .setData( this.toMap() );
  }

  Map<String, dynamic> toMap(){
    Map<String, dynamic> map = {
      "idRemetente"    : this._idRemetente,
      "idDestinatario" : this._idDestinatario,
      "nome"           : this._nome,
      "mensagem"       : this._mensagem,
      "caminhoFoto"    : this._caminhoFoto,
      "tipoMensagem"   : this._tipoMensagem,
    };
    return map;
  }

  String get nome => _nome;

  String get mensagem => _mensagem;

  String get caminhoFoto => _caminhoFoto;

  String get idRemetente => _idRemetente;

  String get idDestinatario => _idDestinatario;

  String get tipoMensagem => _tipoMensagem;

  set idRemetente(String value) {
    _idRemetente = value;
  }

  set nome(String value) {
    _nome = value;
  }

  set caminhoFoto(String value) {
    _caminhoFoto = value;
  }

  set mensagem(String value) {
    _mensagem = value;
  }

  set idDestinatario(String value) {
    _idDestinatario = value;
  }

  set tipoMensagem(String value) {
    _tipoMensagem = value;
  }
}