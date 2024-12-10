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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('access_records')),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedDateRange != null,
              child: Icon(
                Icons.filter_list,
                color: colorScheme.primary,
              ),
            ),
            onPressed: _selectDateRange,
            tooltip: localizations.translate('filter_by_date'),
          ),
          IconButton(
            icon: Icon(
              Icons.share,
              color: colorScheme.primary,
            ),
            onPressed: _exportData,
            tooltip: localizations.translate('share_records'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: localizations.translate('search_by_name'),
              leading: Icon(Icons.search, color: colorScheme.primary),
              padding: const MaterialStatePropertyAll<EdgeInsets>(
                EdgeInsets.symmetric(horizontal: 16.0),
              ),
              elevation: const MaterialStatePropertyAll<double>(0),
              backgroundColor: MaterialStatePropertyAll<Color>(
                colorScheme.surfaceVariant.withOpacity(0.3),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              shape: MaterialStatePropertyAll<OutlinedBorder>(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
          if (_selectedDateRange != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 0,
                color: colorScheme.secondaryContainer.withOpacity(0.4),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        color: colorScheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedDateRange = null;
                          });
                        },
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<RegistroAcesso>>(
              stream: _controller.getRegistrosAcesso(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${localizations.translate('error')}: ${snapshot.error}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final registros = snapshot.data ?? [];
                final registrosFiltrados = registros.where((registro) {
                  final matchesQuery = registro.visitorName.toLowerCase().contains(_searchQuery);
                  final matchesDate = _selectedDateRange == null ||
                      (_selectedDateRange!.start.isBefore(registro.dataHora) &&
                          _selectedDateRange!.end.isAfter(registro.dataHora));
                  return matchesQuery && matchesDate;
                }).toList();

                if (registrosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          color: colorScheme.outline,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.translate('no_records_found'),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: registrosFiltrados.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final registro = registrosFiltrados[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _showDetails(registro),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: registro.visitorType == 'visitante'
                                        ? colorScheme.primaryContainer
                                        : colorScheme.secondaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      registro.visitorType == 'visitante'
                                          ? Icons.person
                                          : Icons.work,
                                      color: registro.visitorType == 'visitante'
                                          ? colorScheme.primary
                                          : colorScheme.secondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        registro.visitorName,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        registro.visitorType == 'visitante'
                                            ? '${localizations.translate('apartment')}: ${registro.apartamento}'
                                            : '${localizations.translate('company')}: ${registro.empresa}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.outline,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 16,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('dd/MM/yyyy HH:mm')
                                                .format(registro.dataHora),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
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
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      currentDate: DateTime.now(),
      saveText: AppLocalizations.of(context).translate('confirm'),
      cancelText: AppLocalizations.of(context).translate('cancel'),
      helpText: AppLocalizations.of(context).translate('select_period'),
      fieldStartHintText: AppLocalizations.of(context).translate('start_date'),
      fieldEndHintText: AppLocalizations.of(context).translate('end_date'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
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
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: registro.visitorType == 'visitante'
                            ? colorScheme.primaryContainer
                            : colorScheme.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          registro.visitorType == 'visitante'
                              ? Icons.person
                              : Icons.work,
                          size: 40,
                          color: registro.visitorType == 'visitante'
                              ? colorScheme.primary
                              : colorScheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      registro.visitorName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      registro.visitorType == 'visitante'
                          ? localizations.translate('visitor')
                          : localizations.translate('provider'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDetailRow(
                      context,
                      Icons.location_on,
                      registro.visitorType == 'visitante'
                          ? localizations.translate('apartment')
                          : localizations.translate('company'),
                      registro.visitorType == 'visitante'
                          ? registro.apartamento
                          : registro.empresa,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      Icons.person_outline,
                      localizations.translate('scanned_by'),
                      registro.scannedByName,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      Icons.calendar_today,
                      localizations.translate('date'),
                      DateFormat('dd/MM/yyyy').format(registro.dataHora),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      context,
                      Icons.access_time,
                      localizations.translate('time'),
                      DateFormat('HH:mm').format(registro.dataHora),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(localizations.translate('close')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
