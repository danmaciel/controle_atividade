import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/atividade.dart';

class AtividadeDialog extends StatefulWidget {
  final int diaId;
  final String dataFormatada;
  final Atividade? atividadeExistente;
  final bool iniciarAgora;

  const AtividadeDialog({
    super.key,
    required this.diaId,
    required this.dataFormatada,
    this.atividadeExistente,
    this.iniciarAgora = false,
  });

  @override
  State<AtividadeDialog> createState() => _AtividadeDialogState();
}

class _AtividadeDialogState extends State<AtividadeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TipoAtividade _tipoSelecionado;
  late TextEditingController _numeroController;
  late TextEditingController _nomeController;
  late TextEditingController _horaInicioController;
  late TextEditingController _horaFimController;
  late bool _lancada;

  @override
  void initState() {
    super.initState();
    final existente = widget.atividadeExistente;
    final agora = TimeOfDay.now();
    final horaAtualStr = _formatTimeOfDay(agora);

    if (existente != null) {
      _tipoSelecionado =
          existente.tipo ?? TipoAtividade.inferirDeNome(existente.nome);
      _numeroController = TextEditingController(
        text: _tipoSelecionado.extrairNumero(existente.nome),
      );
      _nomeController = TextEditingController(text: existente.nome);
    } else {
      _tipoSelecionado = TipoAtividade.worklog;
      _numeroController = TextEditingController();
      _nomeController = TextEditingController(
        text: _tipoSelecionado.gerarNome(),
      );
    }

    _horaInicioController = TextEditingController(
      text: existente?.horaInicio ?? horaAtualStr,
    );
    _horaFimController = TextEditingController(
      text: existente != null
          ? (existente.horaFim ?? '')
          : (widget.iniciarAgora ? '' : horaAtualStr),
    );
    _lancada = existente?.lancada ?? false;

    _numeroController.addListener(_aoAlterarNumero);
    _horaInicioController.addListener(_recalcularPreview);
    _horaFimController.addListener(_recalcularPreview);
  }

  void _aoAlterarNumero() {
    if (_tipoSelecionado.requerNumero) {
      final novoNome = _tipoSelecionado.gerarNome(
        numero: _numeroController.text,
      );
      _nomeController.value = TextEditingValue(
        text: novoNome,
        selection: TextSelection.collapsed(offset: novoNome.length),
      );
    }
  }

  void _aoSelecionarTipo(TipoAtividade? novoTipo) {
    if (novoTipo == null) return;
    setState(() {
      _tipoSelecionado = novoTipo;
      final novoNome = _tipoSelecionado.gerarNome(
        numero: _numeroController.text,
      );
      _nomeController.value = TextEditingValue(
        text: novoNome,
        selection: TextSelection.collapsed(offset: novoNome.length),
      );
    });
  }

  void _recalcularPreview() {
    setState(() {});
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _nomeController.dispose();
    _horaInicioController.dispose();
    _horaFimController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  TimeOfDay _parseTimeOfDay(String texto) {
    final partes = texto.trim().split(':');
    if (partes.length == 2) {
      final h = int.tryParse(partes[0]);
      final m = int.tryParse(partes[1]);
      if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        return TimeOfDay(hour: h, minute: m);
      }
    }
    return TimeOfDay.now();
  }

  bool _validarHora(String valor, {bool obrigatorio = true}) {
    final limpo = valor.trim();
    if (limpo.isEmpty) return !obrigatorio;
    final regex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
    return regex.hasMatch(limpo);
  }

  Future<void> _selecionarHorario(TextEditingController controller) async {
    final inicial = _parseTimeOfDay(controller.text);
    final escolhido = await showTimePicker(
      context: context,
      initialTime: inicial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (escolhido != null) {
      controller.text = _formatTimeOfDay(escolhido);
    }
  }

  void _preencherAgora(TextEditingController controller) {
    controller.text = _formatTimeOfDay(TimeOfDay.now());
  }

  int get _minutosCalculados {
    final inicio = _horaInicioController.text.trim();
    final fim = _horaFimController.text.trim();
    if (!_validarHora(inicio) || !_validarHora(fim, obrigatorio: true)) {
      return 0;
    }
    return Atividade.calcularMinutos(inicio, fim);
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.atividadeExistente != null;
    final minutos = _minutosCalculados;
    final emAberto = _horaFimController.text.trim().isEmpty;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            editando
                ? Icons.edit_note
                : (widget.iniciarAgora ? Icons.play_circle : Icons.add_task),
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editando
                      ? 'Editar Atividade'
                      : (widget.iniciarAgora
                            ? 'Iniciar Atividade Agora'
                            : 'Nova Atividade'),
                ),
                Text(
                  'Data do Card: ${widget.dataFormatada}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: _tipoSelecionado.requerNumero ? 3 : 1,
                    child: DropdownButtonFormField<TipoAtividade>(
                      initialValue: _tipoSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Atividade *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: TipoAtividade.values.map((tipo) {
                        return DropdownMenuItem<TipoAtividade>(
                          value: tipo,
                          child: Text(tipo.label),
                        );
                      }).toList(),
                      onChanged: _aoSelecionarTipo,
                    ),
                  ),
                  if (_tipoSelecionado.requerNumero) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _numeroController,
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Número da ${_tipoSelecionado.label} *',
                          hintText: 'Ex: 123',
                          prefixText: '#',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.tag),
                        ),
                        validator: (value) {
                          final numDigitado = value?.trim() ?? '';
                          final nomeAtual = _nomeController.text.trim();
                          final apenasPrefixo =
                              nomeAtual ==
                              _tipoSelecionado.textoPredefinido.trim();
                          if (numDigitado.isEmpty && apenasPrefixo) {
                            return 'Informe o #número';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _salvar(),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                autofocus: !_tipoSelecionado.requerNumero,
                decoration: const InputDecoration(
                  labelText: 'Nome / Descrição da Atividade *',
                  hintText: 'Ex: worklog, dayle, Working in Issue #123...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.task_alt),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome da atividade';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _salvar(),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _horaInicioController,
                      inputFormatters: [_HoraInputFormatter()],
                      decoration: InputDecoration(
                        labelText: 'Hora Início (HH:mm) *',
                        hintText: '09:00',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.schedule),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Definir hora atual (Agora)',
                              icon: const Icon(Icons.bolt, size: 20),
                              onPressed: () =>
                                  _preencherAgora(_horaInicioController),
                            ),
                            IconButton(
                              tooltip: 'Abrir relógio',
                              icon: const Icon(Icons.access_time, size: 20),
                              onPressed: () =>
                                  _selecionarHorario(_horaInicioController),
                            ),
                          ],
                        ),
                      ),
                      validator: (v) {
                        if (!_validarHora(v ?? '', obrigatorio: true)) {
                          return 'Use HH:mm (ex: 09:30)';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _horaFimController,
                      inputFormatters: [_HoraInputFormatter()],
                      decoration: InputDecoration(
                        labelText: 'Hora Fim (HH:mm)',
                        hintText: 'Vazio = Em andamento',
                        helperText: 'Deixe vazio se estiver em andamento',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.flag_outlined),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_horaFimController.text.isNotEmpty)
                              IconButton(
                                tooltip: 'Limpar (Deixar em andamento)',
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () => _horaFimController.clear(),
                              ),
                            IconButton(
                              tooltip: 'Definir hora atual (Agora)',
                              icon: const Icon(Icons.bolt, size: 20),
                              onPressed: () =>
                                  _preencherAgora(_horaFimController),
                            ),
                            IconButton(
                              tooltip: 'Abrir relógio',
                              icon: const Icon(Icons.access_time, size: 20),
                              onPressed: () =>
                                  _selecionarHorario(_horaFimController),
                            ),
                          ],
                        ),
                      ),
                      validator: (v) {
                        if (!_validarHora(v ?? '', obrigatorio: false)) {
                          return 'Use HH:mm (ex: 11:00)';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Card de pré-visualização automática dos minutos
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Duração calculada automaticamente:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Text(
                      emAberto
                          ? 'Em andamento (0 min)'
                          : '$minutos min (${Atividade.formatarHorasMinutos(minutos)})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: emAberto
                            ? Colors.orange.shade800
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Checkbox de Status Lançada com preview da borda verde/amarela
              InkWell(
                onTap: () => setState(() => _lancada = !_lancada),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _lancada
                        ? Colors.green.withValues(alpha: 0.08)
                        : Colors.amber.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _lancada
                          ? Colors.green.shade600
                          : Colors.amber.shade700,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _lancada,
                        activeColor: Colors.green.shade700,
                        onChanged: (v) =>
                            setState(() => _lancada = v ?? false),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _lancada
                                  ? 'Atividade Lançada (Contorno Verde)'
                                  : 'Pendente de Lançamento (Contorno Amarelo)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _lancada
                                    ? Colors.green.shade800
                                    : Colors.amber.shade900,
                              ),
                            ),
                            Text(
                              'Marque quando esta atividade já tiver sido lançada no sistema externo/apontamento.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _salvar,
          icon: const Icon(Icons.save),
          label: Text(editando ? 'Salvar Alterações' : 'Adicionar Atividade'),
        ),
      ],
    );
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final nome = _nomeController.text.trim();
    final inicio = _horaInicioController.text.trim();
    final fim = _horaFimController.text.trim();

    final resultado = Atividade(
      id: widget.atividadeExistente?.id,
      diaId: widget.diaId,
      tipo: _tipoSelecionado,
      nome: nome,
      horaInicio: inicio,
      horaFim: fim.isEmpty ? null : fim,
      lancada: _lancada,
    );

    Navigator.of(context).pop(resultado);
  }
}

/// Formatter simples para auxiliar na digitação de horários HH:mm
class _HoraInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final trunc = digitsOnly.length > 4
        ? digitsOnly.substring(0, 4)
        : digitsOnly;
    final buffer = StringBuffer();
    for (int i = 0; i < trunc.length; i++) {
      if (i == 2) buffer.write(':');
      buffer.write(trunc[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
