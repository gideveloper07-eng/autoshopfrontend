import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../home/home_screen.dart';
import '../../services/activity_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final companyCodeCtrl = TextEditingController();
  final userIdCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool isLoading = false;
  bool obscure = true;
  bool isValidatingCode = false;
  bool? companyValid;

  String databaseName = "";
  String companyName = "";
  String utg = "";

  static const Color kBlue = Color(0xFF1565C0);
  static const Color kBlueLight = Color(0xFF42A5F5);
  static const Color kBlueDark = Color(0xFF0D47A1);
  static const Color kBlueDeep = Color(0xFF0A2E5C);
  static const Color kNavy = Color(0xFF071426);
  static const Color kNavySoft = Color(0xFF0E2542);
  static const Color kSteel = Color(0xFFB9C7D9);

  @override
  void initState() {
    super.initState();
    ApiService.wakeServer();
  }

  // Called when company code field loses focus
  Future<void> _validateCompany() async {
    final code = companyCodeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => isValidatingCode = true);
    //final result = await ApiService.validateCompany(code);
    Map<String, dynamic> result = await ApiService.validateCompany(code);

    setState(() {
      isValidatingCode = false;

      //databaseName = result['databaseName'] ?? "";
      //companyName  = result['companyName'] ?? "";
      databaseName = result['databaseName']?.toString() ?? "";

      companyName = result['companyName']?.toString() ?? "";

      companyValid = databaseName.isNotEmpty;
    });
  }

  @override
  void dispose() {
    companyCodeCtrl.dispose();
    userIdCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (companyValid == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid Company Code"),
          backgroundColor: kBlueDark,
        ),
      );
      return;
    }
    setState(() => isLoading = true);
    print("DATABASE NAME : $databaseName");
    print("USER ID       : ${userIdCtrl.text.trim()}");
    print("USER ID       : ${passwordCtrl.text.trim()}");
    final res = await ApiService.login(
      databaseName: databaseName,
      userId: userIdCtrl.text.trim(),
      password: passwordCtrl.text.trim(),
    );
    setState(() => isLoading = false);
    if (!mounted) return;

    if (res != null && res['token'] != null) {
      // Save companyCode (not returned by server, so we store it from the form)
      await ApiService.saveUserSession(
        token: res['token'],
        userId: res['userId']?.toString() ?? userIdCtrl.text.trim(),
        isAdmin: res['isAdmin'] ?? false,
        utg: res["utg"]?.toString() ?? "",
        userName: res['name']?.toString() ?? userIdCtrl.text.trim(),
        userEmail: res['email']?.toString() ?? '',
        databaseName: res['databaseName']?.toString() ?? databaseName,
        companyCode: companyCodeCtrl.text.trim(),
      );
      // Log Login Activity
      try {
        await ActivityService.logActivity(
          activityType: "LOGIN",
          activityName: "User Login",
          //  userId: res['userId']?.toString() ?? '',
          userName: res['name']?.toString() ?? '',
          screenName: 'LoginScreen',
        );
      } catch (e) {
        debugPrint("Activity Log Error: $e");
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            userName: res['name'] ?? res['userId'] ?? 'User',
            userEmail: res['email'] ?? '',
          ),
        ),
      );
      print(res["utg"].toString());
    } else {
      // Read the actual message from the server response
      final msg = res?['message']?.toString() ?? "Invalid User ID or Password";

      // Show a prominent dialog for device-lock errors
      if (msg.toLowerCase().contains("another device")) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(
              Icons.devices_other_rounded,
              color: Color(0xFF8B1E3F),
              size: 40,
            ),
            title: const Text(
              "Already Logged In",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              textAlign: TextAlign.center,
            ),
            content: const Text(
              "This account is already logged in on another device.\n\nPlease logout from that device first.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E3F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: kBlueDark),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D3F8A), Color(0xFF2C6CE0), Color(0xFF83C4FF)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              left: -60,
              child: _bgGlow(220, Colors.white.withOpacity(0.06)),
            ),
            Positioned(
              top: 90,
              right: -90,
              child: _bgGlow(260, Colors.white.withOpacity(0.05)),
            ),
            Positioned(
              bottom: -80,
              left: -90,
              child: _bgGlow(180, Colors.white.withOpacity(0.04)),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - 36,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTopHero(),
                          const SizedBox(height: 20),
                          _buildLoginCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bgGlow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildTopHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2979FF), Color(0xFF4EA9FF), Color(0xFF83D4FF)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.26), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.directions_car_filled_rounded,
              size: 56,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "MY AUTOSHOP",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Precision Service Management",
            style: TextStyle(
              fontSize: 14,
              color: kSteel,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF4FBFF)],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6F4FF), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0x220D3C74),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome Back",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10253F),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Login to manage your automobile operations",
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF4D6178),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            _label("Company Code"),
            const SizedBox(height: 6),
            Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) _validateCompany();
              },
              child: TextFormField(
                controller: companyCodeCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? "Company code is required"
                    : null,
                style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
                decoration: InputDecoration(
                  hintText: "Enter company code",
                  hintStyle: TextStyle(
                    color: const Color(0xFF73839A),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.business_outlined,
                    color: kBlue,
                    size: 20,
                  ),
                  suffixIcon: isValidatingCode
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kBlue,
                            ),
                          ),
                        )
                      : companyValid == true
                      ? const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        )
                      : companyValid == false
                      ? const Icon(Icons.cancel, color: Colors.red, size: 20)
                      : null,
                  filled: true,
                  fillColor: companyValid == false
                      ? const Color(0xFFFFECEF)
                      : const Color(0xFFFFF3F5),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: companyValid == false
                          ? Colors.red
                          : companyValid == true
                          ? Colors.green
                          : const Color(0xFFD6E3F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: companyValid == false
                          ? Colors.red
                          : companyValid == true
                          ? Colors.green
                          : const Color(0xFFD6E3F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBlue, width: 1.8),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ),
            if (companyValid == false)
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  "Company code not found",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            _label("User ID"),
            const SizedBox(height: 6),
            _field(
              ctrl: userIdCtrl,
              hint: "Enter your user ID",
              icon: Icons.person_outline,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? "User ID is required"
                  : null,
            ),
            const SizedBox(height: 16),
            _label("Password"),
            const SizedBox(height: 6),
            _passwordField(),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A6BE3),
                      Color(0xFF28A8F6),
                      Color(0xFF57D1FF),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          "LOGIN",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF333333),
    ),
  );

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF73839A), fontSize: 13),
        prefixIcon: Icon(icon, color: kBlue, size: 20),
        filled: true,
        fillColor: const Color(0xFFE8F2FF),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD6E3F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD6E3F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: passwordCtrl,
      obscureText: obscure,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? "Password is required" : null,
      style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
      decoration: InputDecoration(
        hintText: "Enter your password",
        hintStyle: const TextStyle(color: Color(0xFF73839A), fontSize: 13),
        prefixIcon: const Icon(Icons.lock_outline, color: kBlue, size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey.shade400,
            size: 20,
          ),
          onPressed: () => setState(() => obscure = !obscure),
        ),
        filled: true,
        fillColor: const Color(0xFFE8F2FF),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD6E3F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD6E3F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
