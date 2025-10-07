import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/models/result.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/gratitude_category.dart';
import '../../domain/usecases/upload_photo.dart';
import '../bloc/create_gratitude_bloc.dart';
import '../bloc/create_gratitude_event.dart';
import '../bloc/create_gratitude_state.dart';
import '../bloc/gratitude_bloc.dart';
import '../bloc/gratitude_event.dart';

/// Bottom sheet for adding gratitude with map in background
/// 
/// Shows half-screen form with ability to select location on map
/// User can toggle map selection mode and tap on map to pick location
Future<void> showAddGratitudeBottomSheet(
  BuildContext context, {
  required ValueNotifier<LatLng?> selectedLocationNotifier,
  required ValueNotifier<bool> isSelectingLocationNotifier,
  LatLng? initialLocation,
}) async {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    builder: (context) => AddGratitudeBottomSheet(
      initialLocation: initialLocation,
      selectedLocationNotifier: selectedLocationNotifier,
      isSelectingLocationNotifier: isSelectingLocationNotifier,
    ),
  );
}

class AddGratitudeBottomSheet extends StatefulWidget {
  final ValueNotifier<LatLng?> selectedLocationNotifier;
  final ValueNotifier<bool> isSelectingLocationNotifier;
  final LatLng? initialLocation;

  const AddGratitudeBottomSheet({
    required this.selectedLocationNotifier,
    required this.isSelectingLocationNotifier,
    this.initialLocation,
    super.key,
  });

  @override
  State<AddGratitudeBottomSheet> createState() => _AddGratitudeBottomSheetState();
}

class _AddGratitudeBottomSheetState extends State<AddGratitudeBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _tagsController = TextEditingController();
  final _imagePicker = ImagePicker();

  GratitudeCategory _selectedCategory = GratitudeCategory.other;
  LatLng? _selectedLocation;
  bool _isLoadingLocation = false;
  String? _selectedPhotoPath;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    
    // Listen to selected location changes from map
    widget.selectedLocationNotifier.addListener(_onLocationSelected);
    
    // Initialize selectedLocationNotifier with current location
    if (_selectedLocation != null) {
      widget.selectedLocationNotifier.value = _selectedLocation;
    }
    
    if (_selectedLocation == null) {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    widget.selectedLocationNotifier.removeListener(_onLocationSelected);
    _textController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _onLocationSelected() {
    setState(() {
      _selectedLocation = widget.selectedLocationNotifier.value;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        // Use default location
        setState(() {
          _selectedLocation = LatLng(
            AppConstants.defaultCenter.$1,
            AppConstants.defaultCenter.$2,
          );
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
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _selectedLocation = LatLng(
          AppConstants.defaultCenter.$1,
          AppConstants.defaultCenter.$2,
        );
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedPhotoPath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhotoPath = null;
    });
  }

  void _submitForm(String userId, CreateGratitudeBloc createBloc) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is required')),
      );
      return;
    }

    // Parse tags from comma-separated string to List<String>
    final tagsString = _tagsController.text.trim();
    final tagsList = tagsString.isEmpty
        ? <String>[]
        : tagsString
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

    // Upload photo if selected
    String? photoUrl;
    if (_selectedPhotoPath != null) {
      final uploadPhotoUseCase = sl<UploadPhotoUseCase>();
      final result = await uploadPhotoUseCase(_selectedPhotoPath!);
      
      if (result.isError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo upload failed: ${result.failure!.userMessage}')),
        );
        return;
      }
      
      photoUrl = result.data;
    }

    createBloc.add(
      SubmitGratitude(
        userId: userId,
        text: _textController.text.trim(),
        category: _selectedCategory.value, // Use enum value (HEALTH, NATURE, etc.)
        tags: tagsList,
        point: (_selectedLocation!.latitude, _selectedLocation!.longitude),
        photoUrl: photoUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    return BlocProvider(
      create: (_) => sl<CreateGratitudeBloc>(),
      child: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: BlocConsumer<CreateGratitudeBloc, CreateGratitudeState>(
          listener: (context, state) {
            if (state is CreateGratitudeSuccess) {
              // Refresh gratitudes list
              try {
                context.read<GratitudeBloc>().add(const RefreshGratitudes());
              } catch (e) {
                // GratitudeBloc not available
              }

              // Reset notifiers when closing
              widget.isSelectingLocationNotifier.value = false;
              widget.selectedLocationNotifier.value = null;

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

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: mediaQuery.size.height * 0.5 + bottomPadding,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface.withAlpha(25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Add Gratitude',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            // Reset notifiers when closing
                            widget.isSelectingLocationNotifier.value = false;
                            widget.selectedLocationNotifier.value = null;
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),

                  // Form content
                  Expanded(
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        if (authState is! Authenticated) {
                          return const Center(
                            child: Text('Please sign in to add gratitude'),
                          );
                        }

                        return SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: bottomPadding + 16,
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Map selection hint
                                ValueListenableBuilder<bool>(
                                  valueListenable: widget.isSelectingLocationNotifier,
                                  builder: (context, isSelecting, _) {
                                    if (!isSelecting) return const SizedBox.shrink();
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.touch_app,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Tap on the map behind to select location',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),

                                // Gratitude text
                                TextFormField(
                                  controller: _textController,
                                  decoration: const InputDecoration(
                                    labelText: 'What are you grateful for?',
                                    hintText: 'Share your gratitude...',
                                    border: OutlineInputBorder(),
                                  ),
                                  maxLines: 3,
                                  maxLength: 500,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter your gratitude';
                                    }
                                    if (value.trim().length < 10) {
                                      return 'Gratitude must be at least 10 characters';
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
                                      child: Row(
                                        children: [
                                          Text(category.emoji),
                                          const SizedBox(width: 8),
                                          Text(category.label),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: isSubmitting
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() {
                                              _selectedCategory = value;
                                            });
                                          }
                                        },
                                ),
                                const SizedBox(height: 16),

                                // Tags
                                TextFormField(
                                  controller: _tagsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Tags (optional)',
                                    hintText: 'family, health, nature',
                                    border: OutlineInputBorder(),
                                    helperText: 'Separate tags with commas',
                                  ),
                                  enabled: !isSubmitting,
                                ),
                                const SizedBox(height: 16),

                                // Photo picker
                                if (_selectedPhotoPath != null) ...[
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          File(_selectedPhotoPath!),
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: IconButton(
                                          onPressed: _removePhoto,
                                          icon: const Icon(Icons.close),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black54,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ] else ...[
                                  OutlinedButton.icon(
                                    onPressed: isSubmitting ? null : _pickPhoto,
                                    icon: const Icon(Icons.add_photo_alternate),
                                    label: const Text('Add Photo (optional)'),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Location info with select button
                                ValueListenableBuilder<bool>(
                                  valueListenable: widget.isSelectingLocationNotifier,
                                  builder: (context, isSelecting, _) {
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Current location display
                                        ValueListenableBuilder<LatLng?>(
                                          valueListenable: widget.selectedLocationNotifier,
                                          builder: (context, selectedLoc, _) {
                                            final displayLocation = selectedLoc ?? _selectedLocation;
                                            return Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isSelecting
                                                    ? Theme.of(context).colorScheme.primaryContainer
                                                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(8),
                                                border: isSelecting
                                                    ? Border.all(
                                                        color: Theme.of(context).colorScheme.primary,
                                                        width: 2,
                                                      )
                                                    : null,
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.location_on,
                                                        size: 20,
                                                        color: isSelecting
                                                            ? Theme.of(context).colorScheme.primary
                                                            : Theme.of(context).colorScheme.onSurface,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          _isLoadingLocation
                                                              ? 'Getting location...'
                                                              : displayLocation != null
                                                                  ? '${displayLocation.latitude.toStringAsFixed(4)}, ${displayLocation.longitude.toStringAsFixed(4)}'
                                                                  : 'No location selected',
                                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                                fontWeight: isSelecting ? FontWeight.bold : FontWeight.normal,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                              if (isSelecting) ...[
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.touch_app,
                                                      size: 16,
                                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Tap on the map to select location',
                                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // Select location button
                                        if (!isSelecting)
                                          OutlinedButton.icon(
                                            onPressed: isSubmitting
                                                ? null
                                                : () {
                                                    setState(() {
                                                      widget.isSelectingLocationNotifier.value = true;
                                                    });
                                                    // Minimize keyboard
                                                    FocusScope.of(context).unfocus();
                                                    
                                                    // Set initial location for marker
                                                    if (_selectedLocation != null) {
                                                      widget.selectedLocationNotifier.value = _selectedLocation;
                                                    }
                                                    
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('👆 Tap on the map behind to select location'),
                                                        duration: Duration(seconds: 3),
                                                        behavior: SnackBarBehavior.floating,
                                                      ),
                                                    );
                                                  },
                                            icon: const Icon(Icons.edit_location),
                                            label: const Text('Select Location on Map'),
                                          )
                                        else
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      widget.isSelectingLocationNotifier.value = false;
                                                    });
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('✓ Location selection complete'),
                                                        duration: Duration(seconds: 1),
                                                        behavior: SnackBarBehavior.floating,
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.check),
                                                  label: const Text('Done'),
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                                    side: BorderSide(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      widget.isSelectingLocationNotifier.value = false;
                                                      // Don't update location, keep the old one
                                                    });
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text('Selection cancelled'),
                                                        duration: Duration(seconds: 1),
                                                        behavior: SnackBarBehavior.floating,
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.close),
                                                  label: const Text('Cancel'),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),

                                // Submit button
                                FilledButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () => _submitForm(
                                            authState.user.$id,
                                            context.read<CreateGratitudeBloc>(),
                                          ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: isSubmitting
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text('Share Gratitude'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
