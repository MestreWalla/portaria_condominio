import 'package:flutter/material.dart';
import '../../models/registro_acesso_model.dart';
import '../../controllers/registro_acesso_controller.dart';
import '../../localizations/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class AccessRecordsView extends StatefulWidget {
  const AccessRecordsView({super.key});

  @override
  State<AccessRecordsView> createState() => _AccessRecordsViewState();
}

class _AccessRecordsViewState extends State<AccessRecordsView> {
  final RegistroAcessoController _controller = RegistroAcessoController();
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('access_records')),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedDateRange != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _selectDateRange,
            tooltip: localizations.translate('filter_by_date'),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportData,
            tooltip: localizations.translate('share_records'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: localizations.translate('search_by_name'),
              leading: const Icon(Icons.search),
              padding: const MaterialStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Chip(
                      label: Text(
                        'Filtro: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                      ),
                      onDeleted: () {
                        setState(() {
                          _selectedDateRange = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<RegistroAcesso>>(
              stream: _controller.getRegistrosAcesso(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${localizations.translate('error')}: ${snapshot.error}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }

                final registros = snapshot.data ?? [];
                
                // Aplicar filtros
                final registrosFiltrados = registros.where((registro) {
                  final matchesQuery = registro.visitorName.toLowerCase().contains(_searchQuery);
                  final matchesDate = _selectedDateRange == null ||
                      (_selectedDateRange!.start.isBefore(registro.dataHora) &&
                          _selectedDateRange!.end.isAfter(registro.dataHora));
                  return matchesQuery && matchesDate;
                }).toList();

                if (registrosFiltrados.isEmpty) {
                  return Center(
                    child: Text(localizations.translate('no_records_found')),
                  );
                }

                return ListView.builder(
                  itemCount: registrosFiltrados.length,
                  itemBuilder: (context, index) {
                    final registro = registrosFiltrados[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: registro.visitorType == 'visitante'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.secondary,
                          child: Icon(
                            registro.visitorType == 'visitante'
                                ? Icons.person
                                : Icons.work,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        title: Text(
                          registro.visitorName,
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          registro.visitorType == 'visitante'
                              ? '${localizations.translate('apartment')}: ${registro.apartamento}'
                              : '${localizations.translate('company')}: ${registro.empresa}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('dd/MM/yyyy').format(registro.dataHora),
                              style: theme.textTheme.bodySmall,
                            ),
                            Text(
                              DateFormat('HH:mm').format(registro.dataHora),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: () => _showDetails(registro),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
      saveText: AppLocalizations.of(context).translate('confirm'),
      cancelText: AppLocalizations.of(context).translate('cancel'),
      helpText: AppLocalizations.of(context).translate('select_period'),
      fieldStartHintText: AppLocalizations.of(context).translate('start_date'),
      fieldEndHintText: AppLocalizations.of(context).translate('end_date'),
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _showDetails(RegistroAcesso registro) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(localizations.translate('access_details')),
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(
                        context,
                        localizations.translate('name'),
                        registro.visitorName,
                      ),
                      _buildDetailRow(
                        context,
                        localizations.translate('type'),
                        registro.visitorType == 'visitante'
                            ? localizations.translate('visitor')
                            : localizations.translate('provider'),
                      ),
                      if (registro.visitorType == 'visitante')
                        _buildDetailRow(
                          context,
                          localizations.translate('apartment'),
                          registro.apartamento,
                        )
                      else
                        _buildDetailRow(
                          context,
                          localizations.translate('company'),
                          registro.empresa,
                        ),
                      _buildDetailRow(
                        context,
                        localizations.translate('scanned_by'),
                        registro.scannedByName,
                      ),
                      _buildDetailRow(
                        context,
                        localizations.translate('date'),
                        DateFormat('dd/MM/yyyy').format(registro.dataHora),
                      ),
                      _buildDetailRow(
                        context,
                        localizations.translate('time'),
                        DateFormat('HH:mm').format(registro.dataHora),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() async {
    final localizations = AppLocalizations.of(context);
    try {
      final registros = await _controller.getRegistrosAcesso().first;
      
      if (registros.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('no_records_to_export')),
          ),
        );
        return;
      }

      final csv = StringBuffer();
      csv.writeln('Nome,Tipo,Apartamento/Empresa,Registrado por,Data,Hora');

      for (final registro in registros) {
        final line = [
          registro.visitorName,
          registro.visitorType == 'visitante'
              ? localizations.translate('visitor')
              : localizations.translate('provider'),
          registro.visitorType == 'visitante'
              ? registro.apartamento
              : registro.empresa,
          registro.scannedByName,
          DateFormat('dd/MM/yyyy').format(registro.dataHora),
          DateFormat('HH:mm').format(registro.dataHora),
        ].join(',');
        csv.writeln(line);
      }

      await Share.share(
        csv.toString(),
        subject: localizations.translate('access_records'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${localizations.translate('error_exporting')}: $e'),
        ),
      );
    }
  }
}
