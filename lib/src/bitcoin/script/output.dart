import 'dart:typed_data';
import 'package:bitcoin_base/src/bitcoin/script/script.dart';
import 'package:bitcoin_base/src/formating/bytes_num_formating.dart';
import 'package:tuple/tuple.dart';

/// Represents a transaction output.
///
/// [amount] the value we want to send to this output in satoshis
/// [scriptPubKey] the script that will lock this amount
class TxOutput {
  TxOutput({required this.amount, required this.scriptPubKey});
  final BigInt amount;
  final Script scriptPubKey;

  ///  creates a copy of the object
  TxOutput copy() {
    return TxOutput(amount: amount, scriptPubKey: scriptPubKey);
  }

  /// serializes TxInput to bytes
  Uint8List toBytes() {
    final amountBytes = packBigIntToLittleEndian(amount);
    Uint8List scriptBytes = scriptPubKey.toBytes();
    final data = Uint8List.fromList(
        [...amountBytes, ...encodeVarint(scriptBytes.length), ...scriptBytes]);
    return data;
  }

  static Tuple2<TxOutput, int> fromRaw(
      {required String raw, required int cursor, bool hasSegwit = false}) {
    final txoutputraw = hexToBytes(raw);
    int value = ByteData.sublistView(txoutputraw, cursor, cursor + 8)
        .getInt64(0, Endian.little);
    cursor += 8;

    final vi = viToInt(txoutputraw.sublist(cursor, cursor + 9));
    cursor += vi.item2;
    Uint8List lockScript = txoutputraw.sublist(cursor, cursor + vi.item1);
    cursor += vi.item1;
    return Tuple2(
      TxOutput(
          amount: BigInt.from(value),
          scriptPubKey: Script.fromRaw(
              hexData: bytesToHex(lockScript), hasSegwit: hasSegwit)),
      cursor
    );
  }
}
