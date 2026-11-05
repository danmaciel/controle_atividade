import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database/database_helper.dart';
import '../models/atividade.dart';
import '../models/dia_atividade.dart';

enum FiltroStatusLancamento { todas, lancadas, pendentes }

class AtividadeProvider extends ChangeNotifier {
  final DatabaseHelper _dbHelper;
  final Database? dbOverride;

  List<DiaAtividade> _dias = [];
  bool _carregando = false;
  String _termoBusca = '';
  FiltroStatusLancamento _filtroStatus = FiltroStatusLancamento.todas;
  String? _erro;

  AtividadeProvider({
    DatabaseHelper? dbHelper,
    this.dbOverride,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  bool get carregando => _carregando;
  String get termoBusca => _termoBusca;
  FiltroStatusLancamento get filtroStatus => _filtroStatus;
  String? get erro => _erro;

  List<DiaAtividade> get todosDias => List.unmodifiable(_dias);

  /// Lista de dias filtrada pela busca e pelo filtro de status (Todas / Lançadas / Pendentes)
  List<DiaAtividade> get diasFiltrados {
    final busca = _termoBusca.trim().toLowerCase();

    return _dias
        .map((dia) {
          final atividadesFiltradas = dia.atividades.where((ativ) {
            final bateStatus = switch (_filtroStatus) {
              FiltroStatusLancamento.todas => true,
              FiltroStatusLancamento.lancadas => ativ.lancada,
              FiltroStatusLancamento.pendentes => !ativ.lancada,
            };

            if (!bateStatus) return false;

            if (busca.isEmpty) return true;

            final bateNome = ativ.nome.toLowerCase().contains(busca);
            final bateData = dia.dataFormatada.toLowerCase().contains(busca) ||
                dia.data.toLowerCase().contains(busca) ||
                dia.diaDaSemana.toLowerCase().contains(busca) ||
                (dia.observacao?.toLowerCase().contains(busca) ?? false);

            return bateNome || bateData;
          }).toList();

          final diaBateBuscaDireta = busca.isEmpty ||
              dia.dataFormatada.toLowerCase().contains(busca) ||
              dia.data.toLowerCase().contains(busca) ||
              dia.diaDaSemana.toLowerCase().contains(busca) ||
              (dia.observacao?.toLowerCase().contains(busca) ?? false);

          // Se o card do dia está vazio mas bate na busca (e filtro é todas), mantém o card visível
          if (dia.atividades.isEmpty &&
              diaBateBuscaDireta &&
              _filtroStatus == FiltroStatusLancamento.todas) {
            return dia;
          }

          if (atividadesFiltradas.isEmpty) return null;
          return dia.copyWith(atividades: atividadesFiltradas);
        })
        .whereType<DiaAtividade>()
        .toList();
  }

  /// Soma geral de minutos de todos os dias filtrados
  int get totalMinutosGeral =>
      diasFiltrados.fold(0, (soma, d) => soma + d.totalMinutos);

  /// Soma de minutos pendentes de lançamento (amarelos)
  int get totalMinutosPendentes => _dias
      .expand((d) => d.atividades)
      .where((a) => !a.lancada)
      .fold(0, (soma, a) => soma + a.duracaoMinutos);

  /// Soma de minutos já lançados (verdes)
  int get totalMinutosLancados => _dias
      .expand((d) => d.atividades)
      .where((a) => a.lancada)
      .fold(0, (soma, a) => soma + a.duracaoMinutos);

  void atualizarBusca(String termo) {
    _termoBusca = termo;
    notifyListeners();
  }

  void atualizarFiltroStatus(FiltroStatusLancamento novoFiltro) {
    _filtroStatus = novoFiltro;
    notifyListeners();
  }

  Future<void> carregarDados() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _dias = await _dbHelper.listarDiasComAtividades(dbOverride: dbOverride);
    } catch (e) {
      _erro = 'Erro ao carregar atividades: $e';
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Cria ou retorna um Card de Dia para a data informada (YYYY-MM-DD)
  Future<DiaAtividade> criarDia(String data, {String? observacao}) async {
    final dia = await _dbHelper.obterOuCriarDia(
      data,
      observacao: observacao,
      dbOverride: dbOverride,
    );
    await carregarDados();
    return dia;
  }

  /// Edita a data ou observação de um Card de Dia
  Future<void> editarDia(DiaAtividade dia) async {
    await _dbHelper.atualizarDia(dia, dbOverride: dbOverride);
    await carregarDados();
  }

  /// Remove o Card do Dia inteiro (e todas as suas atividades)
  Future<void> removerDia(int diaId) async {
    await _dbHelper.removerDia(diaId, dbOverride: dbOverride);
    await carregarDados();
  }

  /// Insere uma atividade em um dia existente
  Future<void> adicionarAtividade(Atividade atividade) async {
    await _dbHelper.inserirAtividade(atividade, dbOverride: dbOverride);
    await carregarDados();
  }

  /// Inicia uma nova atividade agora (Play) no dia informado (ou no dia de hoje)
  Future<void> iniciarAtividadeAgora({
    required int diaId,
    required String nome,
  }) async {
    final agora = DateTime.now();
    final horaAtual =
        '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';

    final nova = Atividade(
      diaId: diaId,
      nome: nome.trim(),
      horaInicio: horaAtual,
      horaFim: null,
      lancada: false,
    );

    await _dbHelper.inserirAtividade(nova, dbOverride: dbOverride);
    await carregarDados();
  }

  /// Finaliza uma atividade em andamento (Stop), preenchendo hora_fim com o horário atual e calculando os minutos
  Future<void> finalizarAtividadeAgora(
    Atividade atividade, {
    String? horaFimManual,
  }) async {
    final agora = DateTime.now();
    final horaFim = horaFimManual ??
        '${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}';

    final atualizada = atividade.copyWith(horaFim: horaFim);
    await _dbHelper.atualizarAtividade(atualizada, dbOverride: dbOverride);
    await carregarDados();
  }

  /// Edita uma atividade existente (recalculando automaticamente os minutos)
  Future<void> editarAtividade(Atividade atividade) async {
    await _dbHelper.atualizarAtividade(atividade, dbOverride: dbOverride);
    await carregarDados();
  }

  /// Alterna o check de "Lançada" (true = contorno verde, false = contorno amarelo)
  Future<void> alternarLancada(Atividade atividade) async {
    if (atividade.id == null) return;
    await _dbHelper.atualizarStatusLancada(
      atividade.id!,
      !atividade.lancada,
      dbOverride: dbOverride,
    );
    await carregarDados();
  }

  /// Marca ou desmarca todas as atividades do dia como lançadas
  Future<void> marcarTodasDoDia(int diaId, bool lancada) async {
    await _dbHelper.atualizarTodasLancadasDoDia(
      diaId,
      lancada,
      dbOverride: dbOverride,
    );
    await carregarDados();
  }

  /// Remove uma atividade individual do dia
  Future<void> removerAtividade(int atividadeId) async {
    await _dbHelper.removerAtividade(atividadeId, dbOverride: dbOverride);
    await carregarDados();
  }

  /// Helper para formatar DateTime em YYYY-MM-DD
  static String formatarDataIso(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
