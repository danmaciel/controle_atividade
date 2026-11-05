import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/atividade.dart';
import '../providers/atividade_provider.dart';
import '../widgets/atividade_dialog.dart';
import '../widgets/dia_card_widget.dart';
import '../widgets/dia_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _buscaController = TextEditingController();

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _criarNovoCardDia() async {
    final provider = context.read<AtividadeProvider>();
    final resultado =
        await showDialog<({String dataIso, String? observacao})>(
          context: context,
          builder: (_) => const DiaDialog(),
        );

    if (resultado != null && mounted) {
      await provider.criarDia(
        resultado.dataIso,
        observacao: resultado.observacao,
      );
    }
  }

  Future<void> _registrarAtividadeHoje({bool iniciarAgora = false}) async {
    final provider = context.read<AtividadeProvider>();
    final hojeIso = AtividadeProvider.formatarDataIso(DateTime.now());
    final diaHoje = await provider.criarDia(hojeIso);

    if (!mounted || diaHoje.id == null) return;

    final novaAtividade = await showDialog<Atividade>(
      context: context,
      builder: (_) => AtividadeDialog(
        diaId: diaHoje.id!,
        dataFormatada: diaHoje.dataFormatada,
        iniciarAgora: iniciarAgora,
      ),
    );

    if (novaAtividade != null && mounted) {
      await provider.adicionarAtividade(novaAtividade);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AtividadeProvider>();
    final dias = provider.diasFiltrados;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.fact_check_outlined, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gerenciador de Atividades',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                  ),
                  Text(
                    'Controle diário de horas e lançamentos',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () => _registrarAtividadeHoje(iniciarAgora: true),
              icon: const Icon(Icons.play_circle_outline, size: 20),
              label: const Text('Iniciar Agora (Hoje)'),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: FilledButton.tonalIcon(
              onPressed: () => _registrarAtividadeHoje(iniciarAgora: false),
              icon: const Icon(Icons.add_task, size: 20),
              label: const Text('Nova Atividade Hoje'),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: FilledButton.icon(
              onPressed: _criarNovoCardDia,
              icon: const Icon(Icons.calendar_month, size: 20),
              label: const Text('Novo Dia (Card)'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // BARRA DE RESUMO E FILTROS
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              children: [
                // Cards de Resumo Rápido
                Row(
                  children: [
                    Expanded(
                      child: _ResumoMetricaCard(
                        titulo: 'Total Exibido',
                        subtitulo: '${provider.totalMinutosGeral} min',
                        valorPrincipal: Atividade.formatarHorasMinutos(
                          provider.totalMinutosGeral,
                        ),
                        icone: Icons.access_time,
                        corDestaque: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ResumoMetricaCard(
                        titulo: 'Já Lançadas (Verde)',
                        subtitulo: '${provider.totalMinutosLancados} min',
                        valorPrincipal: Atividade.formatarHorasMinutos(
                          provider.totalMinutosLancados,
                        ),
                        icone: Icons.check_circle_outline,
                        corDestaque: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ResumoMetricaCard(
                        titulo: 'Pendentes (Amarelo)',
                        subtitulo: '${provider.totalMinutosPendentes} min',
                        valorPrincipal: Atividade.formatarHorasMinutos(
                          provider.totalMinutosPendentes,
                        ),
                        icone: Icons.pending_actions,
                        corDestaque: Colors.amber.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Busca e Filtro por Status de Lançamento
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _buscaController,
                        onChanged: provider.atualizarBusca,
                        decoration: InputDecoration(
                          hintText:
                              'Buscar por nome da atividade, data (DD/MM/YYYY) ou observação...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: provider.termoBusca.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _buscaController.clear();
                                    provider.atualizarBusca('');
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    SegmentedButton<FiltroStatusLancamento>(
                      segments: const [
                        ButtonSegment(
                          value: FiltroStatusLancamento.todas,
                          label: Text('Todas'),
                          icon: Icon(Icons.list),
                        ),
                        ButtonSegment(
                          value: FiltroStatusLancamento.pendentes,
                          label: Text('Pendentes'),
                          icon: Icon(Icons.circle_outlined),
                        ),
                        ButtonSegment(
                          value: FiltroStatusLancamento.lancadas,
                          label: Text('Lançadas'),
                          icon: Icon(Icons.check_circle_outline),
                        ),
                      ],
                      selected: {provider.filtroStatus},
                      onSelectionChanged: (selecao) {
                        provider.atualizarFiltroStatus(selecao.first);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // LISTA DE CARDS DE DIAS
          Expanded(
            child: provider.carregando
                ? const Center(child: CircularProgressIndicator())
                : provider.erro != null
                ? Center(
                    child: Text(
                      provider.erro!,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  )
                : dias.isEmpty
                ? _buildListaVazia(context, provider)
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: dias.length,
                    itemBuilder: (context, index) {
                      return DiaCardWidget(dia: dias[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaVazia(BuildContext context, AtividadeProvider provider) {
    final temFiltro =
        provider.termoBusca.isNotEmpty ||
        provider.filtroStatus != FiltroStatusLancamento.todas;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  temFiltro ? Icons.search_off : Icons.event_note_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  temFiltro
                      ? 'Nenhuma atividade encontrada para o filtro atual'
                      : 'Nenhum dia de atividade registrado ainda',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  temFiltro
                      ? 'Tente limpar a busca ou alterar o filtro de status acima.'
                      : 'Crie um Card para o dia de hoje ou selecione uma data específica para começar a registrar suas atividades.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                if (temFiltro)
                  OutlinedButton.icon(
                    onPressed: () {
                      _buscaController.clear();
                      provider.atualizarBusca('');
                      provider.atualizarFiltroStatus(
                        FiltroStatusLancamento.todas,
                      );
                    },
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Limpar Filtros'),
                  )
                else
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () =>
                            _registrarAtividadeHoje(iniciarAgora: false),
                        icon: const Icon(Icons.add_task),
                        label: const Text('Registrar Atividade Hoje'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _criarNovoCardDia,
                        icon: const Icon(Icons.calendar_month),
                        label: const Text('Escolher Outra Data'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResumoMetricaCard extends StatelessWidget {
  final String titulo;
  final String valorPrincipal;
  final String subtitulo;
  final IconData icone;
  final Color corDestaque;

  const _ResumoMetricaCard({
    required this.titulo,
    required this.valorPrincipal,
    required this.subtitulo,
    required this.icone,
    required this.corDestaque,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: corDestaque.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: corDestaque.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: corDestaque.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icone, color: corDestaque, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      valorPrincipal,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: corDestaque,
                      ),
                    ),
                    Text(
                      '($subtitulo)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
}
