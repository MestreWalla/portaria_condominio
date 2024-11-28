// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';
import '../../services/routing_service.dart';
import '../../models/morador_model.dart';
import '../../localizations/app_localizations.dart';
import '../../controllers/configuracoes_controller.dart';
import '../../controllers/morador_controller.dart';

class MapaView extends StatefulWidget {
  final String? initialAddress;

  const MapaView({
    super.key,
    this.initialAddress,
  });

  @override
  State<MapaView> createState() => _MapaViewState();
}

class _MapaViewState extends State<MapaView> {
  final TextEditingController _searchController = TextEditingController();
  final MoradorController _moradorController = MoradorController();
  final MapController _mapController = MapController();

  final LatLng _currentLocation =
      const LatLng(-22.566451, -47.401524); // Centro de Limeira
  LatLng? _userLocation;
  LatLng? _destination;
  Morador? _destinationMorador;
  List<LatLng> _routePoints = [];
  List<Morador> _moradores = [];
  late loc.Location _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = loc.Location();
    _loadMoradores();
    _getUserLocation();
    
    if (widget.initialAddress != null) {
      // Aguarda um momento para garantir que o mapa está pronto
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _searchController.text = widget.initialAddress!;
          _searchAddress(widget.initialAddress!);
        }
      });
    }
  }

  Future<void> _loadMoradores() async {
    try {
      final moradores = await _moradorController.buscarTodosMoradores();
      if (!mounted) return;
      setState(() {
        _moradores = moradores;
      });
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
      
      setState(() {
        _userLocation = LatLng(locationData.latitude!, locationData.longitude!);
      });
      _mapController.move(_userLocation!, 15);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao obter localização: $e')),
      );
    }
  }

  Future<void> _searchAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (!mounted) return;
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        _destination = LatLng(location.latitude, location.longitude);

        if (_userLocation != null) {
          final routingService = RoutingService();
          final route =
              await routingService.getRoute(_userLocation!, _destination!);

          if (!mounted) return;
          setState(() {
            _routePoints = route;
          });
          _mapController.move(_destination!, 15);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar endereço: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final configController = context.watch<ConfiguracoesController>();
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('map_title')),
      ),
      body: Column(
        children: [
          _buildSearchField(localizations),
          _buildMap(configController),
          _buildMoradorList(localizations, configController),
        ],
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: localizations.translate('search_address'),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _searchAddress(_searchController.text),
          ),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildMap(ConfiguracoesController configController) {
    return Expanded(
      flex: 2,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation,
          initialZoom: 15,
          onTap: (tapPosition, latLng) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.maptiler.com/maps/basic/{z}/{x}/{y}.png?key=F6GzFLzm4QzPil3r48OC',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: [
              // Ponto inicial (localização atual)
              if (_userLocation != null)
                Marker(
                  point: _userLocation!,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.my_location,
                      size: 25,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

              // Marcadores dos moradores
              ..._moradores.map((morador) {
                return Marker(
                  point: _currentLocation,
                  width: 40,
                  height: 40,
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(morador.nome),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (morador.photoURL != null && morador.photoURL!.isNotEmpty)
                                _buildAvatar(morador.photoURL!, Theme.of(context).colorScheme, morador.nome),
                              const SizedBox(height: 8),
                              Text('Endereço: ${morador.endereco}, ${morador.numeroCasa}'),
                              Text('Telefone: ${morador.telefone}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Fechar'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _startRouteToMorador(morador);
                              },
                              child: const Text('Iniciar Rota'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: _buildAvatar(morador.photoURL, Theme.of(context).colorScheme, morador.nome),
                    ),
                  ),
                );
              }).toList(),

              // Ponto de destino
              if (_destination != null && _destinationMorador != null)
                Marker(
                  point: _destination!,
                  width: 40,
                  height: 50,
                  child: Column(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.background,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _buildAvatar(
                            _destinationMorador!.photoURL,
                            Theme.of(context).colorScheme,
                            _destinationMorador!.nome,
                          ),
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 10,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Linha da rota
          if (_routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: _routePoints,
                  color: Theme.of(context).colorScheme.secondary,
                  strokeWidth: 3,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? photoURL, ColorScheme colorScheme, String userName) {
    if (photoURL != null && photoURL.isNotEmpty) {
      try {
        String base64String = photoURL;
        if (photoURL.startsWith('data:image')) {
          base64String = photoURL.split(',')[1];
        }
        base64String = base64String.trim().replaceAll(RegExp(r'[\n\r\s]'), '');
        
        return CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(base64Decode(base64String)),
          backgroundColor: colorScheme.surfaceVariant,
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Erro ao carregar imagem: $exception');
            return;
          },
        );
      } catch (e) {
        debugPrint('Erro ao processar imagem: $e');
        return _buildDefaultAvatar(colorScheme, userName);
      }
    }
    return _buildDefaultAvatar(colorScheme, userName);
  }

  Widget _buildDefaultAvatar(ColorScheme colorScheme, String userName) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: colorScheme.primary,
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMoradorList(
      AppLocalizations localizations, ConfiguracoesController configController) {
    return Expanded(
      child: _moradores.isEmpty
          ? Center(child: Text(localizations.translate('no_residents_found')))
          : ListView.builder(
              itemCount: _moradores.length,
              itemBuilder: (context, index) {
                final morador = _moradores[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: _buildAvatar(morador.photoURL, Theme.of(context).colorScheme, morador.nome),
                    title: Text(
                      morador.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${morador.endereco}, ${morador.numeroCasa}'),
                        Text(
                          morador.telefone,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _showMoradorLocation(morador.endereco),
                          tooltip: 'Mostrar no mapa',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.directions,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          onPressed: () => _startRouteToMorador(morador),
                          tooltip: 'Iniciar rota',
                        ),
                      ],
                    ),
                    onTap: () => _showMoradorLocation(morador.endereco),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showMoradorLocation(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        final morador = _moradores.firstWhere(
          (m) => m.endereco == address,
          orElse: () => _moradores.first,
        );
        
        setState(() {
          _destination = LatLng(location.latitude, location.longitude);
          _destinationMorador = morador;
          _routePoints = []; // Limpa a rota existente
        });

        // Move o mapa para a localização do morador
        _mapController.move(_destination!, 15);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar localização: $e')),
      );
    }
  }

  Future<void> _startRouteToMorador(Morador morador) async {
    try {
      final address = '${morador.endereco}, ${morador.numeroCasa}';
      final locations = await locationFromAddress(address);
      
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _destination = LatLng(location.latitude, location.longitude);
          _destinationMorador = morador;
        });

        if (_userLocation != null) {
          final routingService = RoutingService();
          final route = await routingService.getRoute(_userLocation!, _destination!);

          setState(() {
            _routePoints = route;
          });

          final bounds = LatLngBounds.fromPoints([_userLocation!, _destination!]);
          _mapController.move(bounds.center, 15);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao iniciar rota: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
