import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ChatDocumentPickerDialog extends StatefulWidget {
  const ChatDocumentPickerDialog({super.key});

  @override
  State<ChatDocumentPickerDialog> createState() =>
      _ChatDocumentPickerDialogState();
}

class _ChatDocumentPickerDialogState extends State<ChatDocumentPickerDialog> {
  List<Map<String, dynamic>> documents = [];
  List<Map<String, dynamic>> filteredDocuments = [];

  bool loading = true;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    final data = await ApiService.getChatDocuments();

    setState(() {
      documents = data;
      filteredDocuments = data;
      loading = false;
    });
  }

  void search(String value) {
    setState(() {
      filteredDocuments = documents.where((doc) {
        final no = (doc["DocumentNo"] ?? "").toString().toLowerCase();

        return no.contains(value.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              color: Colors.blue,
              child: const Row(
                children: [
                  Icon(Icons.attach_file, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    "Share Document",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: TextField(
                controller: searchController,
                onChanged: search,
                decoration: const InputDecoration(
                  hintText: "Search document...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filteredDocuments.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocuments[index];

                        return ListTile(
                          leading: Icon(
                            doc["DocumentType"] == "CHALLAN"
                                ? Icons.description
                                : Icons.picture_as_pdf,
                            color: Colors.red,
                          ),
                          title: Text(doc["DocumentNo"] ?? ""),
                          subtitle: Text(doc["DocumentType"] ?? ""),
                          onTap: () {
                            Navigator.pop(context, doc);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
