import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/atividade.dart';
import '../models/dia_atividade.dart';
import '../providers/atividade_provider.dart';
import 'atividade_dialog.dart';
import 'dia_dialog.dart';

class DiaCardWidget extends StatelessWidget {
  final DiaAtividade dia;

  const DiaCardWidget({super.key, required this.dia});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final todasLancadas = dia.todasLancadas;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: todasLancadas
              ? Colors.green.shade600.withValues(alpha: 0.6)
              : colorScheme.outlineVariant,
          width: todasLancadas ? 1.8 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // CABEÇALHO DO CARD DO DIA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                // Data e Observação
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.calendar_month,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dia.dataFormatada,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dia.diaDaSemana,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            if (dia.atividades.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              _buildBadgeStatusDia(dia),
                            ],
                          ],
                        ),
                        if (dia.observacao != null &&
                            dia.observacao!.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            dia.observacao!,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Botões de ação do Card do Dia
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () =>
                          _abrirModalNovaAtividade(context, iniciarAgora: true),
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Iniciar Agora'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal.shade700,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _abrirModalNovaAtividade(
                        context,
                        iniciarAgora: false,
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Adicionar Atividade'),
                    ),
                    if (dia.atividades.isNotEmpty)
                      IconButton(
                        tooltip: todasLancadas
                            ? 'Desmarcar todas do dia como pendentes (Amarelo)'
                            : 'Marcar todas do dia como lançadas (Verde)',
                        onPressed: () {
                          context.read<AtividadeProvider>().marcarTodasDoDia(
                            dia.id!,
                            !todasLancadas,
                          );
                        },
                        icon: Icon(
                          todasLancadas ? Icons.done_all : Icons.checklist_rtl,
                          color: todasLancadas
                              ? Colors.green.shade700
                              : Colors.amber.shade800,
                        ),
                      ),
                    IconButton(
                      tooltip: 'Editar Data / Observação do Card',
                      onPressed: () => _editarCardDia(context),
                      icon: const Icon(Icons.edit_calendar_outlined),
                    ),
                    IconButton(
                      tooltip: 'Remover Card do Dia (e todas as atividades)',
                      onPressed: () => _confirmarExclusaoDia(context),
                      icon: Icon(
                        Icons.delete_forever_outlined,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // CORPO: LISTA DE ATIVIDADES DO DIA
          Padding(
            padding: const EdgeInsets.all(16),
            child: dia.atividades.isEmpty
                ? _buildEstadoVazio(context)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeçalho das Colunas
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 110,
                              child: Text(
                                'Lançada',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Expanded(
                              flex: 4,
                              child: Text(
                                'Nome da Atividade',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 105,
                              child: Text(
                                'Hora Início',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 115,
                              child: Text(
                                'Hora Fim',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 110,
                              child: Text(
                                'Minutos',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 130,
                              child: Text(
                                'Ações',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Linhas de Atividade com Contorno Verde (lançada) ou Amarelo (pendente)
                      ...dia.atividades.map(
                        (atividade) => _buildLinhaAtividade(context, atividade),
                      ),
                    ],
                  ),
          ),

          // RODAPÉ DO CARD: LINHA FINAL TOTALIZADORA DE HORAS DO DIA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.35),
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.summarize_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${dia.atividades.length} ${dia.atividades.length == 1 ? 'atividade registrada' : 'atividades registradas'} '
                      '(${dia.totalLancadas} ${dia.totalLancadas == 1 ? 'lançada' : 'lançadas'})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total do Dia:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            size: 16,
                            color: colorScheme.onPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dia.totalHorasFormatado,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeStatusDia(DiaAtividade dia) {
    final todas = dia.todasLancadas;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: todas
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.amber.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: todas ? Colors.green.shade600 : Colors.amber.shade700,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            todas ? Icons.check_circle : Icons.pending_outlined,
            size: 13,
            color: todas ? Colors.green.shade800 : Colors.amber.shade900,
          ),
          const SizedBox(width: 4),
          Text(
            todas
                ? 'Todas lançadas'
                : '${dia.totalLancadas}/${dia.atividades.length} lançadas',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: todas ? Colors.green.shade800 : Colors.amber.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoVazio(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.playlist_add,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 10),
          Text(
            'Nenhuma atividade registrada neste dia. Clique em "Adicionar Atividade" ou "Iniciar Agora".',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinhaAtividade(BuildContext context, Atividade atividade) {
    final lancada = atividade.lancada;
    final corContorno = lancada ? Colors.green.shade600 : Colors.amber.shade700;
    final corFundo = lancada
        ? Colors.green.withValues(alpha: 0.06)
        : Colors.amber.withValues(alpha: 0.09);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: corContorno,
          width: 2.0, // Contorno destacado verde (lançada) ou amarelo (pendente)
        ),
      ),
      child: Row(
        children: [
          // Coluna 1: Checked button para marcar se já foi lançada
          SizedBox(
            width: 110,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () =>
                  context.read<AtividadeProvider>().alternarLancada(atividade),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: lancada,
                    activeColor: Colors.green.shade700,
                    side: BorderSide(color: corContorno, width: 2),
                    visualDensity: VisualDensity.compact,
                    onChanged: (_) => context
                        .read<AtividadeProvider>()
                        .alternarLancada(atividade),
                  ),
                  Flexible(
                    child: Text(
                      lancada ? 'Lançada' : 'Pendente',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: lancada
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Coluna 2: Nome da Atividade
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                atividade.nome,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Coluna 3: Hora Início
          SizedBox(
            width: 105,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Text(
                  atividade.horaInicio,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),

          // Coluna 4: Hora Fim (ou botão/status Em Andamento)
          SizedBox(
            width: 115,
            child: Center(
              child: atividade.emAndamento
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade700),
                      ),
                      child: Text(
                        'Em aberto',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        atividade.horaFim!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
            ),
          ),

          // Coluna 5: Quantidade de Minutos (calculada automaticamente)
          SizedBox(
            width: 110,
            child: Center(
              child: Tooltip(
                message: Atividade.formatarHorasMinutos(
                  atividade.duracaoMinutos,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${atividade.duracaoMinutos} min',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Coluna 6: Ações da Atividade (Stop se em andamento, Check, Editar, Remover)
          SizedBox(
            width: 130,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (atividade.emAndamento)
                  IconButton(
                    tooltip: 'Finalizar agora (preencher Hora Fim)',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      context.read<AtividadeProvider>().finalizarAtividadeAgora(
                        atividade,
                      );
                    },
                    icon: Icon(
                      Icons.stop_circle,
                      color: Colors.red.shade600,
                    ),
                  ),
                IconButton(
                  tooltip: 'Editar atividade',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      _abrirModalEditarAtividade(context, atividade),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Remover atividade',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      _confirmarExclusaoAtividade(context, atividade),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirModalNovaAtividade(
    BuildContext context, {
    required bool iniciarAgora,
  }) async {
    if (dia.id == null) return;
    final provider = context.read<AtividadeProvider>();
    final novaAtividade = await showDialog<Atividade>(
      context: context,
      builder: (_) => AtividadeDialog(
        diaId: dia.id!,
        dataFormatada: dia.dataFormatada,
        iniciarAgora: iniciarAgora,
      ),
    );

    if (novaAtividade != null) {
      await provider.adicionarAtividade(novaAtividade);
    }
  }

  Future<void> _abrirModalEditarAtividade(
    BuildContext context,
    Atividade atividade,
  ) async {
    if (dia.id == null) return;
    final provider = context.read<AtividadeProvider>();
    final editada = await showDialog<Atividade>(
      context: context,
      builder: (_) => AtividadeDialog(
        diaId: dia.id!,
        dataFormatada: dia.dataFormatada,
        atividadeExistente: atividade,
      ),
    );

    if (editada != null) {
      await provider.editarAtividade(editada);
    }
  }

  Future<void> _editarCardDia(BuildContext context) async {
    final provider = context.read<AtividadeProvider>();
    final resultado =
        await showDialog<({String dataIso, String? observacao})>(
          context: context,
          builder: (_) => DiaDialog(diaExistente: dia),
        );

    if (resultado != null) {
      await provider.editarDia(
        dia.copyWith(
          data: resultado.dataIso,
          observacao: resultado.observacao,
        ),
      );
    }
  }

  Future<void> _confirmarExclusaoAtividade(
    BuildContext context,
    Atividade atividade,
  ) async {
    final provider = context.read<AtividadeProvider>();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Atividade'),
        content: Text(
          'Deseja remover a atividade "${atividade.nome}" (${atividade.horaInicio} - ${atividade.horaFim ?? 'Em aberto'})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar == true && atividade.id != null) {
      await provider.removerAtividade(atividade.id!);
    }
  }

  Future<void> _confirmarExclusaoDia(BuildContext context) async {
    final provider = context.read<AtividadeProvider>();
    final qtd = dia.atividades.length;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Card do Dia'),
        content: Text(
          'Tem certeza que deseja excluir o Card do dia ${dia.dataFormatada} '
          'e todas as suas $qtd ${qtd == 1 ? 'atividade registrada' : 'atividades registradas'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir Dia Inteiro'),
          ),
        ],
      ),
    );

    if (confirmar == true && dia.id != null) {
      await provider.removerDia(dia.id!);
    }
  }
}
