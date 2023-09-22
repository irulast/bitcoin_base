import 'dart:typed_data';
import 'package:bitcoin_base/src/models/network.dart';
import 'package:bitcoin_base/src/bitcoin/address/address.dart';
import 'package:bitcoin_base/src/bitcoin/constant/constant.dart';
import 'package:bitcoin_base/src/bitcoin/script/input.dart';
import 'package:bitcoin_base/src/bitcoin/script/output.dart';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/bitcoin/script/transaction.dart';
import 'package:bitcoin_base/src/crypto/ec/ec_public.dart';
import 'package:tuple/tuple.dart';

import './utxo.dart';

Tuple2<String, String> spendP2shToP2pk({
  required P2pkAddress receiver,
  required ECPublic senderPub,
  required NetworkInfo networkType,
  required String Function(Uint8List, {int sigHash}) sign,
  required List<UTXO> utxo,
  BigInt? value,
  required BigInt estimateFee,
  int? trSize,
  int sighash = SIGHASH_ALL,
}) {
  int someBytes = 100 + (utxo.length * 100);

  final fee = BigInt.from((trSize ?? someBytes)) * estimateFee;
  final BigInt sumUtxo = utxo.fold(
      BigInt.zero, (previousValue, element) => previousValue + element.value);
  BigInt mustSend = value ?? sumUtxo;
  if (value == null) {
    mustSend = sumUtxo - fee;
  } else {
    BigInt currentValue = value + fee;
    if (trSize != null && sumUtxo < currentValue) {
      throw Exception(
          "need money balance $sumUtxo value + fee = $currentValue");
    }
  }
  if (mustSend.isNegative) {
    throw Exception(
        "your balance must >= transaction ${value ?? sumUtxo} + $fee");
  }
  BigInt needChangeTx = sumUtxo - (mustSend + fee);
  final txin = utxo.map((e) => TxInput(txId: e.txId, txIndex: e.vout)).toList();
  final List<TxOutput> txOut = [
    TxOutput(
        amount: mustSend,
        scriptPubKey: Script(script: receiver.toScriptPubKey()))
  ];
  if (needChangeTx > BigInt.zero) {
    txOut.add(TxOutput(
        amount: needChangeTx,
        scriptPubKey: senderPub.toRedeemScript().toP2shScriptPubKey()));
  }
  final tx = BtcTransaction(inputs: txin, outputs: txOut, hasSegwit: false);
  for (int i = 0; i < txin.length; i++) {
    final txDigit = tx.getTransactionDigest(
        txInIndex: i, script: senderPub.toRedeemScript(), sighash: sighash);
    final signedTx = sign(txDigit, sigHash: sighash);
    txin[i].scriptSig =
        Script(script: [signedTx, senderPub.toRedeemScript().toHex()]);
  }

  if (trSize == null) {
    return spendP2shToP2pk(
        estimateFee: estimateFee,
        networkType: networkType,
        receiver: receiver,
        senderPub: senderPub,
        sign: sign,
        utxo: utxo,
        value: value,
        sighash: sighash,
        trSize: tx.getVSize());
  }
  return Tuple2(tx.serialize(), tx.txId());
}
