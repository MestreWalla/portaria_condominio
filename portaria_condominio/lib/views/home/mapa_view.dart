import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import '../../controllers/morador_controller.dart';
import '../../models/morador_model.dart';

class MapaView extends StatefulWidget {
  const MapaView({super.key});

  @override
  State<MapaView> createState() => _MapaViewState();
}

class _MapaViewState extends State<MapaView> {
  final TextEditingController _searchController = TextEditingController();
  final MoradorController _moradorController = MoradorController();
  final MapController _mapController = MapController();

  LatLng _currentLocation =
      const LatLng(-22.566451, -47.401524); // Centro de Limeira
  LatLng? _userLocation;
  LatLng? _destination;
  List<LatLng> _routePoints = [];
  List<Morador> _moradores = [];
  late loc.Location _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = loc.Location();
    _loadMoradores();
    _getUserLocation();
  }

  Future<void> _loadMoradores() async {
    try {
      final moradores = await _moradorController.buscarTodosMoradores();
      setState(() {
        _moradores = moradores;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar moradores: $e')),
      );
    }
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await _locationService.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationService.requestService();
        if (!serviceEnabled) {
          throw Exception('O serviço de localização não está habilitado.');
        }
      }

      final hasPermission = await _locationService.hasPermission();
      if (hasPermission == loc.PermissionStatus.denied) {
        final permissionGranted = await _locationService.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          throw Exception('Permissão de localização não concedida.');
        }
      }

      final locationData = await _locationService.getLocation();
      setState(() {
        _userLocation = LatLng(locationData.latitude!, locationData.longitude!);
      });
      _mapController.move(_userLocation!, 15);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter localização: $e')),
      );
    }
  }

  Future<void> _searchAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _destination = LatLng(location.latitude, location.longitude);
          _routePoints = [_userLocation!, _destination!];
        });
        _mapController.move(_destination!, 18);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar endereço: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildMap(),
          _buildMoradorList(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar endereço...',
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _searchAddress(_searchController.text),
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Expanded(
      flex: 2,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation,
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.maptiler.com/maps/basic/{z}/{x}/{y}.png?key=F6GzFLzm4QzPil3r48OC',
            subdomains: const ['a', 'b', 'c'],
          ),
          if (_userLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _userLocation!,
                  child: const Icon(
                    Icons.my_location,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          if (_destination != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: _destination!,
                  child: const Icon(
                    Icons.location_on,
                    size: 40,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          if (_routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  color: Colors.blue,
                  strokeWidth: 5.0,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMoradorList() {
    return Expanded(
      child: _moradores.isEmpty
          ? const Center(child: Text('Nenhum morador encontrado.'))
          : ListView.builder(
              itemCount: _moradores.length,
              itemBuilder: (context, index) {
                final morador = _moradores[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(morador.nome),
                  subtitle: Text(morador.endereco),
                  onTap: () => _searchAddress(morador.endereco),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
