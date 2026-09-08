import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/report_service.dart';
import '../../widgets/motion.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final title = TextEditingController();
  final desc = TextEditingController();
  final location = TextEditingController();
  final _shake = ShakeController();
  String category = 'Theft';
  DateTime incident = DateTime.now();
  File? image;
  bool loading = false;
  bool fetchingLocation = false;
  double? latitude;
  double? longitude;
  MapController? _mapController;

  final categories = [
    'Theft',
    'Robbery',
    'Assault',
    'Vandalism',
    'Suspicious Activity',
    'Fire',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => fetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Please enable GPS / Location services on your phone.'),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Text('Location permission was denied.'),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Location permission is permanently denied. Please enable it in App Settings.'),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });

      _mapController?.move(LatLng(latitude!, longitude!), 15.0);

      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            if (p.street != null && p.street!.isNotEmpty) p.street,
            if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality,
          ];
          final addr = parts.join(', ');
          location.text = addr.isNotEmpty ? addr : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        } else {
          location.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }
      } catch (_) {
        location.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(behavior: SnackBarBehavior.floating, content: Text('Error getting location: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => fetchingLocation = false);
    }
  }

  Future<void> submit() async {
    if (title.text.trim().isEmpty || desc.text.trim().isEmpty || location.text.trim().isEmpty) {
      _shake.shake();
      return;
    }
    setState(() => loading = true);
    try {
      String? url;
      if (image != null) url = await ReportService().uploadImage(image!);
      await ReportService().createReport(
        title: title.text.trim(),
        description: desc.text.trim(),
        category: category,
        location: location.text.trim(),
        incidentAt: incident,
        imageUrl: url,
        latitude: latitude,
        longitude: longitude,
      );
      if (mounted) {
        await showSuccessOverlay(context, message: 'Report submitted successfully.');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(behavior: SnackBarBehavior.floating, content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Incident')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Incident title')),
          const SizedBox(height: 12),
          TextField(
            controller: desc,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: category,
            items: categories.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
            onChanged: (x) => setState(() => category = x!),
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          TextField(
            controller: location,
            decoration: InputDecoration(
              labelText: 'Location / Address',
              hintText: 'e.g. 12 Oak Street or tap GPS icon',
              suffixIcon: fetchingLocation
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.my_location, color: Color(0xFF123B5D)),
                      tooltip: 'Use Current GPS Location',
                      onPressed: _fetchCurrentLocation,
                    ),
            ),
          ),
          if (latitude != null && longitude != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(latitude!, longitude!),
                        initialZoom: 15.0,
                        onTap: (tapPosition, point) {
                          setState(() {
                            latitude = point.latitude;
                            longitude = point.longitude;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.communitywatch.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(latitude!, longitude!),
                              width: 36,
                              height: 36,
                              child: const Icon(
                                Icons.location_on,
                                color: Color(0xFFD32F2F),
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Tap map to adjust pin',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Incident time: ${incident.toLocal()}'),
            trailing: MotionIconButton(
              icon: Icons.calendar_month,
              tooltip: 'Pick date',
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDate: incident,
                );
                if (d != null) {
                  setState(() => incident = DateTime(d.year, d.month, d.day, incident.hour, incident.minute));
                }
              },
            ),
          ),
          AnimatedSwitcher(
            duration: Motion.normal,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SizeTransition(sizeFactor: anim, child: child),
            ),
            child: image != null
                ? Padding(
                    key: ValueKey(image!.path),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(image!, height: 180, fit: BoxFit.cover, width: double.infinity),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          MotionButton(
            label: 'Add evidence image',
            icon: Icons.image_outlined,
            variant: MotionButtonVariant.outlined,
            onPressed: () async {
              final x = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (x != null) setState(() => image = File(x.path));
            },
          ),
          const SizedBox(height: 18),
          Shake(
            controller: _shake,
            child: MotionButton(
              label: 'Submit Report',
              loading: loading,
              onPressed: loading ? null : submit,
            ),
          ),
        ],
      ),
    );
  }
}
