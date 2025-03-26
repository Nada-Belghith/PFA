import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:animated_background/animated_background.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pfa/services/quorum_service.dart';
import '../models/scan_result.dart';

class RamasseurScreen extends StatefulWidget {
  const RamasseurScreen({super.key, required this.title});
  final String title;

  @override
  State<RamasseurScreen> createState() => _RamasseurScreenState();
}

class _RamasseurScreenState extends State<RamasseurScreen>
    with TickerProviderStateMixin {
  int bouteillesRamassees = 0;
  double gainTotal = 0.0;
  final ImagePicker _picker = ImagePicker();
  final MobileScannerController cameraController = MobileScannerController();
  late final QuorumService _quorumService;

  @override
  void initState() {
    super.initState();
    _quorumService = QuorumService(
      rpcUrl: QuorumService.defaultRpcUrl,
      privateKey: 'VOTRE_CLE_PRIVEE_ICI', // Clé obtenue de accountkey
    );
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final address = 'YOUR_WALLET_ADDRESS'; // L'adresse du collecteur
      final transactions =
          await _quorumService.getCollectorTransactions(address);

      setState(() {
        bouteillesRamassees =
            transactions.fold(0, (sum, tx) => sum + tx.bottleCount);
        gainTotal = transactions.fold(0.0, (sum, tx) => sum + tx.amount);
      });
    } catch (e) {
      print('Error loading history: $e');
    }
  }

  Future<void> _scannerCodeQR() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Utiliser la caméra'),
                onTap: () async {
                  Navigator.pop(context);
                  await _scannerAvecCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Choisir une image'),
                onTap: () async {
                  Navigator.pop(context);
                  await _choisirImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Zone de dépôt QR'),
                onTap: () {
                  Navigator.pop(context);
                  _afficherZoneDepot();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scannerAvecCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Scanner QR Code'),
              backgroundColor: Colors.green,
            ),
            body: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    Navigator.pop(context);
                    _showConfirmationDialog(barcode.rawValue!);
                  }
                }
              },
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission de la caméra refusée'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _choisirImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _traiterImage(File(image.path));
    }
  }

  void _afficherZoneDepot() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: DragTarget<String>(
            builder: (context, candidateData, rejectedData) {
              return Container(
                height: 300,
                padding: const EdgeInsets.all(20),
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  padding: const EdgeInsets.all(6),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_upload, size: 50),
                        const SizedBox(height: 10),
                        const Text('Déposez votre image QR code ici'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null) {
                              _traiterImage(File(result.files.single.path!));
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Ou cliquez pour choisir'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            // ignore: deprecated_member_use
            onAccept: (String data) {
              // Traiter le fichier déposé
              _traiterImage(File(data));
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Future<void> _traiterImage(File file) async {
    try {
      final result = await cameraController.analyzeImage(file.path);
      if (result!.barcodes.isNotEmpty) {
        final barcode = result.barcodes.first;
        if (barcode.rawValue != null) {
          _showConfirmationDialog(barcode.rawValue!);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun QR code trouvé dans l\'image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la lecture du QR code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showConfirmationDialog(String qrData) {
    try {
      final result = ScanResult.fromQRString(qrData);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirmation de collecte',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('ID poubelle', result.evenement),
                _buildInfoRow('Date', result.date),
                _buildInfoRow('Heure', result.heure),
                _buildInfoRow('Bouteilles ramassées',
                    result.nouvellesBouteilles.toString()),
                _buildInfoRow('Gain de la collecte',
                    '${result.gainCollecte.toStringAsFixed(3)} DT'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final txHash =
                        await _quorumService.sendCollectionTransaction(
                      trashBinId: result.evenement,
                      bottleCount: result.nouvellesBouteilles,
                      amount: result.gainCollecte,
                      date: result.date,
                      time: result.heure,
                    );

                    setState(() {
                      bouteillesRamassees += result.nouvellesBouteilles;
                      gainTotal += result.gainCollecte;
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Transaction confirmée: $txHash'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR code invalide'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          Text(value, style: GoogleFonts.poppins()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
          options: const ParticleOptions(
            spawnMinRadius: 2.0,
            spawnMaxRadius: 3.0,
            particleCount: 70,
            spawnMinSpeed: 10.0,
            spawnMaxSpeed: 50.0,
            baseColor: Colors.green,
          ),
        ),
        vsync: this,
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(
                  widget.title,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StatCard(
                        icon: Icons.local_drink,
                        value: bouteillesRamassees.toString(),
                        label: 'Bouteilles Ramassées',
                        color: Colors.blue,
                      ).animate().fadeIn().scale(),
                      const SizedBox(height: 20),
                      StatCard(
                        icon: Icons.monetization_on,
                        value: '${gainTotal.toStringAsFixed(3)} DT',
                        label: 'Gains Totaux',
                        color: Colors.green,
                      ).animate().fadeIn().scale(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scannerCodeQR,
        label: const Text('Scanner'),
        icon: const Icon(Icons.qr_code_scanner),
        elevation: 4,
      ).animate().fadeIn().scale(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  @override
  void dispose() {
    _quorumService.dispose();
    cameraController.dispose();
    super.dispose();
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
