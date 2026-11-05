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

@DriftDatabase(tables: [Planets, Buildings, Research, Events, Meta])
class StarmineDatabase extends _$StarmineDatabase {
  StarmineDatabase(super.executor);

  /// Base sur le téléphone (dossier de l'app).
  factory StarmineDatabase.open() => StarmineDatabase(driftDatabase(name: 'starmine'));

  /// v1 : V0. v2 : technologies (table research) et réglages de production.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(research);
        await m.addColumn(buildings, buildings.percent);
      }
    },
    beforeOpen: (details) => customStatement('PRAGMA foreign_keys = ON'),
  );
}
