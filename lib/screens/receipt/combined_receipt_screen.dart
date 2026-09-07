import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CombinedReceiptScreen extends StatefulWidget {
  // These are supplied when the screen is opened from a receipt-change
  // push notification.
  final String? receiptNo;
  final String? requestId;

  const CombinedReceiptScreen({super.key, this.receiptNo, this.requestId});

  @override
  State<CombinedReceiptScreen> createState() => _CombinedReceiptScreenState();
}

class _CombinedReceiptScreenState extends State<CombinedReceiptScreen> {
  bool loading = true;

  List<Map<String, dynamic>> receipts = [];

  final PageController _pageController = PageController();
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    loadReceipts();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD DATA
  // ==========================================================

  Future<void> loadReceipts() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final data = await ApiService.getCombinedReceipts();

      if (!mounted) return;

      // When opened from a push notification, find the requested receipt.
      // Receipt number is preferred; request ID is used as a fallback.
      int targetIndex = 0;

      final notificationReceiptNo = widget.receiptNo?.trim() ?? '';
      final notificationRequestId = widget.requestId?.trim() ?? '';

      if (notificationReceiptNo.isNotEmpty) {
        final index = data.indexWhere((item) {
          final no = item["receipt_no"]?.toString().trim() ?? '';
          return no.isNotEmpty &&
              no.toLowerCase() == notificationReceiptNo.toLowerCase();
        });

        if (index >= 0) {
          targetIndex = index;
        }
      }

      if (targetIndex == 0 && notificationRequestId.isNotEmpty) {
        final index = data.indexWhere((item) {
          final id = item["request_id"]?.toString().trim() ?? '';
          return id.isNotEmpty &&
              id.toLowerCase() == notificationRequestId.toLowerCase();
        });

        if (index >= 0) {
          targetIndex = index;
        }
      }

      setState(() {
        receipts = data;
        currentPage = targetIndex;
        loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients || receipts.isEmpty) return;

        final safeIndex = targetIndex.clamp(0, receipts.length - 1);
        _pageController.jumpToPage(safeIndex);

        if (notificationReceiptNo.isNotEmpty ||
            notificationRequestId.isNotEmpty) {
          print("==============================================");
          print("RECEIPT NOTIFICATION OPENED");
          print("Receipt No : $notificationReceiptNo");
          print("Request ID : $notificationRequestId");
          print("Target Page: $safeIndex");
          print("==============================================");
        }
      });

      print("COMBINED RECEIPT SCREEN ROWS: ${receipts.length}");
    } catch (e) {
      print("COMBINED RECEIPT SCREEN ERROR: $e");

      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  // ==========================================================
  // SAFE VALUE
  // ==========================================================

  String value(dynamic v) {
    if (v == null) {
      return "-";
    }

    final text = v.toString().trim();

    if (text.isEmpty || text.toLowerCase() == "null") {
      return "-";
    }

    return text;
  }

  // ==========================================================
  // DATE FORMAT
  // ==========================================================

  String formatDate(dynamic date) {
    if (date == null) {
      return "-";
    }

    try {
      final d = DateTime.parse(date.toString());

      return "${d.day.toString().padLeft(2, '0')}/"
          "${d.month.toString().padLeft(2, '0')}/"
          "${d.year}";
    } catch (_) {
      return value(date);
    }
  }

  // ==========================================================
  // STATUS
  // ==========================================================
  String getStatus(Map<String, dynamic> item) {
    return value(item["status"]);
  }

  String getReason(Map<String, dynamic> item) {
    return value(item["reason"]);
  }
  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FC),

      appBar: AppBar(
        backgroundColor: const Color(0xff1769D5),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        title: const Text(
          "Combined Receipt",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Container(
            height: 55,
            color: const Color(0xff1769D5),

            child: Row(
              children: [
                Expanded(child: _tabTitle(title: "Receipts", index: 1)),
              ],
            ),
          ),
        ),
      ),

      body: _buildBody(),
    );
  }

  // ==========================================================
  // TAB STATE
  // ==========================================================

  int selectedTab = 1;

  Widget _tabTitle({required String title, required int index}) {
    final selected = selectedTab == index;

    return InkWell(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },

      child: Container(
        alignment: Alignment.center,

        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),

        child: Text(
          "$title (${receipts.length})",

          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BODY
  // ==========================================================

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (receipts.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadReceipts,

        child: ListView(
          children: [
            const SizedBox(height: 250),

            Icon(
              Icons.receipt_long_outlined,
              size: 55,
              color: Colors.blueGrey.shade400,
            ),

            const SizedBox(height: 15),

            Center(
              child: Text(
                "No receipts found.",
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: TextButton.icon(
                onPressed: loadReceipts,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh"),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadReceipts,

      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              "Receipt ${currentPage + 1} of ${receipts.length}",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: receipts.length,
              onPageChanged: (index) {
                setState(() {
                  currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final item = receipts[index];

                return Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  child: buildReceiptCard(item),
                );
              },
            ),
          ),

          if (receipts.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(receipts.length, (index) {
                  final selected = currentPage == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: selected ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xff1769D5)
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // RECEIPT REQUEST CARD
  // ==========================================================

  Widget buildRequestCard(Map<String, dynamic> item) {
    final requestId = value(item["request_id"]);

    final requestDate = formatDate(item["request_date"]);

    final requestType = value(item["request_type"]);

    final valueFrom = value(item["value_from"]);

    final valueTo = value(item["value_to"]);

    final receiptId = value(item["request_receipt_id"] ?? item["receipt_id"]);

    final status = getStatus(item);

    final reason = getReason(item);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(10),

        border: Border.all(color: Colors.grey.shade200),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ==================================================
          // HEADER
          // ==================================================
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,

                    borderRadius: BorderRadius.circular(15),
                  ),

                  child: Text(
                    "Request #$requestId",

                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),

                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Text(
                formatDate(item["request_date"]),

                style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ==================================================
          // REQUEST DETAILS
          // ==================================================
          detailRow(Icons.category_outlined, "Type", requestType),

          detailRow(Icons.currency_rupee, "Value From", valueFrom),

          detailRow(Icons.currency_rupee, "Value To", valueTo),

          detailRow(Icons.receipt_long_outlined, "Receipt ID", receiptId),

          const SizedBox(height: 8),

          Divider(color: Colors.grey.shade200, height: 1),

          const SizedBox(height: 10),

          // ==================================================
          // STATUS
          // ==================================================
          statusRow(status),

          // ==================================================
          // REASON
          // ==================================================
          reasonRow(reason),
        ],
      ),
    );
  }

  // ==========================================================
  // RECEIPT CARD
  // ==========================================================

  Widget buildReceiptCard(Map<String, dynamic> item) {
    final receiptNo = value(item["receipt_no"]);
    final receiptDate = formatDate(item["receipt_date"]);
    final customerName = value(item["customer_name"]);
    final requestType = value(item["request_type"]);
    final requestDate = formatDate(item["request_date"]);
    final valueFrom = value(item["value_from"]);
    final valueTo = value(item["value_to"]);
    final requestUserId = value(item["request_user_id"]);
    final status = getStatus(item);
    final reason = getReason(item);

    // Initials for the customer avatar.
    String initials = "R";
    if (customerName != "-" && customerName.trim().isNotEmpty) {
      final parts = customerName
          .trim()
          .split(RegExp(r"\s+"))
          .where((e) => e.isNotEmpty)
          .toList();

      if (parts.length >= 2) {
        initials = "${parts.first[0]}${parts.last[0]}".toUpperCase();
      } else {
        initials = parts.first[0].toUpperCase();
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Gradient border similar to the reference UI.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff39E66F), Color(0xff10CFEA), Color(0xff3155D5)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffFCFEFF),
          borderRadius: BorderRadius.circular(26),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TOP HEADER
              // ==================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xff4053BA),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xff18243D),
                            fontSize: 19,
                            height: 1.25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          "Receipt #$receiptNo",
                          style: TextStyle(
                            color: Colors.blueGrey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffE8ECFA),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      receiptDate,
                      style: const TextStyle(
                        color: Color(0xff4053BA),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================================================
              // REQUEST TYPE
              // ==================================================
              _receiptInfoBox(
                icon: Icons.category_outlined,
                title: "Request Type",
                valueText: requestType,
              ),

              const SizedBox(height: 10),

              // ==================================================
              // REQUEST DATE
              // ==================================================
              _receiptInfoBox(
                icon: Icons.calendar_today_outlined,
                title: "Request Date",
                valueText: requestDate,
              ),

              const SizedBox(height: 10),

              // ==================================================
              // USER ID
              // ==================================================
              _receiptInfoBox(
                icon: Icons.person_outline,
                title: "Employee Login ID",
                valueText: requestUserId,
              ),

              const SizedBox(height: 10),

              // ==================================================
              // VALUE FROM
              // ==================================================
              _receiptInfoBox(
                icon: Icons.currency_rupee,
                title: "Value From",
                valueText: valueFrom,
              ),

              const SizedBox(height: 10),

              // ==================================================
              // VALUE TO
              // ==================================================
              _receiptInfoBox(
                icon: Icons.currency_rupee,
                title: "Value To",
                valueText: valueTo,
              ),

              const SizedBox(height: 10),

              // ==================================================
              // STATUS
              // ==================================================
              _receiptInfoBox(
                icon: Icons.pending_outlined,
                title: "Status",
                valueText: status.toUpperCase(),
                valueColor:
                    status.toLowerCase() == "approved" ||
                        status.toLowerCase() == "approve" ||
                        status.toLowerCase() == "completed" ||
                        status.toLowerCase() == "complete"
                    ? Colors.green.shade700
                    : status.toLowerCase() == "rejected" ||
                          status.toLowerCase() == "reject"
                    ? Colors.red.shade700
                    : Colors.orange.shade700,
              ),

              const SizedBox(height: 10),

              // ==================================================
              // REASON
              // ==================================================
              _receiptInfoBox(
                icon: Icons.comment_outlined,
                title: "Reason",
                valueText: reason,
              ),

              const SizedBox(height: 16),

              // ==================================================
              // UPDATE BUTTON
              // ==================================================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateReceipt(item),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text("Update"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4053BA),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptInfoBox({
    required IconData icon,
    required String title,
    required String valueText,
    Color? valueColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xffF1F4F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 23, color: const Color(0xff4053BA)),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff18243D),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  valueText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor ?? const Color(0xff202636),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // UPDATE RECEIPT
  // ==========================================================

  Future<void> _updateReceipt(Map<String, dynamic> item) async {
    try {
      // ==================================================
      // GET REQUEST UNQID
      // app_receipt_request.unqid
      // ==================================================

      final requestUnqid = value(item["request_id"]);

      // ==================================================
      // GET RECEIPT UNQID
      // rh_rcl.rcl_2
      // ==================================================

      final recptUnqid = value(
        item["request_receipt_id"] ?? item["receipt_id"],
      );

      final reqType = value(item["request_type"]);

      final valTo = value(item["value_to"]);

      final receiptNo = value(item["receipt_no"]);

      // ==================================================
      // PRINT VALUES
      // ==================================================

      print("");
      print("==============================================");
      print("        UPDATE BUTTON CLICKED");
      print("==============================================");
      print("Request Unqid : $requestUnqid");
      print("Receipt No    : $receiptNo");
      print("recpt_unqid   : $recptUnqid");
      print("req_type      : $reqType");
      print("val_to        : $valTo");
      print("==============================================");

      // ==================================================
      // VALIDATION
      // ==================================================

      if (requestUnqid == "-" || requestUnqid.trim().isEmpty) {
        throw Exception("Request Unqid not found");
      }

      if (recptUnqid == "-" || recptUnqid.trim().isEmpty) {
        throw Exception("Receipt Unqid not found");
      }

      if (reqType == "-" || reqType.trim().isEmpty) {
        throw Exception("Request type not found");
      }

      if (valTo == "-" || valTo.trim().isEmpty) {
        throw Exception("Value To not found");
      }

      // ==================================================
      // CALL API
      // ==================================================

      final result = await ApiService.updateReceiptRequest(
        requestUnqid: requestUnqid,
        recptUnqid: recptUnqid,
        reqType: reqType,
        valTo: valTo,
      );

      // ==================================================
      // PRINT RESPONSE
      // ==================================================

      print("");
      print("==============================================");
      print("       UPDATE RECEIPT RESPONSE");
      print("==============================================");
      print(result);
      print("==============================================");

      // ==================================================
      // SUCCESS
      // ==================================================

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Receipt updated successfully"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // ==================================================
      // REFRESH DATA
      // ==================================================

      await loadReceipts();
    } catch (e) {
      print("❌ UPDATE RECEIPT ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Update failed: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ==========================================================
  // DETAIL ROW
  // ==========================================================

  Widget detailRow(IconData icon, String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, size: 17, color: Colors.blueGrey.shade500),

          const SizedBox(width: 8),

          SizedBox(
            width: 90,

            child: Text(
              title,

              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
            ),
          ),

          const SizedBox(width: 5),

          Expanded(
            child: Text(
              text,

              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // VALUE BOX
  // ==========================================================

  Widget valueBox(String title, String text) {
    return Container(
      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(
        color: const Color(0xffF7F9FC),

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: Colors.grey.shade200),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade600),
          ),

          const SizedBox(height: 3),

          Text(
            text,

            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // STATUS ROW
  // ==========================================================

  Widget statusRow(String status) {
    final normalized = status.toLowerCase().trim();

    Color background;
    Color foreground;
    IconData icon;

    if (normalized == "approved" ||
        normalized == "approve" ||
        normalized == "completed" ||
        normalized == "complete") {
      background = Colors.green.shade50;

      foreground = Colors.green.shade800;

      icon = Icons.check_circle_outline;
    } else if (normalized == "rejected" || normalized == "reject") {
      background = Colors.red.shade50;

      foreground = Colors.red.shade800;

      icon = Icons.cancel_outlined;
    } else {
      background = Colors.orange.shade50;

      foreground = Colors.orange.shade800;

      icon = Icons.pending_outlined;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          Icon(icon, size: 18, color: foreground),

          const SizedBox(width: 8),

          const SizedBox(
            width: 90,

            child: Text(
              "Status",
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),

            decoration: BoxDecoration(
              color: background,

              borderRadius: BorderRadius.circular(20),
            ),

            child: Text(
              status.toUpperCase(),

              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // REASON ROW
  // ==========================================================

  Widget reasonRow(String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.comment_outlined,
            size: 18,
            color: Colors.blueGrey.shade500,
          ),

          const SizedBox(width: 8),

          const SizedBox(
            width: 90,

            child: Text(
              "Reason",
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),

              decoration: BoxDecoration(
                color: const Color(0xffF7F9FC),

                borderRadius: BorderRadius.circular(7),

                border: Border.all(color: Colors.grey.shade200),
              ),

              child: Text(
                reason,

                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
