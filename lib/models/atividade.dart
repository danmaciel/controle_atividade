enum TipoAtividade {
  worklog('Worklog', 'worklog'),
  daily('Daily', 'dayle'),
  issue('Issue', 'Working in Issue #'),
  task('Task', 'Working in Task #'),
  sprintRetrospective('Sprint Retrospective', 'sprint retrospective'),
  sprintPlanning('Sprint Planning', 'sprint planning'),
  sprintReview('Sprint Review', 'sprint review');

  final String label;
  final String textoPredefinido;

  const TipoAtividade(this.label, this.textoPredefinido);

  bool get requerNumero =>
      this == TipoAtividade.issue || this == TipoAtividade.task;

  /// Gera o nome predefinido para o tipo de atividade.
  /// Para Issue e Task, concatena o número informado após `#`.
  String gerarNome({String numero = ''}) {
    if (!requerNumero) return textoPredefinido;
    final numLimpo = numero.trim().replaceFirst(RegExp(r'^#+'), '');
    return '$textoPredefinido$numLimpo';
  }

  /// Extrai o número caso o nome siga o padrão "Working in Issue #123" ou "Working in Task #123"
  String extrairNumero(String nome) {
    if (!requerNumero) return '';
    final texto = nome.trim();
    if (texto.toLowerCase().startsWith(textoPredefinido.toLowerCase())) {
      return texto.substring(textoPredefinido.length).trim();
    }
    return '';
  }

  static TipoAtividade? fromName(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    for (final tipo in TipoAtividade.values) {
      if (tipo.name == name) return tipo;
    }
    return null;
  }

  /// Infere o tipo de atividade a partir do nome salvo
  static TipoAtividade inferirDeNome(String nome) {
    final limpo = nome.trim().toLowerCase();
    if (limpo.startsWith('working in issue #')) {
      return TipoAtividade.issue;
    }
    if (limpo.startsWith('working in task #')) {
      return TipoAtividade.task;
    }
    if (limpo == 'dayle' || limpo == 'daily') {
      return TipoAtividade.daily;
    }
    if (limpo == 'sprint retrospective') {
      return TipoAtividade.sprintRetrospective;
    }
    if (limpo == 'sprint planning' || limpo == 'spring planning') {
      return TipoAtividade.sprintPlanning;
    }
    if (limpo == 'sprint review') {
      return TipoAtividade.sprintReview;
    }
    return TipoAtividade.worklog;
  }
}

class Atividade {
  final int? id;
  final int diaId;
  final TipoAtividade? tipo;
  final String nome;
  final String horaInicio; // Formato HH:mm
  final String? horaFim; // Formato HH:mm (null ou vazio se em andamento)
  final int duracaoMinutos; // Calculado automaticamente
  final bool lancada; // Se foi lançada (true = contorno verde, false = contorno amarelo)

  Atividade({
    this.id,
    required this.diaId,
    this.tipo,
    required this.nome,
    required this.horaInicio,
    this.horaFim,
    int? duracaoMinutos,
    this.lancada = false,
  }) : duracaoMinutos =
           duracaoMinutos ?? calcularMinutos(horaInicio, horaFim);

  bool get emAndamento => horaFim == null || horaFim!.trim().isEmpty;

  /// Calcula a quantidade de minutos entre [horaInicio] e [horaFim] no formato HH:mm.
  /// Caso [horaFim] seja menor que [horaInicio] (ex: virou a meia-noite), soma 24h.
  static int calcularMinutos(String? horaInicio, String? horaFim) {
    if (horaInicio == null ||
        horaFim == null ||
        horaInicio.trim().isEmpty ||
        horaFim.trim().isEmpty) {
      return 0;
    }

    final inicioMin = _parseHoraParaMinutos(horaInicio);
    final fimMin = _parseHoraParaMinutos(horaFim);

    if (inicioMin == null || fimMin == null) return 0;

    int diff = fimMin - inicioMin;
    if (diff < 0) {
      // Caso a atividade tenha passado da meia-noite
      diff += 24 * 60;
    }
    return diff;
  }

  static int? _parseHoraParaMinutos(String horaStr) {
    final partes = horaStr.trim().split(':');
    if (partes.length != 2) return null;
    final h = int.tryParse(partes[0]);
    final m = int.tryParse(partes[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }

  /// Formata minutos para "XXh YYm"
  static String formatarHorasMinutos(int totalMinutos) {
    final horas = totalMinutos ~/ 60;
    final minutos = totalMinutos % 60;
    final hStr = horas.toString().padLeft(2, '0');
    final mStr = minutos.toString().padLeft(2, '0');
    return '${hStr}h ${mStr}m';
  }

  Atividade copyWith({
    int? id,
    int? diaId,
    TipoAtividade? tipo,
    String? nome,
    String? horaInicio,
    String? horaFim,
    bool limparHoraFim = false,
    int? duracaoMinutos,
    bool? lancada,
  }) {
    final novoInicio = horaInicio ?? this.horaInicio;
    final novoFim = limparHoraFim ? null : (horaFim ?? this.horaFim);
    return Atividade(
      id: id ?? this.id,
      diaId: diaId ?? this.diaId,
      tipo: tipo ?? this.tipo,
      nome: nome ?? this.nome,
      horaInicio: novoInicio,
      horaFim: novoFim,
      duracaoMinutos:
          duracaoMinutos ?? calcularMinutos(novoInicio, novoFim),
      lancada: lancada ?? this.lancada,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'dia_id': diaId,
      if (tipo != null) 'tipo': tipo!.name,
      'nome': nome,
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
      'duracao_minutos': duracaoMinutos,
      'lancada': lancada ? 1 : 0,
    };
  }

  factory Atividade.fromMap(Map<String, dynamic> map) {
    final inicio = map['hora_inicio'] as String? ?? '00:00';
    final fim = map['hora_fim'] as String?;
    final nome = map['nome'] as String? ?? '';
    return Atividade(
      id: map['id'] as int?,
      diaId: map['dia_id'] as int,
      tipo: TipoAtividade.fromName(map['tipo'] as String?) ??
          TipoAtividade.inferirDeNome(nome),
      nome: nome,
      horaInicio: inicio,
      horaFim: fim,
      duracaoMinutos:
          (map['duracao_minutos'] as int?) ?? calcularMinutos(inicio, fim),
      lancada: (map['lancada'] as int? ?? 0) == 1,
    );
  }
}
