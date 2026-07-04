import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ChatDocumentPickerDialog extends StatefulWidget {
  final String receiverPropertyCode;
  final String receiverCompanyName;

  const ChatDocumentPickerDialog({
    super.key,
    required this.receiverPropertyCode,
    required this.receiverCompanyName,
  });

  @override
  State<ChatDocumentPickerDialog> createState() =>
      _ChatDocumentPickerDialogState();
}

class _ChatDocumentPickerDialogState extends State<ChatDocumentPickerDialog> {
  List<Map<String, dynamic>> documents = [];
  List<Map<String, dynamic>> filteredDocuments = [];

  bool loading = true;

  /// Set when we detect a cross-company situation — shows the switch message
  /// instead of the document list.
  bool _requireSwitch = false;
  String _switchMessage = '';

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    final session = await ApiService.getUserSession();

    final currentPropertyCode = (session?['companyCode'] ?? '')
        .toString()
        .trim()
        .toLowerCase();

    final receiverCode = widget.receiverPropertyCode.trim().toLowerCase();

    print("========== DOCUMENT CHECK ==========");
    print("Current Company : $currentPropertyCode");
    print("Receiver Company: $receiverCode");
    print("====================================");

    // Different company
    if (receiverCode.isNotEmpty &&
        currentPropertyCode.isNotEmpty &&
        receiverCode != currentPropertyCode) {
      if (!mounted) return;

      setState(() {
        loading = false;
        _requireSwitch = true;
        _switchMessage =
            "Please switch to ${widget.receiverCompanyName} to fetch documents.";
      });

      return;
    }

    // Same company -> load documents
    // Same company -> load documents
    final response = await ApiService.getChatDocuments(
      receiverPropertyCode: widget.receiverPropertyCode,
      receiverCompanyName: widget.receiverCompanyName,
    );

    if (!mounted) return;

    // Extra safety (backend check)
    if (response["requireSwitch"] == true) {
      setState(() {
        loading = false;
        _requireSwitch = true;
        _switchMessage =
            response["message"] ?? "Please switch company to fetch documents.";
      });
      return;
    }

    final data = List<Map<String, dynamic>>.from(response["data"] ?? []);

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
            // ── Header ────────────────────────────────────────────────────
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

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : _requireSwitch
                  ? _buildSwitchMessage()
                  : _buildDocumentList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown when the receiver belongs to a different company.
  Widget _buildSwitchMessage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swap_horiz_rounded,
              color: Colors.orange,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Switch Company Required',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            _switchMessage,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Normal document list shown when same-company.
  Widget _buildDocumentList() {
    return Column(
      children: [
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
          child: filteredDocuments.isEmpty
              ? const Center(
                  child: Text(
                    'No documents found.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
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
    );
  }
}
