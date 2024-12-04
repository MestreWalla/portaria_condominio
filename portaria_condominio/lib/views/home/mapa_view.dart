// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
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
  final FocusNode _searchFocusNode = FocusNode();

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

  Future<List<String>> _getSuggestions(String pattern) async {
    if (pattern.length < 3) return [];

    final patternLower = pattern.toLowerCase();
    List<String> suggestions = [];

    // Busca por nome do morador
    suggestions.addAll(
      _moradores
          .where((morador) => morador.nome.toLowerCase().contains(patternLower))
          .map((morador) => '${morador.nome} - ${morador.endereco}, ${morador.numeroCasa}')
    );

    // Busca por endereço dos moradores
    suggestions.addAll(
      _moradores
          .where((morador) =>
              '${morador.endereco}, ${morador.numeroCasa}'.toLowerCase().contains(patternLower))
          .map((morador) => '${morador.nome} - ${morador.endereco}, ${morador.numeroCasa}')
          .where((suggestion) => !suggestions.contains(suggestion)) // Evita duplicatas
    );

    try {
      // Busca sugestões do Google Places API apenas se não houver sugestões de moradores
      if (suggestions.isEmpty) {
        final locations = await locationFromAddress(pattern);
        suggestions.addAll(
          locations.map((location) => location.toString()).toList(),
        );
      }
    } catch (e) {
      debugPrint('Erro ao buscar sugestões de endereço: $e');
    }

    return suggestions;
  }

  void _handleSuggestionSelected(String suggestion) {
    _searchController.text = suggestion;
    _searchFocusNode.unfocus();

    // Verifica se é um morador ou endereço comum
    final moradorOpt = _moradores
        .where((m) => suggestion.startsWith('${m.nome} - '))
        .firstOrNull;

    if (moradorOpt != null) {
      _startRouteToMorador(moradorOpt);
    } else {
      _searchAddress(suggestion);
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
  Widget build(BuildContext context) {
    final configController = context.watch<ConfiguracoesController>();
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: TypeAheadField<String>(
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: localizations.translate('search_address'),
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            onPressed: () {
                              controller.clear();
                              focusNode.unfocus();
                            },
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.my_location,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          onPressed: _getUserLocation,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                );
              },
              decorationBuilder: (context, child) {
                return Material(
                  elevation: 8,
                  shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.surface,
                  child: child,
                );
              },
              itemBuilder: (context, suggestion) {
                final isMoradorSuggestion = suggestion.contains(' - ');
                final isNameMatch = isMoradorSuggestion && 
                    _moradores.any((m) => suggestion.toLowerCase().startsWith(m.nome.toLowerCase()));

                return ListTile(
                  leading: Icon(
                    isNameMatch ? Icons.person : (isMoradorSuggestion ? Icons.home : Icons.location_on_outlined),
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  title: Text(
                    suggestion,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: isMoradorSuggestion ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: isMoradorSuggestion
                      ? Text(
                          isNameMatch ? 'Morador (nome)' : 'Morador (endereço)',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                          ),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              },
              onSelected: _handleSuggestionSelected,
              suggestionsCallback: _getSuggestions,
              animationDuration: const Duration(milliseconds: 300),
              hideOnEmpty: true,
              hideOnLoading: false,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildMap(configController),
          _buildMoradorList(localizations, configController),
        ],
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
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.my_location,
                      size: 22,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.secondary,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                        width: 2,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                  strokeWidth: 4,
                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  borderColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                  borderStrokeWidth: 6,
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
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(0)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, -4),
                spreadRadius: 2,
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _moradores.length,
                  itemBuilder: (context, index) {
                    final morador = _moradores[index];
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 1),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          elevation: 0,
                          child: InkWell(
                            onTap: () => _startRouteToMorador(morador),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Hero(
                                      tag: 'avatar_${morador.id}',
                                      child: _buildAvatar(
                                        morador.photoURL,
                                        Theme.of(context).colorScheme,
                                        morador.nome,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            morador.nome,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
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
                                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
