import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/atividade.dart';
import '../models/dia_atividade.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  final String? customDbPath;

  DatabaseHelper._internal({this.customDbPath});

  /// Construtor para testes (ex: usando inMemoryDatabasePath)
  factory DatabaseHelper.forTesting(String dbPath) {
    return DatabaseHelper._internal(customDbPath: dbPath);
  }

  static bool _ffiInicializado = false;

  static void inicializarFfi() {
    if (_ffiInicializado) return;
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInicializado = true;
    }
  }

  Future<Database> get database async {
    if (customDbPath != null) {
      return _initDatabase(customDbPath!);
    }
    if (_database != null && _database!.isOpen) {
      return _database!;
    }
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final dbPath = p.join(dir.path, 'controle_atividade.db');
    _database = await _initDatabase(dbPath);
    return _database!;
  }

  Future<Database> _initDatabase(String dbPath) async {
    inicializarFfi();
    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 2,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('ALTER TABLE atividades ADD COLUMN tipo TEXT');
          }
        },
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dias_atividade (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL UNIQUE,
        observacao TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE atividades (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dia_id INTEGER NOT NULL,
        tipo TEXT,
        nome TEXT NOT NULL,
        hora_inicio TEXT NOT NULL,
        hora_fim TEXT,
        duracao_minutos INTEGER NOT NULL DEFAULT 0,
        lancada INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (dia_id) REFERENCES dias_atividade (id) ON DELETE CASCADE ON UPDATE CASCADE
      )
    ''');
  }

  /// Lista todos os dias (cards) ordenados por data decrescente, já com suas atividades
  Future<List<DiaAtividade>> listarDiasComAtividades({Database? dbOverride}) async {
    final db = dbOverride ?? await database;
    final diasMaps = await db.query(
      'dias_atividade',
      orderBy: 'data DESC, id DESC',
    );

    if (diasMaps.isEmpty) return [];

    final atividadesMaps = await db.query(
      'atividades',
      orderBy: 'hora_inicio ASC, id ASC',
    );

    final Map<int, List<Atividade>> atividadesPorDia = {};
    for (final map in atividadesMaps) {
      final ativ = Atividade.fromMap(map);
      atividadesPorDia.putIfAbsent(ativ.diaId, () => []).add(ativ);
    }

    return diasMaps.map((diaMap) {
      final id = diaMap['id'] as int;
      return DiaAtividade.fromMap(
        diaMap,
        atividades: atividadesPorDia[id] ?? [],
      );
    }).toList();
  }

  /// Obtém um dia pela data (YYYY-MM-DD) ou cria caso não exista
  Future<DiaAtividade> obterOuCriarDia(
    String data, {
    String? observacao,
    Database? dbOverride,
  }) async {
    final db = dbOverride ?? await database;
    final existentes = await db.query(
      'dias_atividade',
      where: 'data = ?',
      whereArgs: [data],
      limit: 1,
    );

    if (existentes.isNotEmpty) {
      final diaMap = existentes.first;
      final id = diaMap['id'] as int;
      if (observacao != null && observacao.trim().isNotEmpty) {
        await db.update(
          'dias_atividade',
          {'observacao': observacao.trim()},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
      final ativMaps = await db.query(
        'atividades',
        where: 'dia_id = ?',
        whereArgs: [id],
        orderBy: 'hora_inicio ASC, id ASC',
      );
      return DiaAtividade.fromMap(
        diaMap,
        atividades: ativMaps.map(Atividade.fromMap).toList(),
      );
    }

    final id = await db.insert('dias_atividade', {
      'data': data,
      'observacao': observacao?.trim(),
    });

    return DiaAtividade(
      id: id,
      data: data,
      observacao: observacao?.trim(),
      atividades: [],
    );
  }

  /// Atualiza a data e/ou observação de um Card de Dia
  Future<void> atualizarDia(DiaAtividade dia, {Database? dbOverride}) async {
    final db = dbOverride ?? await database;
    await db.update(
      'dias_atividade',
      {
        'data': dia.data,
        'observacao': dia.observacao?.trim(),
      },
      where: 'id = ?',
      whereArgs: [dia.id],
    );
  }

  /// Remove o Card do Dia e todas as atividades vinculadas a ele (ON DELETE CASCADE)
  Future<void> removerDia(int diaId, {Database? dbOverride}) async {
    final db = dbOverride ?? await database;
    await db.delete(
      'dias_atividade',
      where: 'id = ?',
      whereArgs: [diaId],
    );
  }

  /// Insere uma atividade individual dentro de um dia
  Future<int> inserirAtividade(
    Atividade atividade, {
    Database? dbOverride,
  }) async {
    final db = dbOverride ?? await database;
    final recalculada = atividade.copyWith(
      duracaoMinutos: Atividade.calcularMinutos(
        atividade.horaInicio,
        atividade.horaFim,
      ),
    );
    return db.insert('atividades', recalculada.toMap());
  }

  /// Atualiza uma atividade individual (recalculando os minutos automaticamente)
  Future<void> atualizarAtividade(
    Atividade atividade, {
    Database? dbOverride,
  }) async {
    final db = dbOverride ?? await database;
    final recalculada = atividade.copyWith(
      duracaoMinutos: Atividade.calcularMinutos(
        atividade.horaInicio,
        atividade.horaFim,
      ),
    );
    await db.update(
      'atividades',
      recalculada.toMap(),
      where: 'id = ?',
      whereArgs: [recalculada.id],
    );
  }

  /// Alterna o status 'lancada' (true = verde, false = amarelo) de uma atividade
  Future<void> atualizarStatusLancada(
    int atividadeId,
    bool lancada, {
    Database? dbOverride,
  }) async {
    final db = dbOverride ?? await database;
    await db.update(
      'atividades',
      {'lancada': lancada ? 1 : 0},
      where: 'id = ?',
      whereArgs: [atividadeId],
    );
  }

  /// Marca ou desmarca todas as atividades de um dia como lançadas
  Future<void> atualizarTodasLancadasDoDia(
    int diaId,
    bool lancada, {
    Database? dbOverride,
  }) async {
    final db = dbOverride ?? await database;
    await db.update(
      'atividades',
      {'lancada': lancada ? 1 : 0},
      where: 'dia_id = ?',
      whereArgs: [diaId],
    );
  }

  /// Remove uma única atividade
  Future<void> removerAtividade(
    int atividadeId, {
    Database? dbOverride,
  }) async {
    final db = dbOverride ?? await database;
    await db.delete(
      'atividades',
      where: 'id = ?',
      whereArgs: [atividadeId],
    );
  }
}
