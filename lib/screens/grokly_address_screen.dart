import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroklyAddressScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onAddressSelected;
  const GroklyAddressScreen({super.key, this.onAddressSelected});

  @override
  State<GroklyAddressScreen> createState() => _GroklyAddressScreenState();
}

class _GroklyAddressScreenState extends State<GroklyAddressScreen> {
  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  static const _themeColor = Color(0xFF2F825D);

  void _showAddAddressForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddAddressForm(uid: uid),
    );
  }

  void _deleteAddress(String docId) {
    if (uid == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('addresses')
        .doc(docId)
        .delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address removed'),
        backgroundColor: _themeColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF3),
      appBar: AppBar(
        backgroundColor: _themeColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Saved Addresses',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: uid != null
            ? FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .collection('addresses')
                .orderBy('createdAt', descending: true)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          if (uid == null) {
            return _buildEmptyState(
                'Please sign in to view your addresses', Icons.login);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _themeColor),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState(
                'No saved addresses yet', Icons.location_off_outlined);
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    data['id'] = doc.id;
                    return _buildAddressCard(data);
                  },
                ),
              ),
              _buildAddButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: const Color(0xFFBFC9BE), size: 56),
                const SizedBox(height: 12),
                Text(message,
                    style: const TextStyle(
                        color: Color(0xFF6F7A70), fontSize: 15)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showAddAddressForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add your first address'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE7EAE7))),
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _themeColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _showAddAddressForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Add New Address',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAddressCard(Map<String, dynamic> data) {
    final label = data['label'] ?? 'Home';
    final street = data['street'] ?? '';
    final city = data['city'] ?? '';
    final state = data['state'] ?? '';
    final pincode = data['pincode'] ?? '';
    final phone = data['phone'] ?? '';
    final addressStr = '$street, $city, $state - $pincode';

    return GestureDetector(
      onTap: () {
        if (widget.onAddressSelected != null) {
          widget.onAddressSelected!(data);
          Navigator.pop(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDE4DE)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                label.toString().toLowerCase() == 'work'
                    ? Icons.work_outline
                    : Icons.home_outlined,
                color: _themeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF181D19)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    addressStr,
                    style: const TextStyle(
                        color: Color(0xFF6C756F), fontSize: 13),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Phone: $phone',
                      style: const TextStyle(
                          color: Color(0xFF6C756F), fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: () => _deleteAddress(data['id']),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAddressForm extends StatefulWidget {
  final String? uid;
  const _AddAddressForm({required this.uid});

  @override
  State<_AddAddressForm> createState() => _AddAddressFormState();
}

class _AddAddressFormState extends State<_AddAddressForm> {
  final _formKey = GlobalKey<FormState>();
  String label = 'Home';
  String street = '';
  String city = '';
  String state = '';
  String pincode = '';
  String phone = '';
  bool isSaving = false;

  static const _themeColor = Color(0xFF2F825D);

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (widget.uid == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please sign in first')));
      return;
    }

    setState(() => isSaving = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .collection('addresses')
        .add({
      'label': label,
      'street': street,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Address',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF181D19)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Home'),
                    value: 'Home',
                    groupValue: label,
                    activeColor: _themeColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => label = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Work'),
                    value: 'Work',
                    groupValue: label,
                    activeColor: _themeColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => label = val!),
                  ),
                ),
              ],
            ),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Street / Flat No',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _themeColor, width: 2),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => street = v!,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'City',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _themeColor, width: 2),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onSaved: (v) => city = v!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _themeColor, width: 2),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onSaved: (v) => state = v!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Pincode',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _themeColor, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onSaved: (v) => pincode = v!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _themeColor, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                    onSaved: (v) => phone = v!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isSaving ? null : _save,
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Address',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
