import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/gratitude_category.dart';
import '../bloc/create_gratitude_bloc.dart';
import '../bloc/create_gratitude_event.dart';
import '../bloc/create_gratitude_state.dart';
import '../bloc/gratitude_bloc.dart';
import '../bloc/gratitude_event.dart';

/// Add gratitude form screen
class AddGratitudeScreen extends StatefulWidget {
  final (double, double)? initialLocation;

  const AddGratitudeScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<AddGratitudeScreen> createState() => _AddGratitudeScreenState();
}

class _AddGratitudeScreenState extends State<AddGratitudeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _tagsController = TextEditingController();

  GratitudeCategory _selectedCategory = GratitudeCategory.other;
  (double, double)? _selectedLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation == null) {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          setState(() {
            _selectedLocation = AppConstants.defaultCenter;
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied forever. Please enable in settings.'),
            ),
          );
        }
        setState(() {
          _selectedLocation = AppConstants.defaultCenter;
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _selectedLocation = (position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _selectedLocation = AppConstants.defaultCenter;
        _isLoadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  void _submitForm(String userId) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is required')),
      );
      return;
    }

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    context.read<CreateGratitudeBloc>().add(
          SubmitGratitude(
            userId: userId,
            text: _textController.text.trim(),
            category: _selectedCategory.value,
            tags: tags,
            point: _selectedLocation!,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CreateGratitudeBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Gratitude'),
        ),
        body: BlocConsumer<CreateGratitudeBloc, CreateGratitudeState>(
          listener: (context, state) {
            if (state is CreateGratitudeSuccess) {
              // Refresh gratitudes list (try to access GratitudeBloc if available)
              try {
                context.read<GratitudeBloc>().add(const RefreshGratitudes());
              } catch (e) {
                // GratitudeBloc not available in context, skip refresh
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gratitude added successfully! 🎉')),
              );
              Navigator.of(context).pop();
            } else if (state is CreateGratitudeError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            final isSubmitting = state is CreateGratitudeSubmitting;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Text field
                    TextFormField(
                      controller: _textController,
                      maxLines: 5,
                      maxLength: AppConstants.maxGratitudeTextLength,
                      decoration: const InputDecoration(
                        labelText: 'What are you grateful for?',
                        hintText: 'Share your gratitude...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your gratitude';
                        }
                        if (value.trim().length < 10) {
                          return 'Please enter at least 10 characters';
                        }
                        return null;
                      },
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 16),

                    // Category selector
                    DropdownButtonFormField<GratitudeCategory>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: GratitudeCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.label),
                        );
                      }).toList(),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _selectedCategory = value);
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // Tags field
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (optional)',
                        hintText: 'kindness, help, support',
                        helperText: 'Separate tags with commas',
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isSubmitting,
                    ),
                    const SizedBox(height: 16),

                    // Location info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Location',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_isLoadingLocation)
                              const Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Getting location...'),
                                ],
                              )
                            else if (_selectedLocation != null)
                              Text(
                                'Lat: ${_selectedLocation!.$1.toStringAsFixed(4)}, '
                                'Lng: ${_selectedLocation!.$2.toStringAsFixed(4)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            else
                              const Text('No location selected'),
                            if (!_isLoadingLocation && !isSubmitting)
                              TextButton.icon(
                                onPressed: _getCurrentLocation,
                                icon: const Icon(Icons.my_location, size: 16),
                                label: const Text('Update location'),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit button
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        if (authState is! Authenticated) {
                          return const Text('User not authenticated');
                        }

                        return FilledButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () => _submitForm(authState.user.$id),
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(isSubmitting ? 'Submitting...' : 'Share Gratitude'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
