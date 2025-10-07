import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/gratitude_entity.dart';
import '../bloc/gratitude_bloc.dart';
import '../bloc/gratitude_event.dart';
import '../bloc/gratitude_state.dart';
import '../widgets/gratitude_marker.dart';

/// Interactive map screen showing gratitude markers
class MapScreen extends StatefulWidget {
  final ValueNotifier<LatLng?>? selectedLocationNotifier;
  final ValueNotifier<bool>? isSelectingLocationNotifier;

  const MapScreen({
    super.key,
    this.selectedLocationNotifier,
    this.isSelectingLocationNotifier,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GratitudeBloc>()..add(const LoadGratitudes()),
      child: Scaffold(
        body: BlocBuilder<GratitudeBloc, GratitudeState>(
          builder: (context, state) {
            return Stack(
              children: [
                _buildMap(context, state),
                if (state is GratitudeLoading)
                  const Center(child: CircularProgressIndicator()),
                if (state is GratitudeError)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<GratitudeBloc>()
                              .add(const RefreshGratitudes()),
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context, GratitudeState state) {
    final gratitudes = state is GratitudeLoaded ? state.gratitudes : <GratitudeEntity>[];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(
          AppConstants.defaultCenter.$1,
          AppConstants.defaultCenter.$2,
        ),
        initialZoom: AppConstants.defaultZoom,
        minZoom: AppConstants.minZoom,
        maxZoom: AppConstants.maxZoom,
        onTap: (tapPosition, point) {
          // If in location selection mode, update the selected location
          if (widget.isSelectingLocationNotifier?.value == true) {
            widget.selectedLocationNotifier?.value = point;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Location selected: ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.ripple',
        ),
        // Gratitude markers
        MarkerLayer(
          markers: gratitudes.map((gratitude) {
            return Marker(
              width: 40,
              height: 40,
              point: LatLng(gratitude.point.$1, gratitude.point.$2),
              child: GratitudeMarker(
                gratitude: gratitude,
                onTap: () => _showGratitudeDetails(context, gratitude),
              ),
            );
          }).toList(),
        ),
        // Selected location marker (when picking location)
        if (widget.selectedLocationNotifier != null)
          ValueListenableBuilder<LatLng?>(
            valueListenable: widget.selectedLocationNotifier!,
            builder: (context, selectedLocation, _) {
              if (selectedLocation == null) return const SizedBox.shrink();
              return MarkerLayer(
                markers: [
                  Marker(
                    width: 50,
                    height: 50,
                    point: selectedLocation,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(50),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  void _showGratitudeDetails(BuildContext context, GratitudeEntity gratitude) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Category chip
                Chip(
                  label: Text(gratitude.category),
                  avatar: const Icon(Icons.category, size: 16),
                ),
                const SizedBox(height: 16),
                // Text
                Text(
                  gratitude.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                // Tags
                if (gratitude.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: gratitude.tags.map((tag) {
                      return Chip(
                        label: Text('#$tag'),
                        labelStyle: const TextStyle(fontSize: 12),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                // Stats
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${gratitude.likesCount}'),
                    const SizedBox(width: 16),
                    Icon(Icons.comment_outlined, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text('${gratitude.repliesCount}'),
                    const Spacer(),
                    Text(
                      '${gratitude.createdAt.day}.${gratitude.createdAt.month}.${gratitude.createdAt.year}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
