import 'atividade.dart';

class DiaAtividade {
  final int? id;
  final String data; // Formato ISO YYYY-MM-DD
  final String? observacao;
  final List<Atividade> atividades;

  DiaAtividade({
    this.id,
    required this.data,
    this.observacao,
    this.atividades = const [],
  });

  /// Total de minutos somando todas as atividades do dia
  int get totalMinutos =>
      atividades.fold(0, (soma, item) => soma + item.duracaoMinutos);

  /// Total de horas e minutos formatado (ex: "02h 30m (150 min)")
  String get totalHorasFormatado {
    final hm = Atividade.formatarHorasMinutos(totalMinutos);
    return '$hm ($totalMinutos min)';
  }

  /// Total apenas no formato HHh MMm (ex: "02h 30m")
  String get apenasHorasMinutos => Atividade.formatarHorasMinutos(totalMinutos);

  /// Quantidade de atividades já marcadas como lançadas
  int get totalLancadas => atividades.where((a) => a.lancada).length;

  /// Verifica se todas as atividades do dia (quando há pelo menos 1) estão lançadas
  bool get todasLancadas =>
      atividades.isNotEmpty && atividades.every((a) => a.lancada);

  /// Converte a string YYYY-MM-DD para DateTime
  DateTime get dateTime {
    final partes = data.split('-');
    if (partes.length == 3) {
      final ano = int.tryParse(partes[0]) ?? 2026;
      final mes = int.tryParse(partes[1]) ?? 1;
      final dia = int.tryParse(partes[2]) ?? 1;
      return DateTime(ano, mes, dia);
    }
    return DateTime.tryParse(data) ?? DateTime.now();
  }

  /// Data formatada no padrão brasileiro DD/MM/YYYY
  String get dataFormatada {
    final dt = dateTime;
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  /// Dia da semana em português
  String get diaDaSemana {
    const nomes = {
      DateTime.monday: 'Segunda-feira',
      DateTime.tuesday: 'Terça-feira',
      DateTime.wednesday: 'Quarta-feira',
      DateTime.thursday: 'Quinta-feira',
      DateTime.friday: 'Sexta-feira',
      DateTime.saturday: 'Sábado',
      DateTime.sunday: 'Domingo',
    };
    return nomes[dateTime.weekday] ?? '';
  }

  DiaAtividade copyWith({
    int? id,
    String? data,
    String? observacao,
    List<Atividade>? atividades,
  }) {
    return DiaAtividade(
      id: id ?? this.id,
      data: data ?? this.data,
      observacao: observacao ?? this.observacao,
      atividades: atividades ?? this.atividades,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'data': data,
      'observacao': observacao,
    };
  }

  factory DiaAtividade.fromMap(
    Map<String, dynamic> map, {
    List<Atividade> atividades = const [],
  }) {
    return DiaAtividade(
      id: map['id'] as int?,
      data: map['data'] as String,
      observacao: map['observacao'] as String?,
      atividades: atividades,
    );
  }
}
