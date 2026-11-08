import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/game_controller.dart';
import '../app/save_manager.dart';
import '../core/big_num.dart';
import '../core/economy/offline.dart';
import '../core/number_format.dart';
import 'animation_preview.dart';
import 'cutscene_player.dart';
import 'offline_dialog.dart';
import 'prestige_page.dart';
import 'theme.dart';

const kAppVersion = '0.5.0';

/// Ajustes (spec 9.12). Se abre desde el engranaje.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final st = c.state.settings;
        final f = c.formatter;
        final sample = BigNum.parse('1.5e12');
        return Scaffold(
          appBar: AppBar(title: const Text('Ajustes')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Formato de números',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<NumberFormatMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: NumberFormatMode.shortSuffix,
                    label: Text('K, M, B', key: Key('fmt-shortSuffix')),
                  ),
                  ButtonSegment(
                    value: NumberFormatMode.names,
                    label: Text('Nombres', key: Key('fmt-names')),
                  ),
                  ButtonSegment(
                    value: NumberFormatMode.scientific,
                    label: Text('Científica', key: Key('fmt-scientific')),
                  ),
                ],
                selected: {f.mode},
                onSelectionChanged: (s) => c.setNumberFormat(s.first),
              ),
              const SizedBox(height: 4),
              Text(
                'Ejemplo: ${f.format(sample)}',
                key: const Key('fmt-sample'),
              ),
              const Divider(height: 32),
              Text(
                'Tamaño de letra: ${(st.fontScale * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Slider(
                key: const Key('font-scale'),
                min: 0.85,
                max: 1.6,
                divisions: 15,
                value: st.fontScale,
                onChanged: c.setFontScale,
              ),
              SwitchListTile(
                key: const Key('sound'),
                title: const Text('Música y efectos'),
                subtitle: const Text('El audio llega en F6'),
                value: st.sound,
                onChanged: c.setSound,
              ),
              SwitchListTile(
                key: const Key('vibration'),
                title: const Text('Vibración'),
                value: st.vibration,
                onChanged: c.setVibration,
              ),
              const Divider(height: 32),
              ListTile(
                key: const Key('export'),
                leading: const Icon(Icons.upload),
                title: const Text('Exportar partida'),
                subtitle: const Text('Copia tu partida como texto'),
                onTap: () => _export(context),
              ),
              ListTile(
                key: const Key('import'),
                leading: const Icon(Icons.download),
                title: const Text('Importar partida'),
                subtitle: const Text(
                  'Reemplaza tu partida con un texto exportado',
                ),
                onTap: () => _import(context),
              ),
              ListTile(
                key: const Key('reset'),
                leading: const Icon(
                  Icons.delete_forever,
                  color: Palette.tomato,
                ),
                title: const Text('Reiniciar partida'),
                subtitle: const Text('Borra todo el progreso'),
                onTap: () => _reset(context),
              ),
              const Divider(height: 32),
              const Text(
                'Escenas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final scene in Cutscene.values)
                ListTile(
                  key: Key('scene-${scene.id}'),
                  leading: const Icon(Icons.movie_outlined),
                  title: Text(scene.title),
                  onTap: () => showCutscene(
                    context,
                    scene,
                    sound: c.state.settings.sound,
                  ),
                ),
              if (c.testMode) ...[
                const Divider(height: 32),
                const Text(
                  'Probar animaciones',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Solo en modo de prueba. No cambian tu partida.',
                  style: TextStyle(fontSize: 12),
                ),
                ListTile(
                  key: const Key('preview-centrifuge'),
                  leading: const Icon(Icons.local_laundry_service),
                  title: const Text('Centrifugado'),
                  onTap: () => showCentrifugeAnimation(context, '1.2K'),
                ),
                ListTile(
                  key: const Key('preview-offline'),
                  leading: const Icon(Icons.bedtime),
                  title: const Text('Bienvenida offline'),
                  onTap: () => showOfflineDialog(
                    context,
                    c,
                    f,
                    preview: OfflineReport(
                      gain: BigNum.parse('2.5e6'),
                      secondsAway: 3 * 3600,
                      secondsCounted: 3 * 3600,
                      clockWentBack: false,
                    ),
                  ),
                ),
                ListTile(
                  key: const Key('preview-mascot'),
                  leading: const Icon(Icons.emoji_emotions),
                  title: const Text('Mascota (reposo, salto y celebra)'),
                  onTap: () => showMascotPreview(context),
                ),
              ],
              const Divider(height: 32),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Calcetinópolis'),
                subtitle: Text('Versión $kAppVersion'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _export(BuildContext context) async {
    final text = controller.exportSave();
    if (text == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tu partida'),
        content: SingleChildScrollView(
          child: SelectableText(
            text,
            key: const Key('export-text'),
            style: const TextStyle(fontSize: 11),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Copiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final field = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Importar partida'),
        content: TextField(
          key: const Key('import-field'),
          controller: field,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Pega aquí el texto exportado',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            key: const Key('import-confirm'),
            onPressed: () => Navigator.pop(ctx, field.text),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await controller.importSave(text);
      messenger.showSnackBar(
        const SnackBar(content: Text('Partida importada')),
      );
    } on SaveFormatException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Ese texto no es una partida válida. No se cambió nada.',
          ),
        ),
      );
    }
  }

  Future<void> _reset(BuildContext context) async {
    final field = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('¿Reiniciar partida?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Se borra TODO: negocios, Parejas, Hilvanes y metas. No se puede deshacer.',
              ),
              const SizedBox(height: 12),
              const Text('Escribe REINICIAR para confirmar:'),
              TextField(
                key: const Key('reset-field'),
                controller: field,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
          actions: [
            FilledButton(
              key: const Key('reset-cancel'),
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              key: const Key('reset-confirm'),
              onPressed: field.text.trim().toUpperCase() == 'REINICIAR'
                  ? () => Navigator.pop(ctx, true)
                  : null,
              child: const Text('Reiniciar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) await controller.resetGame();
  }
}
