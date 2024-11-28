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

class _MapaViewState extends State<MapaView> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final MoradorController _moradorController = MoradorController();
  final MapController _mapController = MapController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
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
    _animationController.forward();
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
      padding: const EdgeInsets.all(16.0),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: localizations.translate('search_address'),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.primary,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.my_location,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                onPressed: _getUserLocation,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onSubmitted: _searchAddress,
          ),
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

              // Ponto de destino (morador selecionado)
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
          backgroundColor: colorScheme.surfaceContainerHighest,
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
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: _moradores.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        localizations.translate('no_residents_found'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _moradores.length,
                  itemBuilder: (context, index) {
                    final morador = _moradores[index];
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0, 1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                index * 0.1,
                                (index * 0.1) + 0.5,
                                curve: Curves.easeOut,
                              ),
                            ),
                          ),
                          child: child,
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Hero(
                            tag: 'avatar_${morador.id}',
                            child: _buildAvatar(
                              morador.photoURL,
                              Theme.of(context).colorScheme,
                              morador.nome,
                            ),
                          ),
                          title: Text(
                            morador.nome,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${morador.endereco}, ${morador.numeroCasa}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.phone_outlined,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    morador.telefone,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                      ),
                    );
                  },
                ),
        ),
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
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
