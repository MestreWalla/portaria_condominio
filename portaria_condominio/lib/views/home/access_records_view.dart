import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share/share.dart';
import '../../controllers/visita_controller.dart';
import '../../localizations/app_localizations.dart';
import '../../models/visita_model.dart';

class AccessRecordsView extends StatefulWidget {
  const AccessRecordsView({super.key});

  @override
  _AccessRecordsViewState createState() => _AccessRecordsViewState();
}

class _AccessRecordsViewState extends State<AccessRecordsView> {
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final visitaController = Provider.of<VisitaController>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('access_records')),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: _selectedDateRange != null,
              child: const Icon(Icons.filter_list),
            ),
            onPressed: _selectDateRange,
            tooltip: AppLocalizations.of(context).translate('filter_by_date'),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportData,
            tooltip: AppLocalizations.of(context).translate('share_records'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              hintText: AppLocalizations.of(context).translate('search_by_name'),
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
            child: FutureBuilder<List<Visita>>(
              future: visitaController.buscarTodasVisitas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context).translate('no_records_found')),
                  );
                }

                final visitas = snapshot.data!.where((visita) {
                  DateTime? visitaStartDate;
                  try {
                    visitaStartDate = DateFormat('dd/MM/yyyy').parse(visita.startDate);
                  } catch (e) {
                    // Se o formato de data estiver inválido, ignora a visita
                    return false;
                  }
                  final matchesQuery = visita.nome.toLowerCase().contains(_searchQuery);
                  final matchesDate = _selectedDateRange == null ||
                      (_selectedDateRange!.start.isBefore(visitaStartDate!) &&
                      _selectedDateRange!.end.isAfter(visitaStartDate));
                  return matchesQuery && matchesDate;
                }).toList();

                return ListView.builder(
                  itemCount: visitas.length,
                  itemBuilder: (context, index) {
                    final visita = visitas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(visita.nome[0].toUpperCase()),
                        ),
                        title: Text(
                          visita.nome,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Casa: ${visita.apartamento}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat.yMd().format(DateFormat('dd/MM/yyyy').parse(visita.startDate)),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              visita.startTime,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: () {
                          _showDetails(visita);
                        },
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
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _showDetails(Visita visita) {
    DateTime? visitaStartDate;
    try {
      visitaStartDate = DateFormat('dd/MM/yyyy').parse(visita.startDate);
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erro ao carregar data'),
          content: Text('Formato de data inválido para ${visita.startDate}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              visita.nome[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 32,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(visita.status),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusText(visita.status),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        visita.nome,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        visita.role.toUpperCase(),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _DetailItem(
                        icon: Icons.apartment,
                        title: 'Apartamento',
                        value: visita.apartamento,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _DetailItem(
                              icon: Icons.calendar_today,
                              title: 'Data',
                              value: DateFormat.yMMMMd('pt_BR').format(visitaStartDate!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _DetailItem(
                              icon: Icons.login,
                              title: AppLocalizations.of(context).translate('entry_time'),
                              value: visita.startTime,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _DetailItem(
                              icon: Icons.logout,
                              title: AppLocalizations.of(context).translate('exit_time'),
                              value: visita.endTime.isNotEmpty 
                                ? visita.endTime 
                                : AppLocalizations.of(context).translate('not_registered'),
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (visita.observacoes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _DetailItem(
                          icon: Icons.note,
                          title: 'Observações',
                          value: visita.observacoes,
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(AppLocalizations.of(context).translate('close')),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              final detalhes = '''
${AppLocalizations.of(context).translate('visit_details')}:
${AppLocalizations.of(context).translate('name')}: ${visita.nome}
${AppLocalizations.of(context).translate('apartment')}: ${visita.apartamento}
${AppLocalizations.of(context).translate('entry_time')}: ${visita.startTime}
${AppLocalizations.of(context).translate('exit_time')}: ${visita.endTime.isNotEmpty ? visita.endTime : AppLocalizations.of(context).translate('not_registered')}
${AppLocalizations.of(context).translate('status')}: ${_getStatusText(visita.status)}
${visita.observacoes.isNotEmpty ? '\n${AppLocalizations.of(context).translate('observations')}: ${visita.observacoes}' : ''}
''';
                              Share.share(detalhes);
                            },
                            icon: const Icon(Icons.share),
                            label: Text(AppLocalizations.of(context).translate('share')),
                          ),
                        ],
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'agendado':
        return Colors.blue;
      case 'em_andamento':
        return Colors.green;
      case 'finalizado':
        return Colors.grey;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    final translations = {
      'agendado': AppLocalizations.of(context).translate('scheduled'),
      'em_andamento': AppLocalizations.of(context).translate('in_progress'),
      'finalizado': AppLocalizations.of(context).translate('finished'),
      'cancelado': AppLocalizations.of(context).translate('canceled'),
    };
    return translations[status.toLowerCase()] ?? AppLocalizations.of(context).translate('unknown');
  }

  Widget _DetailItem({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color ?? Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    // Simula exportação de dados
    const String data = 'Nome, Apartamento, Data\n';
    Share.share(data, subject: 'Registros de Acesso');
  }
}
