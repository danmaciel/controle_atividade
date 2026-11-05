import 'package:controle_atividade/database/database_helper.dart';
import 'package:controle_atividade/main.dart';
import 'package:controle_atividade/models/atividade.dart';
import 'package:controle_atividade/providers/atividade_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    DatabaseHelper.inicializarFfi();
  });

  group('Cálculo automático de minutos e totalizadores', () {
    test('Calcula corretamente a duração em minutos entre hora início e fim', () {
      expect(Atividade.calcularMinutos('08:00', '09:30'), 90);
      expect(Atividade.calcularMinutos('13:15', '17:45'), 270);
      expect(Atividade.calcularMinutos('09:00', null), 0);
      expect(Atividade.calcularMinutos('23:30', '00:30'), 60);
    });

    test('Formata horas e minutos corretamente', () {
      expect(Atividade.formatarHorasMinutos(150), '02h 30m');
      expect(Atividade.formatarHorasMinutos(45), '00h 45m');
    });

    test('Tipos de atividade estão na ordem correta e geram textos predefinidos', () {
      expect(
        TipoAtividade.values,
        [
          TipoAtividade.worklog,
          TipoAtividade.daily,
          TipoAtividade.issue,
          TipoAtividade.task,
          TipoAtividade.sprintRetrospective,
          TipoAtividade.sprintPlanning,
          TipoAtividade.sprintReview,
        ],
      );

      expect(TipoAtividade.worklog.gerarNome(), 'worklog');
      expect(TipoAtividade.daily.gerarNome(), 'dayle');
      expect(TipoAtividade.issue.gerarNome(numero: '123'), 'Working in Issue #123');
      expect(TipoAtividade.task.gerarNome(numero: '456'), 'Working in Task #456');
      expect(TipoAtividade.sprintRetrospective.gerarNome(), 'sprint retrospective');
      expect(TipoAtividade.sprintPlanning.gerarNome(), 'sprint planning');
      expect(TipoAtividade.sprintReview.gerarNome(), 'sprint review');
    });
  });

  group('Persistência SQLite e Provider (CRUD Dia e Atividades)', () {
    test('Insere, edita, alterna lançada e remove atividades e card do dia', () async {
      final dbHelper = DatabaseHelper.forTesting(inMemoryDatabasePath);
      final db = await dbHelper.database;
      final provider = AtividadeProvider(dbHelper: dbHelper, dbOverride: db);

      // 1. Criar card do dia
      final dia = await provider.criarDia('2026-11-02', observacao: 'Segunda');
      expect(provider.todosDias.length, 1);
      expect(dia.dataFormatada, '02/11/2026');

      // 2. Inserir duas atividades
      await provider.adicionarAtividade(
        Atividade(
          diaId: dia.id!,
          nome: 'Reunião de alinhamento',
          horaInicio: '09:00',
          horaFim: '10:00',
          lancada: false,
        ),
      );
      await provider.adicionarAtividade(
        Atividade(
          diaId: dia.id!,
          nome: 'Desenvolvimento Flutter',
          horaInicio: '10:00',
          horaFim: '11:30',
          lancada: true,
        ),
      );

      expect(provider.todosDias.first.atividades.length, 2);
      expect(provider.todosDias.first.totalMinutos, 150);
      expect(provider.todosDias.first.totalHorasFormatado, '02h 30m (150 min)');
      expect(provider.totalMinutosLancados, 90);
      expect(provider.totalMinutosPendentes, 60);

      // 3. Alternar status "lançada" da primeira atividade
      final primeira = provider.todosDias.first.atividades.first;
      expect(primeira.lancada, isFalse);
      await provider.alternarLancada(primeira);
      expect(provider.todosDias.first.atividades.first.lancada, isTrue);
      expect(provider.todosDias.first.todasLancadas, isTrue);

      // 4. Editar horário da primeira atividade (recalculando minutos automaticamente)
      final primeiraAtualizada = provider.todosDias.first.atividades.first
          .copyWith(horaFim: '10:15');
      await provider.editarAtividade(primeiraAtualizada);
      expect(
        provider.todosDias.first.atividades.first.duracaoMinutos,
        75,
      );
      expect(provider.todosDias.first.totalMinutos, 165);

      // 5. Remover atividade individual
      await provider.removerAtividade(primeiraAtualizada.id!);
      expect(provider.todosDias.first.atividades.length, 1);
      expect(provider.todosDias.first.totalMinutos, 90);

      // 6. Remover card do dia inteiro (cascade)
      await provider.removerDia(dia.id!);
      expect(provider.todosDias, isEmpty);

      await db.close();
    });
  });

  testWidgets('Exibe Card do Dia, contorno verde/amarelo e totalizador', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    late Database db;
    late AtividadeProvider provider;

    await tester.runAsync(() async {
      final dbHelper = DatabaseHelper.forTesting(inMemoryDatabasePath);
      db = await dbHelper.database;
      provider = AtividadeProvider(dbHelper: dbHelper, dbOverride: db);

      final dia = await provider.criarDia('2026-11-02', observacao: 'Sprint 1');
      await provider.adicionarAtividade(
        Atividade(
          diaId: dia.id!,
          nome: 'Tarefa Pendente',
          horaInicio: '08:00',
          horaFim: '09:00',
          lancada: false,
        ),
      );
      await provider.adicionarAtividade(
        Atividade(
          diaId: dia.id!,
          nome: 'Tarefa Lançada',
          horaInicio: '09:00',
          horaFim: '10:30',
          lancada: true,
        ),
      );
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const ControleAtividadeApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('02/11/2026'), findsOneWidget);
    expect(find.text('Tarefa Pendente'), findsOneWidget);
    expect(find.text('Tarefa Lançada'), findsOneWidget);
    expect(find.text('60 min'), findsOneWidget);
    expect(find.text('90 min'), findsOneWidget);
    expect(find.text('02h 30m (150 min)'), findsOneWidget);

    await tester.runAsync(() async {
      await db.close();
    });
  });
}
