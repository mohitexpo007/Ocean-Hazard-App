// emergency_services.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // add url_launcher in pubspec for tap-to-call/email

class EmergencyServicesPage extends StatefulWidget {
  const EmergencyServicesPage({super.key});

  @override
  State<EmergencyServicesPage> createState() => _EmergencyServicesPageState();
}

class _EmergencyServicesPageState extends State<EmergencyServicesPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1F3C88), Color(0xFF2E5AAC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _index == 0 ? 'Emergency Services' : 'Contact Us',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _EmergencyTab(),
          _ContactTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: const Color(0xFF1F3C88),
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_fire_department_outlined),
            label: 'Emergency',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_in_talk_outlined),
            label: 'Contact',
          ),
        ],
      ),
    );
  }
}

/// ---------------------- EMERGENCY TAB ----------------------
class _EmergencyTab extends StatelessWidget {
  const _EmergencyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _sectionHeader('🌊  OCEAN HAZARD EMERGENCY SERVICES  🌊',
            color: const Color(0xFFE74C3C)),

        const SizedBox(height: 14),
        _titleRow('1. Emergency Contacts'),

        const SizedBox(height: 8),
        _contactRow(context, 'Coast Guard', '1554', tel: '1554'),
        _divider(),
        _contactRow(context, 'Police Emergency', '100', tel: '100'),
        _divider(),
        _contactRow(context, 'Ambulance', '108', tel: '108'),
        _divider(),
        _contactRow(context, 'Fire Service', '101', tel: '101'),
        _divider(),
        _contactRow(context, 'INCOIS Tsunami Warning', '040-2378-5000',
            tel: '+914023785000'),
        _divider(),
        _contactRow(context, 'Disaster Management', '011-2637-9215',
            tel: '+911126379215'),

        const SizedBox(height: 18),
        _titleRow('2. Immediate Actions for Ocean Hazards'),

        const SizedBox(height: 10),
        _tipCard(
          title: 'Tsunami Warning Response:',
          body:
          'Move immediately to higher ground (at least 30m above sea level). Do not wait for official evacuation orders. Avoid beaches, harbors, and coastal areas.',
        ),
        _tipCard(
          title: 'High Waves & Storm Surge:',
          body:
          'Stay away from coastal areas, piers, and rocky shores. Secure boats and coastal equipment. Monitor weather updates continuously.',
        ),
        _tipCard(
          title: 'Drowning/Water Emergency:',
          body:
          'Call Coast Guard (1554) immediately. If trained, attempt rescue with flotation device. Never enter dangerous waters without proper equipment.',
        ),
        _tipCard(
          title: 'Coastal Flooding:',
          body:
          'Move to higher ground immediately. Avoid driving through flooded roads. Stay away from downed power lines and report to authorities.',
        ),

        const SizedBox(height: 18),
        _titleRow('3. Hazard Reporting'),
        const SizedBox(height: 10),
        _tipCard(
          title: 'Report Ocean Hazards:',
          body:
          'Use this app to report unusual ocean behavior, coastal damage, or hazardous conditions. Include photos, location, and description for emergency response teams.',
        ),
      ],
    );
  }

  Widget _divider() => Divider(color: Colors.grey.shade200, height: 20);

  Widget _sectionHeader(String text, {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _titleRow(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
        const SizedBox(height: 6),
        Container(
          height: 3,
          width: 140,
          decoration: BoxDecoration(
            color: const Color(0xFFE74C3C),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _contactRow(BuildContext context, String label, String value,
      {String? tel}) {
    return InkWell(
      onTap: tel == null
          ? null
          : () async {
        final uri = Uri.parse('tel:$tel');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open dialer')),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, color: Colors.black87, height: 1.2)),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: tel != null ? const Color(0xFF2E5AAC) : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipCard({required String title, required String body}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: Color(0xFFE74C3C), width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFCF3D2B),
                  fontSize: 15)),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------- CONTACT TAB ----------------------
class _ContactTab extends StatefulWidget {
  const _ContactTab();

  @override
  State<_ContactTab> createState() => _ContactTabState();
}

class _ContactTabState extends State<_ContactTab> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _location = TextEditingController();
  final _feedback = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _location.dispose();
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _infoCard(context),
        const SizedBox(height: 18),

        // Follow Us
        _sectionTitle('Follow Us'),
        const SizedBox(height: 10),
        Row(
          children: [
            _socialCircle(
              color: const Color(0xFF3b5998),
              icon: Icons.facebook,
              onTap: () => _openUrl('https://facebook.com/'),
            ),
            const SizedBox(width: 14),
            _socialCircle(
              color: const Color(0xFF1DA1F2),
              icon: Icons.alternate_email,
              onTap: () => _openUrl('https://x.com/'),
            ),
            const SizedBox(width: 14),
            _socialCircle(
              color: const Color(0xFFFF0000),
              icon: Icons.play_arrow_rounded,
              onTap: () => _openUrl('https://youtube.com/'),
            ),
          ],
        ),

        const SizedBox(height: 22),
        _sectionTitle('Send Feedback'),
        const SizedBox(height: 8),
        const Text(
          'Help us improve our ocean hazard monitoring and early warning services. '
              'Share your thoughts or suggestions.',
          style: TextStyle(color: Colors.black87, height: 1.5),
        ),
        const SizedBox(height: 14),

        _input('Your Name', controller: _name, textInputAction: TextInputAction.next),
        const SizedBox(height: 12),
        _input('Your Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next),
        const SizedBox(height: 12),
        _input('Location (Optional)',
            controller: _location, hint: 'City, State', textInputAction: TextInputAction.next),
        const SizedBox(height: 12),
        _input('Your Feedback',
            controller: _feedback,
            hint: 'Share your thoughts about our ocean safety platform...',
            maxLines: 5),

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1F3C88),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _submit,
            child: const Text('Send', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Indian National Centre for Ocean Information Services (INCOIS)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _kv('Email', 'director@incois.gov.in',
              onTap: () => _openUrl('mailto:director@incois.gov.in')),
          _sep(),
          _kv('Phone', '+91-40-2378-5000',
              onTap: () => _openUrl('tel:+914023785000')),
          _sep(),
          _kv('Emergency Hotline', '+91-40-2378-5001',
              onTap: () => _openUrl('tel:+914023785001')),
          _sep(),
          _kv('Address', 'Pragathi Nagar, Hyderabad - 500090'),
        ],
      ),
    );
  }

  Widget _kv(String k, String v, {VoidCallback? onTap}) {
    final row = Row(
      children: [
        Expanded(
          child: Text(k,
              style: const TextStyle(color: Colors.black87, fontSize: 15)),
        ),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: onTap != null ? const Color(0xFF2E5AAC) : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }

  Widget _sep() => Divider(color: Colors.grey.shade200, height: 10);

  Widget _sectionTitle(String t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
        const SizedBox(height: 6),
        Container(
          height: 3,
          width: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFE74C3C),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _socialCircle(
      {required Color color, required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _input(
      String label, {
        String? hint,
        TextEditingController? controller,
        TextInputType keyboardType = TextInputType.text,
        TextInputAction? textInputAction,
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Color(0xFF2E5AAC), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (_name.text.trim().isEmpty || _email.text.trim().isEmpty || _feedback.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill Name, Email and Feedback')),
      );
      return;
    }
    // Here you can POST this feedback to your backend.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks for your feedback!')),
    );
    _name.clear();
    _email.clear();
    _location.clear();
    _feedback.clear();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
