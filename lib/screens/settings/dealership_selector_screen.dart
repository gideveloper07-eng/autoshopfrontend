import 'dart:convert';
import 'package:college_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DealershipSelectorScreen extends StatefulWidget {
  const DealershipSelectorScreen({super.key});

  @override
  State<DealershipSelectorScreen> createState() =>
      _DealershipSelectorScreenState();
}

class _DealershipSelectorScreenState extends State<DealershipSelectorScreen> {
  List<dynamic> dealerships = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final jsonData = prefs.getString('accessibleDatabases') ?? '[]';

    setState(() {
      dealerships = jsonDecode(jsonData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Dealership')),
      body: ListView.builder(
        itemCount: dealerships.length,
        itemBuilder: (_, index) {
          final d = dealerships[index];

          return ListTile(
            title: Text(d['propertyname']),
            subtitle: Text(d['propertycode']),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await ApiService.switchDatabase(d['unqid']);

              if (result != null && result['success'] == true) {
                await ApiService.updateCurrentDatabase(
                  token: result['token'],
                  databaseName: result['databaseName'],
                  companyCode: result['propertyCode'],
                  clientId: d['unqid'],
                );

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                );
              }
            },
          );
        },
      ),
    );
  }
}
