import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/geo_provider.dart';
import '../../core/theme.dart';
import '../../models/geo_landmark.dart';
import '../../services/geo_service.dart';
import '../../widgets/common.dart';

class GeoScreen extends StatefulWidget {
  const GeoScreen({super.key});

  @override
  State<GeoScreen> createState() => _GeoScreenState();
}

class _GeoScreenState extends State<GeoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final geo = context.read<GeoProvider>();
      if (geo.status == GeoPermissionStatus.notRequested) {
        geo.init();
      }
    });
  }

  void _showQuestDialog(BuildContext context, GeoLandmark landmark) {
    final geo = context.read<GeoProvider>();
    final auth = context.read<AuthProvider>();
    final isDone = geo.completedQuestIds.contains(landmark.id);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.architecture_rounded, color: AppColors.violet),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                landmark.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tag(
              landmark.geometryType,
              color: AppColors.mint,
              icon: Icons.category_outlined,
            ),
            const SizedBox(height: 12),
            Text(
              landmark.description,
              style: const TextStyle(fontSize: 14, color: AppColors.text),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.elevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Геометриялық факт:',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    landmark.mathFact,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.stars_rounded,
                  color: AppColors.mint,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  '+${landmark.bonusPoints} ұпай сыйлыққа',
                  style: const TextStyle(
                    color: AppColors.mint,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Жабу'),
          ),
          FilledButton(
            key: const Key('solve_geo_quest_button'),
            onPressed: isDone
                ? null
                : () async {
                    await geo.completeQuest(landmark, auth);
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '«${landmark.name}» гео-квесті орындалды! +${landmark.bonusPoints} ұпай қосылды.',
                          ),
                          backgroundColor: AppColors.mint.withValues(
                            alpha: 0.9,
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
            child: Text(isDone ? 'Орындалған' : 'Квестті тапсыру'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final geo = context.watch<GeoProvider>();
    final auth = context.watch<AuthProvider>();

    return ListView(
      key: const Key('geo_screen_list_view'),
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
      children: [
        const ScreenHeading(
          eyebrow: 'Күрделі мобильді функция',
          title: 'Гео-локация және карта',
          subtitle:
              'Геометрияны шынайы сәулет нысандары мен GPS арқылы зерттеңіз.',
        ),

        // Permission & State Handling
        if (geo.status == GeoPermissionStatus.notRequested)
          _buildNotRequestedCard(context, geo)
        else if (geo.status == GeoPermissionStatus.serviceDisabled)
          _buildServiceDisabledCard(context, geo)
        else if (geo.status == GeoPermissionStatus.denied)
          _buildDeniedCard(context, geo)
        else if (geo.status == GeoPermissionStatus.deniedForever)
          _buildDeniedForeverCard(context, geo)
        else if (geo.status == GeoPermissionStatus.granted)
          _buildGrantedContent(context, geo, auth),
      ],
    );
  }

  Widget _buildNotRequestedCard(BuildContext context, GeoProvider geo) {
    return SurfaceCard(
      key: const Key('geo_permission_not_requested_card'),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_searching_rounded,
              size: 32,
              color: AppColors.violet,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Геолокация рұқсаты қажет',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Жақын маңдағы геометриялық сәулет нысандарын (сфера, пирамида, гиперболоид) анықтау үшін GPS геолокация рұқсатын беріңіз.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const Key('geo_request_permission_button'),
            onPressed: geo.isLoading ? null : geo.requestPermission,
            icon: const Icon(Icons.my_location_rounded, size: 18),
            label: const Text('Рұқсат беру'),
          ),
          const SizedBox(height: 10),
          _buildSimulationFallback(geo),
        ],
      ),
    );
  }

  Widget _buildServiceDisabledCard(BuildContext context, GeoProvider geo) {
    return SurfaceCard(
      key: const Key('geo_service_disabled_card'),
      child: Column(
        children: [
          const Icon(
            Icons.location_off_rounded,
            size: 48,
            color: AppColors.warning,
          ),
          const SizedBox(height: 14),
          const Text(
            'GPS қызметі өшірулі',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Құрылғының баптауларында геолокация қызметі (GPS) қосылмаған. GPS-ті іске қосыңыз.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('geo_open_settings_button'),
            onPressed: geo.openLocationSettings,
            icon: const Icon(Icons.settings_rounded, size: 18),
            label: const Text('GPS баптауларын ашу'),
          ),
          const SizedBox(height: 10),
          _buildSimulationFallback(geo),
        ],
      ),
    );
  }

  Widget _buildDeniedCard(BuildContext context, GeoProvider geo) {
    return SurfaceCard(
      key: const Key('geo_permission_denied_card'),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.gpp_bad_rounded,
              size: 30,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Геолокацияға рұқсат берілмеді',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Сіз рұқсатты қабылдамадыңыз. Геометриялық картамен жұмыс істеу үшін қайта рұқсат беріңіз.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('geo_retry_permission_button'),
            onPressed: geo.isLoading ? null : geo.requestPermission,
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: const Text('Қайта сұрау'),
          ),
          const SizedBox(height: 10),
          _buildSimulationFallback(geo),
        ],
      ),
    );
  }

  Widget _buildDeniedForeverCard(BuildContext context, GeoProvider geo) {
    return SurfaceCard(
      key: const Key('geo_permission_denied_forever_card'),
      child: Column(
        children: [
          const Icon(
            Icons.lock_person_rounded,
            size: 48,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 14),
          const Text(
            'Рұқсат біржола бұғатталған',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Геолокацияға қолжетімділік параметрлерде жабылған. Оны қосу үшін жүйе баптауларына өтіңіз.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('geo_open_app_settings_button'),
            onPressed: geo.openAppSettings,
            icon: const Icon(Icons.settings_applications_rounded, size: 18),
            label: const Text('Қосымша параметрлерін ашу'),
          ),
          const SizedBox(height: 10),
          _buildSimulationFallback(geo),
        ],
      ),
    );
  }

  Widget _buildSimulationFallback(GeoProvider geo) {
    return TextButton.icon(
      key: const Key('geo_simulate_astana_button'),
      onPressed: () {
        geo.simulateCoordinates(51.1283, 71.4305);
      },
      icon: const Icon(
        Icons.travel_explore_rounded,
        size: 16,
        color: AppColors.mint,
      ),
      label: const Text(
        'Сынақ үшін: Астана координаттарын симуляциялау',
        style: TextStyle(color: AppColors.mint, fontSize: 12),
      ),
    );
  }

  Widget _buildGrantedContent(
    BuildContext context,
    GeoProvider geo,
    AuthProvider auth,
  ) {
    final coords = geo.coordinates;
    final nearest = geo.nearestLandmark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live Coordinates Card
        SurfaceCard(
          key: const Key('geo_live_coordinates_card'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.gps_fixed_rounded,
                      color: AppColors.mint,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GPS Геолокация белсенді',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Нақты уақыттағы координаттар',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (geo.isSimulated)
                    const Tag(
                      'Симуляция',
                      color: AppColors.warning,
                      icon: Icons.tune_rounded,
                    )
                  else
                    const Tag(
                      'GPS LIVE',
                      color: AppColors.mint,
                      icon: Icons.sensors_rounded,
                    ),
                  const SizedBox(width: 6),
                  IconButton(
                    key: const Key('geo_refresh_coordinates_button'),
                    icon: geo.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.refresh_rounded,
                            size: 20,
                            color: AppColors.muted,
                          ),
                    onPressed: geo.isLoading ? null : geo.refresh,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (coords != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: _CoordBadge(
                        label: 'Ендік (Latitude)',
                        value: '${coords.latitude.toStringAsFixed(4)}° N',
                        icon: Icons.north_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CoordBadge(
                        label: 'Бойлық (Longitude)',
                        value: '${coords.longitude.toStringAsFixed(4)}° E',
                        icon: Icons.east_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _CoordBadge(
                        label: 'Биіктік (Altitude)',
                        value: '${coords.altitude.toStringAsFixed(1)} м',
                        icon: Icons.terrain_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CoordBadge(
                        label: 'Дәлдік (Accuracy)',
                        value: '±${coords.accuracy.toStringAsFixed(1)} м',
                        icon: Icons.track_changes_rounded,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Координаттарды жүктеуде...',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              // City quick simulation picker
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Қаланы ауыстыру:',
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                  ActionChip(
                    label: const Text('Астана', style: TextStyle(fontSize: 11)),
                    onPressed: () => geo.simulateCoordinates(51.1283, 71.4305),
                  ),
                  ActionChip(
                    label: const Text('Алматы', style: TextStyle(fontSize: 11)),
                    onPressed: () => geo.simulateCoordinates(43.2241, 76.9248),
                  ),
                  ActionChip(
                    label: const Text(
                      'Париж (Лувр)',
                      style: TextStyle(fontSize: 11),
                    ),
                    onPressed: () => geo.simulateCoordinates(48.8606, 2.3376),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Nearest landmark card
        if (coords != null && nearest != null) ...[
          SurfaceCard(
            key: const Key('geo_nearest_landmark_card'),
            color: AppColors.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.near_me_rounded,
                      color: AppColors.violet,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ең жақын нысан',
                        style: TextStyle(
                          color: AppColors.violet,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tag(
                      nearest.formatDistanceTo(
                        coords.latitude,
                        coords.longitude,
                      ),
                      color: AppColors.mint,
                      icon: Icons.straighten_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  nearest.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${nearest.city} • ${nearest.geometryType}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  nearest.mathFact,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  key: const Key('nearest_open_quest_button'),
                  onPressed: () => _showQuestDialog(context, nearest),
                  icon: const Icon(Icons.explore_rounded, size: 18),
                  label: Text(
                    geo.completedQuestIds.contains(nearest.id)
                        ? 'Квест орындалды (Қайта көру)'
                        : 'Гео-квестті бастау (+${nearest.bonusPoints} ұпай)',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Section title
        Row(
          children: [
            const Expanded(
              child: Text(
                'Сәулет геометриясы каталогы',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Tag(
              '${geo.completedQuestIds.length}/${geo.landmarks.length} шешілді',
              color: AppColors.blue,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Landmarks list
        for (final landmark in geo.landmarks) ...[
          _LandmarkTile(
            landmark: landmark,
            userCoords: coords,
            isCompleted: geo.completedQuestIds.contains(landmark.id),
            onTap: () => _showQuestDialog(context, landmark),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CoordBadge extends StatelessWidget {
  const _CoordBadge({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LandmarkTile extends StatelessWidget {
  const _LandmarkTile({
    required this.landmark,
    required this.userCoords,
    required this.isCompleted,
    required this.onTap,
  });

  final GeoLandmark landmark;
  final GeoCoordinates? userCoords;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final distanceText = userCoords != null
        ? landmark.formatDistanceTo(userCoords!.latitude, userCoords!.longitude)
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isCompleted
                ? AppColors.mint.withValues(alpha: 0.5)
                : AppColors.line.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.mint.withValues(alpha: 0.15)
                    : AppColors.elevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.place_outlined,
                color: isCompleted ? AppColors.mint : AppColors.violet,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    landmark.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${landmark.city} • ${landmark.geometryType}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (distanceText != null)
              Tag(
                distanceText,
                color: AppColors.blue,
                icon: Icons.navigation_outlined,
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
