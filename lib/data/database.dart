import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

enum EventStatus { pending, done, cancelled }

@DataClassName('PlanetRow')
class Planets extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get tempMax => integer()();
  RealColumn get metal => real()();
  RealColumn get crystal => real()();
  RealColumn get deuterium => real()();

  /// Champ de débris (schéma v8).
  RealColumn get debrisMetal => real().withDefault(const Constant(0))();
  RealColumn get debrisCrystal => real().withDefault(const Constant(0))();

  /// Epoch UTC en millisecondes.
  IntColumn get lastUpdateMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BuildingRow')
class Buildings extends Table {
  IntColumn get planetId => integer().references(Planets, #id)();

  /// Clé du bâtiment (`BuildingKind.key`).
  TextColumn get kind => text()();
  IntColumn get level => integer()();

  /// Réglage de production 0 à 100 (schéma v2).
  IntColumn get percent => integer().withDefault(const Constant(100))();

  @override
  Set<Column<Object>> get primaryKey => {planetId, kind};
}

/// Niveaux de technologie, globaux à la partie (schéma v2).
@DataClassName('ResearchRow')
class Research extends Table {
  /// Clé de la techno (`TechKind.key`).
  TextColumn get kind => text()();
  IntColumn get level => integer()();

  @override
  Set<Column<Object>> get primaryKey => {kind};
}

/// Unités stationnées sur une planète (schéma v3).
@DataClassName('UnitRow')
class Units extends Table {
  IntColumn get planetId => integer().references(Planets, #id)();

  /// Clé de l'unité (`UnitKind.key`).
  TextColumn get kind => text()();
  IntColumn get quantity => integer()();

  @override
  Set<Column<Object>> get primaryKey => {planetId, kind};
}

/// Rapports des raids (schéma v4), JSON dans [payload].
@DataClassName('ReportRow')
class Reports extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get atMs => integer()();
  TextColumn get payload => text()();
  BoolColumn get seen => boolean().withDefault(const Constant(false))();
}

/// Niveau de chaque officier débloqué (schéma v5).
@DataClassName('OfficerRow')
class Officers extends Table {
  /// Clé de l'officier (`OfficerKind.key`).
  TextColumn get kind => text()();
  IntColumn get level => integer()();

  @override
  Set<Column<Object>> get primaryKey => {kind};
}

/// Compteurs de progression, prérequis des officiers (schéma v5).
@DataClassName('CounterRow')
class Counters extends Table {
  /// Clé du compteur (`Counter.key`).
  TextColumn get kind => text()();
  IntColumn get value => integer()();

  @override
  Set<Column<Object>> get primaryKey => {kind};
}

/// Ordres en file d'attente, pas encore démarrés ni payés (schéma v6, spec 13). [id] est
/// l'id d'événement réservé ; [payload] : `{"item": clé}` ou `{"unit": clé, "count": n}`.
@DataClassName('QueuedOrderRow')
class QueuedOrders extends Table {
  IntColumn get id => integer()();
  IntColumn get position => integer()();
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Effets temporaires des événements en cours (schéma v7, spec 14), réécrits à chaque
/// sauvegarde. [payload] : JSON de `encodeEffect`.
@DataClassName('EffectRow')
class ActiveEffects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get payload => text()();
}

/// Bases pirates (schéma v9, spec 15) : JSON de `encodeBase`, réécrites à chaque sauvegarde.
@DataClassName('PirateBaseRow')
class PirateBases extends Table {
  IntColumn get idx => integer()();
  TextColumn get payload => text()();

  @override
  Set<Column<Object>> get primaryKey => {idx};
}

/// Journal des événements ponctuels (schéma v7) : clé, issue, option.
@DataClassName('StoryLogRow')
class StoryLog extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get atMs => integer()();
  TextColumn get key => text()();

  /// `StoryOutcomeKind.name`.
  TextColumn get kind => text()();
  IntColumn get option => integer().nullable()();
}

/// File unique de tous les événements, futurs et passés.
@DataClassName('EventRow')
class Events extends Table {
  IntColumn get id => integer()();
  IntColumn get planetId => integer().references(Planets, #id)();
  TextColumn get type => text()();
  IntColumn get dueAtMs => integer()();

  /// Données propres au type, en JSON.
  TextColumn get payload => text()();
  TextColumn get status => textEnum<EventStatus>()();
  IntColumn get createdAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('MetaEntry')
class Meta extends Table {
  TextColumn get name => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {name};
}

@DriftDatabase(
  tables: [
    Planets,
    Buildings,
    Research,
    Units,
    Events,
    Reports,
    Officers,
    Counters,
    QueuedOrders,
    ActiveEffects,
    StoryLog,
    PirateBases,
    Meta,
  ],
)
class StarmineDatabase extends _$StarmineDatabase {
  StarmineDatabase(super.executor);

  /// Base sur le téléphone (dossier de l'app).
  factory StarmineDatabase.open() => StarmineDatabase(driftDatabase(name: 'starmine'));

  /// v1 : V0. v2 : technologies (table research) et réglages de production.
  /// v3 : unités (table units). v4 : rapports de raid (table reports).
  /// v5 : officiers et compteurs (tables officers, counters).
  /// v6 : files d'attente (table queued_orders).
  /// v7 : événements ponctuels (tables active_effects, story_log).
  /// v8 : champ de débris (colonnes de planets). v9 : bases pirates (table pirate_bases).
  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(research);
        await m.addColumn(buildings, buildings.percent);
      }
      if (from < 3) {
        await m.createTable(units);
      }
      if (from < 4) {
        await m.createTable(reports);
      }
      if (from < 5) {
        await m.createTable(officers);
        await m.createTable(counters);
        // Les raids déjà repoussés comptent pour l'Ingénieur.
        await customStatement(
          "INSERT INTO counters (kind, value) SELECT 'raids_repelled', COUNT(*) FROM reports "
          'WHERE payload LIKE \'%"winner":"defender"%\'',
        );
      }
      if (from < 6) {
        await m.createTable(queuedOrders);
      }
      if (from < 7) {
        await m.createTable(activeEffects);
        await m.createTable(storyLog);
      }
      if (from < 8) {
        await m.addColumn(planets, planets.debrisMetal);
        await m.addColumn(planets, planets.debrisCrystal);
      }
      if (from < 9) {
        await m.createTable(pirateBases);
      }
    },
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
