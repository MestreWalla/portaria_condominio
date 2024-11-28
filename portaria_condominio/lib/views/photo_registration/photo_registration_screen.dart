import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../controllers/morador_controller.dart';

class PhotoRegistrationScreen extends StatefulWidget {
  final String userType;
  final String userId;
  final bool returnPhotoData;

  const PhotoRegistrationScreen({
    super.key,
    required this.userType,
    required this.userId,
    this.returnPhotoData = false,
  });

  @override
  _PhotoRegistrationScreenState createState() => _PhotoRegistrationScreenState();
}

class _PhotoRegistrationScreenState extends State<PhotoRegistrationScreen> {
  final ImagePicker _picker = ImagePicker();
  final MoradorController _moradorController = MoradorController();
  File? _imageFile;
  bool _isUploading = false;
  String? _uploadStatus;
  Uint8List? _compressedImageBytes;

  Future<void> _captureAndProcessPhoto() async {
    if (_isUploading) return;

    try {
      // Captura a foto com qualidade reduzida
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 70,
      );

      if (photo == null) return;

      if (!mounted) return;

      setState(() {
        _imageFile = File(photo.path);
        _isUploading = true;
        _uploadStatus = 'Processando foto...';
      });

      // Lê o arquivo como bytes e converte para Uint8List
      final Uint8List imageBytes = await _imageFile!.readAsBytes();
      
      // Comprime a imagem diretamente para Uint8List
      _compressedImageBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: 50,
        minHeight: 500,
        minWidth: 375,
        rotate: 0,
      );

      if (_compressedImageBytes == null) {
        throw Exception('Falha ao comprimir a imagem');
      }

      print('Imagem comprimida com sucesso');
      print('Tamanho dos bytes comprimidos: ${_compressedImageBytes!.length}');

      // Converte para base64 (sem prefixo)
      final base64Image = base64Encode(_compressedImageBytes!);
      
      print('Imagem convertida para base64');
      print('Tamanho do base64: ${base64Image.length}');

      // Limpa o arquivo temporário
      await _imageFile!.delete();

      if (!mounted) return;

      setState(() {
        _isUploading = false;
        _uploadStatus = 'Foto processada com sucesso!';
      });

      // Aguarda um pequeno delay antes de fechar a tela
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Retorna o resultado apropriado baseado no parâmetro returnPhotoData
      if (widget.returnPhotoData) {
        print('Retornando dados da foto para a tela de cadastro');
        Navigator.of(context).pop(base64Image);
      } else {
        print('Salvando foto diretamente no banco');
        // Se não precisamos retornar os dados da foto, tentamos salvá-la diretamente
        try {
          await _moradorController.atualizarFotoMorador(widget.userId, base64Image);
          print('Foto salva com sucesso no banco');
          Navigator.of(context).pop(true);
        } catch (e) {
          print('Erro ao salvar foto no banco: $e');
          throw Exception('Falha ao salvar foto: $e');
        }
      }

    } catch (e) {
      if (!mounted) return;
      _handleError(e);
    }
  }

  void _handleError(dynamic error) {
    if (!mounted) return;
    
    setState(() {
      _isUploading = false;
      _uploadStatus = 'Erro ao processar foto';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erro ao processar foto: ${error.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Tentar Novamente',
          textColor: Colors.white,
          onPressed: _captureAndProcessPhoto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isUploading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, aguarde o processamento da foto.'),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registrar Foto'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_compressedImageBytes != null)
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: MemoryImage(_compressedImageBytes!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 80,
                    color: Colors.grey[600],
                  ),
                ),
              const SizedBox(height: 32),
              if (_isUploading)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(_uploadStatus ?? 'Processando...'),
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: _captureAndProcessPhoto,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_compressedImageBytes == null ? 'Tirar Foto' : 'Tirar Nova Foto'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
