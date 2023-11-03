import 'dart:typed_data';

import 'package:bitcoin_base_i/src/models/network.dart';
import 'package:bitcoin_base_i/src/bitcoin/address/segwit_address.dart';
import 'package:bitcoin_base_i/src/bitcoin/constant/constant.dart';
import 'package:bitcoin_base_i/src/bitcoin/script/control_block.dart';
import 'package:bitcoin_base_i/src/bitcoin/script/input.dart';
import 'package:bitcoin_base_i/src/bitcoin/script/output.dart';
import 'package:bitcoin_base_i/src/bitcoin/script/script.dart';
import 'package:bitcoin_base_i/src/bitcoin/script/transaction.dart';
import 'package:bitcoin_base_i/src/bitcoin/script/witness.dart';
import 'package:bitcoin_base_i/src/crypto/ec/ec_private.dart';
import 'package:bitcoin_base_i/src/crypto/ec/ec_public.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/helper.dart';

void main() {
  group('TestCreateP2trWithSingleTapScript', () {
    late ECPrivate toPriv1;
    late ECPublic toPub1;
    late ECPrivate toPriv2;
    late ECPublic toPub2;
    late ECPrivate privkeyTrScript1;
    late ECPublic pubkeyTrScript1;
    late Script trScriptP2pk1;
    late String toTaprootScriptAddress1;
    late P2trAddress toAddress2;
    late ECPrivate fromPriv2;
    late ECPublic fromPub2;
    late P2trAddress fromAddress2;
    late TxInput txIn2;
    late TxOutput txOut2;
    late Script scriptPubKey2;
    late String signedTx2;
    late String signedTx3;

    setUp(() {
      toPriv1 = ECPrivate.fromWif(
          "cT33CWKwcV8afBs5NYzeSzeSoGETtAB8izjDjMEuGqyqPoF7fbQR");
      toPub1 = toPriv1.getPublic();
      toPriv2 = ECPrivate.fromWif(
          "cNxX8M7XU8VNa5ofd8yk1eiZxaxNrQQyb7xNpwAmsrzEhcVwtCjs");
      toPub2 = toPriv2.getPublic();
      toAddress2 = toPub2.toTaprootAddress();
      privkeyTrScript1 = ECPrivate.fromWif(
          "cSW2kQbqC9zkqagw8oTYKFTozKuZ214zd6CMTDs4V32cMfH3dgKa");
      pubkeyTrScript1 = privkeyTrScript1.getPublic();
      trScriptP2pk1 =
          Script(script: [pubkeyTrScript1.toXOnlyHex(), 'OP_CHECKSIG']);
      toTaprootScriptAddress1 =
          "tb1p0fcjs5l5xqdyvde5u7ut7sr0gzaxp4yya8mv06d2ygkeu82l65xs6k4uqr";
      fromPriv2 = ECPrivate.fromWif(
          "cT33CWKwcV8afBs5NYzeSzeSoGETtAB8izjDjMEuGqyqPoF7fbQR");
      fromPub2 = fromPriv2.getPublic();
      fromAddress2 = fromPub2.toTaprootAddress(scripts: [trScriptP2pk1]);
      txIn2 = TxInput(
          txId:
              "3d4c9d73c4c65772e645ff26493590ae4913d9c37125b72398222a553b73fa66",
          txIndex: 0);
      txOut2 = TxOutput(
          amount: priceToBtcUnit(0.00003),
          scriptPubKey: Script(script: toAddress2.toScriptPubKey()));
      scriptPubKey2 = Script(script: fromAddress2.toScriptPubKey());
      signedTx2 =
          "0200000000010166fa733b552a229823b72571c3d91349ae90354926ff45e67257c6c4739d4c3d0000000000ffffffff01b80b000000000000225120d4213cd57207f22a9e905302007b99b84491534729bd5f4065bdcb42ed10fcd50140f1776ddef90a87b646a45ad4821b8dd33e01c5036cbe071a2e1e609ae0c0963685cb8749001944dbe686662dd7c95178c85c4f59c685b646ab27e34df766b7b100000000";
      signedTx3 =
          "0200000000010166fa733b552a229823b72571c3d91349ae90354926ff45e67257c6c4739d4c3d0000000000ffffffff01b80b000000000000225120d4213cd57207f22a9e905302007b99b84491534729bd5f4065bdcb42ed10fcd50340bf0a391574b56651923abdb256731059008a08b5a3406cd81ce10ef5e7f936c6b9f7915ec1054e2a480e4552fa177aed868dc8b28c6263476871b21584690ef8222013f523102815e9fbbe132ffb8329b0fef5a9e4836d216dce1824633287b0abc6ac21c01036a7ed8d24eac9057e114f22342ebf20c16d37f0d25cfd2c900bf401ec09c900000000";
      // Initialize your variables here if needed
    });

    // 1-create address with single script spending path
    test('address_with_script_path', () {
      var toAddress = toPub1.toTaprootAddress(scripts: [trScriptP2pk1]);

      expect(toAddress.toAddress(NetworkInfo.TESTNET), toTaprootScriptAddress1);
    });

    // 2-spend taproot from key path (has single tapleaf script for spending)
    test('spend_key_path2', () {
      var tx =
          BtcTransaction(inputs: [txIn2], outputs: [txOut2], hasSegwit: true);

      const int signHash = TAPROOT_SIGHASH_ALL;
      final txDigit = tx.getTransactionTaprootDigset(
          txIndex: 0,
          scriptPubKeys: [scriptPubKey2],
          amounts: [BigInt.from(3500)],
          sighash: signHash);
      final signatur = fromPriv2.signTapRoot(txDigit,
          scripts: [trScriptP2pk1], sighash: signHash);
      tx.witnesses.add(TxWitnessInput(stack: [signatur]));
      expect(tx.serialize(), signedTx2);
    });

    // // 3-spend taproot from script path (has single tapleaf script for spending)
    test('spend_script_path2', () {
      var tx = BtcTransaction(
        outputs: [txOut2],
        inputs: [txIn2],
        hasSegwit: true,
      );
      final digit = tx.getTransactionTaprootDigset(
        amounts: [BigInt.from(3500)],
        scriptPubKeys: [scriptPubKey2],
        txIndex: 0,
        extFlags: 1,
        script: trScriptP2pk1,
      );
      final sig = privkeyTrScript1.signTapRoot(digit,
          scripts: [trScriptP2pk1], sighash: TAPROOT_SIGHASH_ALL, tweak: false);
      final controlBlock = ControlBlock(public: fromPub2);

      tx.witnesses.add(TxWitnessInput(
          stack: [sig, trScriptP2pk1.toHex(), controlBlock.toHex()]));
      expect(tx.serialize(), signedTx3);
    });
  });

  group('TestCreateP2trWithTwoTapScripts', () {
    late final ECPrivate privkeyTrScriptA = ECPrivate.fromWif(
        'cSW2kQbqC9zkqagw8oTYKFTozKuZ214zd6CMTDs4V32cMfH3dgKa');
    late final ECPublic pubkeyTrScriptA = privkeyTrScriptA.getPublic();
    late final trScriptP2pkA =
        Script(script: [pubkeyTrScriptA.toXOnlyHex(), 'OP_CHECKSIG']);

    late final ECPrivate privkeyTrScriptB = ECPrivate.fromWif(
        'cSv48xapaqy7fPs8VvoSnxNBNA2jpjcuURRqUENu3WVq6Eh4U3JU');
    late final ECPublic pubkeyTrScriptB = privkeyTrScriptB.getPublic();

    late final trScriptP2pkB =
        Script(script: [pubkeyTrScriptB.toXOnlyHex(), 'OP_CHECKSIG']);

    late final ECPrivate fromPriv = ECPrivate.fromWif(
        "cT33CWKwcV8afBs5NYzeSzeSoGETtAB8izjDjMEuGqyqPoF7fbQR");
    late final fromPub = fromPriv.getPublic();
    late final fromAddress =
        fromPub.toTaprootAddress(scripts: [trScriptP2pkA, trScriptP2pkB]);

    late final txIn = TxInput(
        txId:
            '808ec85db7b005f1292cea744b24e9d72ba4695e065e2d968ca17744b5c5c14d',
        txIndex: 0);

    late final ECPrivate toPriv = ECPrivate.fromWif(
        "cNxX8M7XU8VNa5ofd8yk1eiZxaxNrQQyb7xNpwAmsrzEhcVwtCjs");
    late final toPub = toPriv.getPublic();
    late final toAddress = toPub.toTaprootAddress();
    late final txOut = TxOutput(
        amount: priceToBtcUnit(0.00003),
        scriptPubKey: Script(script: toAddress.toScriptPubKey()));

    late final scriptPubkey = fromAddress.toScriptPubKey();
    late final allUtxosScriptpubkeys = [Script(script: scriptPubkey)];
    const String signedTx3 =
        "020000000001014dc1c5b54477a18c962d5e065e69a42bd7e9244b74ea2c29f105b0b75dc88e800000000000ffffffff01b80b000000000000225120d4213cd57207f22a9e905302007b99b84491534729bd5f4065bdcb42ed10fcd50340ab89d20fee5557e57b7cf85840721ef28d68e91fd162b2d520e553b71d604388ea7c4b2fcc4d946d5d3be3c12ef2d129ffb92594bc1f42cdaec8280d0c83ecc2222013f523102815e9fbbe132ffb8329b0fef5a9e4836d216dce1824633287b0abc6ac41c01036a7ed8d24eac9057e114f22342ebf20c16d37f0d25cfd2c900bf401ec09c9682f0e85d59cb20fd0e4503c035d609f127c786136f276d475e8321ec9e77e6c00000000";

    // 1-spend taproot from first script path (A) of two (A,B)
    test("test_spend_script_path_A_from_AB", () {
      final tx =
          BtcTransaction(inputs: [txIn], outputs: [txOut], hasSegwit: true);

      final txDigit = tx.getTransactionTaprootDigset(
          amounts: [BigInt.from(3500)],
          scriptPubKeys: allUtxosScriptpubkeys,
          txIndex: 0,
          script: trScriptP2pkA,
          extFlags: 1);

      final sign = privkeyTrScriptA.signTapRoot(
        txDigit,
        scripts: [trScriptP2pkA, trScriptP2pkB],
        tweak: false,
      );
      final leafB = trScriptP2pkB.toTapleafTaggedHash();

      final controlBlock = ControlBlock(public: fromPub, scripts: leafB);
      tx.witnesses.add(TxWitnessInput(
          stack: [sign, trScriptP2pkA.toHex(), controlBlock.toHex()]));
      expect(tx.serialize(), signedTx3);
    });
  });

  group("TestCreateP2trWithThreeTapScripts", () {
    // 1-spend taproot from key path (has three tapleaf script for spending)
    final privkeyTrScriptA = ECPrivate.fromWif(
        'cSW2kQbqC9zkqagw8oTYKFTozKuZ214zd6CMTDs4V32cMfH3dgKa');
    final pubkeyTrScriptA = privkeyTrScriptA.getPublic();
    final trScriptP2pkA =
        Script(script: [pubkeyTrScriptA.toXOnlyHex(), 'OP_CHECKSIG']);

    final privkeyTrScriptB = ECPrivate.fromWif(
        'cSv48xapaqy7fPs8VvoSnxNBNA2jpjcuURRqUENu3WVq6Eh4U3JU');
    final pubkeyTrScriptB = privkeyTrScriptB.getPublic();
    final trScriptP2pkB =
        Script(script: [pubkeyTrScriptB.toXOnlyHex(), 'OP_CHECKSIG']);

    final privkeyTrScriptC = ECPrivate.fromWif(
        'cRkZPNnn3jdr64o3PDxNHG68eowDfuCdcyL6nVL4n3czvunuvryC');
    final pubkeyTrScriptC = privkeyTrScriptC.getPublic();
    final trScriptP2pkC =
        Script(script: [pubkeyTrScriptC.toXOnlyHex(), 'OP_CHECKSIG']);

    final fromPriv = ECPrivate.fromWif(
        'cT33CWKwcV8afBs5NYzeSzeSoGETtAB8izjDjMEuGqyqPoF7fbQR');
    final fromPub = fromPriv.getPublic();
    final fromAddress = fromPub.toTaprootAddress(scripts: [
      [trScriptP2pkA, trScriptP2pkB],
      trScriptP2pkC
    ]);

    final txIn = TxInput(
        txId:
            '9b8a01d0f333b2440d4d305d26641e14e0e1932ebc3c4f04387c0820fada87d3',
        txIndex: 0);

    final toPriv = ECPrivate.fromWif(
        'cNxX8M7XU8VNa5ofd8yk1eiZxaxNrQQyb7xNpwAmsrzEhcVwtCjs');
    final toPub = toPriv.getPublic();
    final toAddress = toPub.toTaprootAddress();
    final txOut = TxOutput(
        amount: BigInt.from(3000),
        scriptPubKey: Script(script: toAddress.toScriptPubKey()));

    // final fromAmount = priceToBtcUnit(0.000035);
    final allAmounts = [BigInt.from(3500)];

    final scriptPubkey = fromAddress.toScriptPubKey();
    final allUtxosScriptPubkeys = [scriptPubkey];

    const String signedTx =
        '02000000000101d387dafa20087c38044f3cbc2e93e1e0141e64265d304d0d44b233f3d0018a9b0000000000ffffffff01b80b000000000000225120d4213cd57207f22a9e905302007b99b84491534729bd5f4065bdcb42ed10fcd50340644e392f5fd88d812bad30e73ff9900cdcf7f260ecbc862819542fd4683fa9879546613be4e2fc762203e45715df1a42c65497a63edce5f1dfe5caea5170273f2220e808f1396f12a253cf00efdf841e01c8376b616fb785c39595285c30f2817e71ac61c01036a7ed8d24eac9057e114f22342ebf20c16d37f0d25cfd2c900bf401ec09c9ed9f1b2b0090138e31e11a31c1aea790928b7ce89112a706e5caa703ff7e0ab928109f92c2781611bb5de791137cbd40a5482a4a23fd0ffe50ee4de9d5790dd100000000';

    test("test_spend_script_path_A_from_AB", () {
      final tx =
          BtcTransaction(inputs: [txIn], outputs: [txOut], hasSegwit: true);
      final digit = tx.getTransactionTaprootDigset(
          txIndex: 0,
          extFlags: 1,
          scriptPubKeys:
              allUtxosScriptPubkeys.map((e) => Script(script: e)).toList(),
          script: trScriptP2pkB,
          amounts: allAmounts.map((e) => e).toList());
      final sig = privkeyTrScriptB.signTapRoot(
        digit,
        scripts: [
          [trScriptP2pkA, trScriptP2pkB],
          trScriptP2pkC
        ],
        tweak: false,
      );

      final leafA = trScriptP2pkA.toTapleafTaggedHash();
      final leafC = trScriptP2pkC.toTapleafTaggedHash();
      final controlBlock = ControlBlock(
          public: fromPub, scripts: Uint8List.fromList([...leafA, ...leafC]));

      tx.witnesses.add(TxWitnessInput(
          stack: [sig, trScriptP2pkB.toHex(), controlBlock.toHex()]));

      expect(tx.serialize(), signedTx);
    });
  });
}
