import 'package:flutter_test/flutter_test.dart';
import 'package:app_serveur_flutter/features/robot/domain/floor_model.dart';
import 'package:app_serveur_flutter/features/robot/domain/payment_status.dart';
import 'package:app_serveur_flutter/features/tasks/domain/task_model.dart';

RobotTask _task({PaymentStatus p = PaymentStatus.none, DeliveryStep s = DeliveryStep.pending}) =>
    RobotTask(
      id: 'T1',
      batchId: 'OP1',
      orderId: '#1',
      tableNumber: 'Table 4',
      floorId: 1,
      zoneKey: 'B',
      paymentStatus: p,
      currentStep: s,
      createdAt: DateTime(2026),
    );

void main() {
  group('Statuts de paiement : none / tpe_pending / tpe_paid', () {
    test('Codes backend', () {
      expect(PaymentStatus.none.code, 'none');
      expect(PaymentStatus.tpePending.code, 'tpe_pending');
      expect(PaymentStatus.tpePaid.code, 'tpe_paid');
      expect(PaymentStatus.fromCode('tpe_paid'), PaymentStatus.tpePaid);
      expect(PaymentStatus.fromCode('inconnu'), PaymentStatus.none);
      expect(PaymentStatus.fromCode(null), PaymentStatus.none);
    });

    test('TPE choisi -> le robot garde « TPE en attente »', () {
      expect(PaymentStatus.initial(withTpe: true), PaymentStatus.tpePending);
      expect(PaymentStatus.initial(withTpe: false), PaymentStatus.none);
    });

    test('Annonce du robot après paiement', () {
      expect(PaymentStatus.paidAnnouncement, "C'est bon, paiement validé");
    });

    test('Compatibilité : ancien champ needsTpe -> tpe_pending', () {
      final slot = ZoneSlot.fromJson({'zoneKey': 'A', 'orderId': '#1', 'needsTpe': true}, 'A');
      expect(slot.paymentStatus, PaymentStatus.tpePending);
      expect(slot.needsTpe, isTrue);
    });

    test('Le statut de paiement survit à un aller-retour JSON', () {
      final t = _task(p: PaymentStatus.tpePaid, s: DeliveryStep.delivered);
      final back = RobotTask.fromJson(t.toJson());
      expect(back.paymentStatus, PaymentStatus.tpePaid);
      expect(back.toJson()['paymentStatus'], 'tpe_paid');
    });
  });

  group('Fin de livraison avec TPE', () {
    test('Arrivée sans TPE = livraison terminée', () {
      final t = _task(s: DeliveryStep.delivered);
      expect(t.isAwaitingTpe, isFalse);
      expect(t.isFinished, isTrue);
    });

    test('Arrivée avec TPE en attente = pas encore terminée (aucune alerte)', () {
      final t = _task(p: PaymentStatus.tpePending, s: DeliveryStep.delivered);
      expect(t.isAwaitingTpe, isTrue);
      expect(t.isFinished, isFalse);
    });

    test('Après « J\'ai terminé » : Payé = terminée', () {
      final t = _task(p: PaymentStatus.tpePaid, s: DeliveryStep.delivered);
      expect(t.isFinished, isTrue);
    });

    test('Une opération est terminée quand toutes ses livraisons le sont', () {
      final a = _task(s: DeliveryStep.delivered);
      final b = RobotTask.fromJson({
        ..._task(p: PaymentStatus.tpePending, s: DeliveryStep.delivered).toJson(),
        'id': 'T2',
        'stopIndex': 1,
      });
      final batch = DeliveryBatch(id: 'OP1', tasks: [b, a]);
      expect(batch.tasks.first.id, 'T1'); // trié par ordre de passage
      expect(batch.isFinished, isFalse);
      expect(batch.currentStop!.id, 'T2');
      expect(batch.finishedCount, 1);
    });
  });
}
