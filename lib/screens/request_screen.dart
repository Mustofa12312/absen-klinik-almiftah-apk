import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class RequestScreen extends StatefulWidget {
  final String requestType;

  const RequestScreen({super.key, required this.requestType});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _submitRequest() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      setState(() => _isLoading = true);
      try {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
        if (widget.requestType == 'Koreksi') {
          // Asumsikan perbaikan jam masuk/keluar tidak tersedia di UI saat ini, hanya alasan
          await FirestoreService.submitCorrection(
            attendanceId: 'att_unknown', // Harus diambil dari histori, untuk MVP kita lewatkan atau butuh update UI
            branchId: 'HQ-01',
            type: 'wrong_data',
            requestedCheckIn: '08:00',
            requestedCheckOut: '17:00',
            reason: _reasonController.text,
          );
        } else {
          String type = 'permission';
          if (widget.requestType == 'Sakit') type = 'sick';
          if (widget.requestType == 'Cuti') type = 'leave';
          if (widget.requestType == 'Dinas') type = 'business_trip';

          await FirestoreService.submitLeaveRequest(
            branchId: 'HQ-01',
            startDate: dateStr,
            endDate: dateStr,
            type: type,
            reason: _reasonController.text,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pengajuan ${widget.requestType} berhasil dikirim! Menunggu persetujuan admin.'),
              backgroundColor: const Color(0xFFE06A00),
            )
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih tanggal terlebih dahulu.'),
          backgroundColor: Colors.orange,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengajuan ${widget.requestType}'),
        backgroundColor: const Color(0xFFE06A00),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 0,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pengajuan ini akan dikirim ke Super Admin untuk ditinjau. Pastikan data yang dimasukkan akurat.',
                          style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('Pilih Tanggal', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2025),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null 
                          ? '${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}' 
                          : 'Pilih Tanggal Pengajuan',
                        style: TextStyle(
                          color: _selectedDate != null ? Colors.black : Colors.grey.shade600
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              const Text('Alasan / Keterangan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tuliskan alasan pengajuan Anda di sini...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE06A00), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alasan tidak boleh kosong';
                  }
                  return null;
                },
              ),

              if (widget.requestType == 'Sakit') ...[
                const SizedBox(height: 24),
                const Text('Lampiran Surat Dokter (Opsional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Unggah Berkas'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: const BorderSide(color: Color(0xFFE06A00)),
                  ),
                ),
              ],

              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE06A00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('KIRIM PENGAJUAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
