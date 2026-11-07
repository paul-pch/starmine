import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/game_data.dart';
import '../format.dart';
import '../game_controller.dart';
import '../visuals.dart';
import '../widgets/combat_stats.dart';
import '../widgets/info_button.dart';

/// Vitesse de jeu, sauvegarde (presse-papiers), reset, permissions.
class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key, required this.controller});

  final GameController controller;

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool? _exact;

  GameController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _checkExact();
  }

  Future<void> _checkExact() async {
    final exact = await _c.notifier.canScheduleExact();
    if (mounted) setState(() => _exact = exact);
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _export() async {
    final json = await _c.exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    _snack('Sauvegarde copiée dans le presse-papiers (${json.length} caractères)');
  }

  Future<void> _import() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      _snack('Presse-papiers vide');
      return;
    }
    if (!await _confirm('Importer la sauvegarde ?', 'La partie en cours sera remplacée.')) return;
    try {
      await _c.importJson(text);
      _snack('Sauvegarde importée');
    } on FormatException catch (e) {
      _snack('Import impossible : ${e.message}');
    }
  }

  Future<void> _reset() async {
    if (!await _confirm('Nouvelle partie ?', 'La partie en cours sera effacée.')) return;
    await _c.reset();
    _snack('Nouvelle partie');
  }

  /// Flottes pirates de test, du raid d'éclaireurs à l'armada.
  static const _presets = <String, Map<UnitKind, int>>{
    'Éclaireurs : 5 chasseurs légers': {UnitKind.lightFighter: 5},
    'Patrouille : 15 chasseurs légers, 5 lourds': {
      UnitKind.lightFighter: 15,
      UnitKind.heavyFighter: 5,
    },
    'Escadre : 30 chasseurs légers, 8 croiseurs': {UnitKind.lightFighter: 30, UnitKind.cruiser: 8},
    'Armada : 20 croiseurs, 10 vaisseaux de bataille': {
      UnitKind.cruiser: 20,
      UnitKind.battleship: 10,
    },
  };

  Future<void> _simulate() async {
    final fleet = await showModalBottomSheet<Map<UnitKind, int>>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in _presets.entries)
              ListTile(title: Text(e.key), onTap: () => Navigator.pop(context, e.value)),
          ],
        ),
      ),
    );
    if (fleet == null || !mounted) return;
    await SimulationSheet.show(context, _c, fleet);
  }

  Future<void> _requestExact() async {
    await _c.notifier.requestExact();
    await _checkExact();
  }

  @override
  Widget build(BuildContext context) {
    final planet = _c.state.planet;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        ListTile(
          title: const Text('Vitesse de jeu'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 1, label: Text('×1')),
                ButtonSegment(value: 10, label: Text('×10')),
                ButtonSegment(value: 100, label: Text('×100')),
              ],
              selected: {_c.speed},
              onSelectionChanged: (s) => _c.setSpeed(s.single),
            ),
          ),
        ),
        ListTile(
          title: const Text('Ambiance'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SegmentedButton<Ambiance>(
              segments: [
                for (final a in Ambiance.values) ButtonSegment(value: a, label: Text(a.label)),
              ],
              selected: {_c.ambiance},
              onSelectionChanged: (s) => _c.setAmbiance(s.single),
            ),
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: const Text('Exporter la sauvegarde'),
          subtitle: const Text('JSON copié dans le presse-papiers'),
          onTap: _export,
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Importer une sauvegarde'),
          subtitle: const Text('Depuis le presse-papiers'),
          onTap: _import,
        ),
        ListTile(
          leading: const Icon(Icons.gps_fixed),
          title: const Text('Simulateur de combat'),
          subtitle: const Text('100 batailles d’une flotte type contre tes défenses, sans effet'),
          trailing: const InfoButton(
            title: 'Simulateur de combat',
            body:
                'Joue une bataille selon les règles OGame : 6 rounds au plus, tir rapide, '
                'boucliers régénérés à chaque round, 70 % des défenses détruites reconstruites. '
                'Le résultat varie d’une simulation à l’autre : relance pour te faire une idée.',
          ),
          onTap: _simulate,
        ),
        ListTile(
          leading: const Icon(Icons.warning_amber_rounded),
          title: const Text('Raid pirate maintenant'),
          subtitle: Text(
            'La prochaine flotte est détectée tout de suite · tes points : '
            '${fmtAmount(_c.points)} · base des raids : ${fmtAmount(_c.economyPoints)}',
          ),
          onTap: () async {
            await _c.raidNow();
            _snack('Flotte pirate détectée');
          },
        ),
        ListTile(
          leading: const Icon(Icons.auto_stories_outlined),
          title: const Text('Événement maintenant'),
          subtitle: const Text('Le prochain événement ponctuel survient tout de suite'),
          onTap: () async {
            await _c.storyNow();
            _snack(_c.pendingChoice != null ? 'Décision attendue' : 'Événement survenu');
          },
        ),
        ListTile(
          leading: const Icon(Icons.restart_alt),
          title: const Text('Nouvelle partie'),
          onTap: _reset,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.alarm),
          title: const Text('Notifications à l’heure exacte'),
          subtitle: Text(switch (_exact) {
            null => 'Vérification…',
            true => 'Autorisées',
            false => 'Non autorisées : décalage possible de quelques minutes',
          }),
          trailing: _exact == false
              ? TextButton(onPressed: _requestExact, child: const Text('Autoriser'))
              : null,
        ),
        const Divider(),
        ListTile(
          title: const Text('Planète'),
          subtitle: Text('Dernière mise à jour ${planet.lastUpdate.toLocal()}'),
        ),
      ],
    );
  }
}
