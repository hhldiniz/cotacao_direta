import 'dart:io';

import 'package:cotacao_direta/util/background_alert_check.dart';
import 'package:cotacao_direta/util/notification_service.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

/// Identifica a tarefa dentro do app; trocar este nome faz o WorkManager
/// tratar o agendamento como outro, deixando o anterior para trás.
const _uniqueName = "cotacao-direta-currency-alerts";

/// Nome que chega ao [Workmanager.executeTask]. Há uma tarefa só, mas ele é o
/// que permitiria distinguir outras no futuro.
const _taskName = "currencyAlertsCheck";

/// De quanto em quanto tempo o sistema acorda o app.
///
/// Uma hora acompanha a validade da cotação salva (ver `CurrencyRepository`):
/// acordar com mais frequência releria o mesmo valor do banco, sem consultar a
/// API, e só gastaria bateria. O WorkManager trata isto como um alvo, não uma
/// promessa — ele agrupa as execuções e respeita o modo economia.
const _frequency = Duration(hours: 1);

/// Ponto de entrada da tarefa, chamado pelo sistema num isolate novo.
///
/// A anotação impede que a compilação AOT descarte a função: nada no código do
/// app a chama, só o plugin, pelo nome.
@pragma('vm:entry-point')
void backgroundAlertCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    // Isolate novo: nada do que o main() preparou existe aqui, então os canais
    // de plataforma e as notificações precisam ser inicializados de novo.
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService().initialize();
    await runBackgroundAlertCheck();
    return true;
  });
}

/// Agenda a checagem periódica no Android.
///
/// Fora do Android é um no-op: no Linux Desktop o app não fica em segundo
/// plano, e chamar o plugin lá levantaria exceção por falta de implementação.
Future<void> startPlatformBackgroundAlertChecks() async {
  if (!Platform.isAndroid) return;
  await Workmanager().initialize(backgroundAlertCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _uniqueName,
    _taskName,
    frequency: _frequency,
    // Sem rede não há cotação nova para comparar; deixar o sistema escolher a
    // hora evita acordar o app para não fazer nada.
    constraints: Constraints(networkType: NetworkType.connected),
    // `update` mantém o agendamento que já existe em vez de recriá-lo a cada
    // abertura do app — recriar reiniciaria a contagem, e um app aberto com
    // frequência nunca chegaria a rodar a tarefa.
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}
