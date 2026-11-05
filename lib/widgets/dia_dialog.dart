import 'package:flutter/material.dart';

import '../models/dia_atividade.dart';
import '../providers/atividade_provider.dart';

class DiaDialog extends StatefulWidget {
  final DiaAtividade? diaExistente;

  const DiaDialog({super.key, this.diaExistente});

  @override
  State<DiaDialog> createState() => _DiaDialogState();
}

class _DiaDialogState extends State<DiaDialog> {
  late DateTime _dataSelecionada;
  late TextEditingController _observacaoController;

  @override
  void initState() {
    super.initState();
    _dataSelecionada = widget.diaExistente?.dateTime ?? DateTime.now();
    _observacaoController = TextEditingController(
      text: widget.diaExistente?.observacao ?? '',
    );
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  String get _dataFormatadaBr {
    final d = _dataSelecionada.day.toString().padLeft(2, '0');
    final m = _dataSelecionada.month.toString().padLeft(2, '0');
    final y = _dataSelecionada.year.toString();
    return '$d/$m/$y';
  }

  Future<void> _selecionarData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecione a data do Card de Atividades',
    );
    if (escolhida != null) {
      setState(() {
        _dataSelecionada = escolhida;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.diaExistente != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            editando ? Icons.edit_calendar : Icons.calendar_today,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Text(editando ? 'Editar Data do Card' : 'Novo Dia de Atividades'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Data das Atividades:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selecionarData,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _dataFormatadaBr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _observacaoController,
              decoration: const InputDecoration(
                labelText: 'Observação / Título do Dia (opcional)',
                hintText: 'Ex: Sprint 14, Plantão, Projeto X...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              onSubmitted: (_) => _confirmar(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _confirmar,
          icon: const Icon(Icons.check),
          label: Text(editando ? 'Salvar Alterações' : 'Criar Card do Dia'),
        ),
      ],
    );
  }

  void _confirmar() {
    final dataIso = AtividadeProvider.formatarDataIso(_dataSelecionada);
    final obs = _observacaoController.text.trim();
    Navigator.of(context).pop((
      dataIso: dataIso,
      observacao: obs.isEmpty ? null : obs,
    ));
  }
}
