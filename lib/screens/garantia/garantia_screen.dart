import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;

class GarantiaScreen extends StatefulWidget {
  const GarantiaScreen({super.key});

  @override
  State<GarantiaScreen> createState() => _GarantiaScreenState();
}

class _GarantiaScreenState extends State<GarantiaScreen> {
  // Controladores para campos de texto
  final TextEditingController _nombreObraController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _empresaInstaladoraController = TextEditingController();
  final TextEditingController _contactoObraController = TextEditingController();
  final TextEditingController _responsableController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _visitaNumeroController = TextEditingController();
  final TextEditingController _modeloEquipoController = TextEditingController();
  final TextEditingController _numeroSerieController = TextEditingController();
  final TextEditingController _fallaErrorController = TextEditingController();
  final TextEditingController _diagnosticoController = TextEditingController();
  final TextEditingController _procedimientoController = TextEditingController();
  final TextEditingController _repuestoNecesarioController = TextEditingController();
  final TextEditingController _codigoRepuestoController = TextEditingController();

  // Imágenes
  final List<File?> _imagenes = List.filled(3, null);
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List?> _imagenesBytes = List.filled(3, null);

  // Variable para controlar si corresponde a garantía
  bool? _correspondeGarantia;

  // ESTILOS UNIFICADOS PARA PDF
  final _tableHeaderStyle = pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: PdfColors.black,
  );

  final _tableBorder = pw.TableBorder.all(
    color: PdfColors.grey,
    width: 0.5,
  );

  final _tableTextStyle = const pw.TextStyle(
    fontSize: 10,
  );

  @override
  void initState() {
    super.initState();
    _fechaController.text = _formatearFecha(DateTime.now());
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }

  Future<void> _seleccionarImagen(int index) async {
    final option = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFFE00420)),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFFE00420)),
            title: const Text('Elegir de galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (option != null) {
      try {
        final XFile? image = await _picker.pickImage(source: option);
        if (image != null) {
          final bytes = await image.readAsBytes(); // Esta línea ahora SÍ se usa
          setState(() {
            _imagenes[index] = File(image.path);
            _imagenesBytes[index] = bytes; // Aquí usamos los bytes
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar imagen: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE00420),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obligatorio = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: '$label${obligatorio ? '*' : ''}',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildGarantiaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSeccion('¿CORRESPONDE A GARANTÍA?'),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('SÍ'),
                leading: Radio<bool?>(
                  value: true,
                  groupValue: _correspondeGarantia,
                  onChanged: (bool? value) {
                    setState(() {
                      _correspondeGarantia = value;
                    });
                  },
                  activeColor: Colors.green,
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('NO'),
                leading: Radio<bool?>(
                  value: false,
                  groupValue: _correspondeGarantia,
                  onChanged: (bool? value) {
                    setState(() {
                      _correspondeGarantia = value;
                    });
                  },
                  activeColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePicker(int index, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _seleccionarImagen(index),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE00420), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _imagenesBytes[index] != null
                ? Image.memory(
              _imagenesBytes[index]!,
              fit: BoxFit.cover,
            )
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate,
                  size: 50,
                  color: Color(0xFFE00420),
                ),
                SizedBox(height: 8),
                Text('Toca para agregar imagen',
                    style: TextStyle(color: Color(0xFFE00420))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  bool _validarCamposCompletos() {
    if (_nombreObraController.text.isEmpty ||
        _direccionController.text.isEmpty ||
        _empresaInstaladoraController.text.isEmpty ||
        _responsableController.text.isEmpty ||
        _modeloEquipoController.text.isEmpty ||
        _fallaErrorController.text.isEmpty ||
        _diagnosticoController.text.isEmpty ||
        _procedimientoController.text.isEmpty ||
        _correspondeGarantia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos obligatorios marcados con *')),
      );
      return false;
    }
    return true;
  }

  pw.Widget _buildPDFHeader() { // Eliminamos el parámetro de contexto
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INFORME DE GARANTÍA',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#E11931'),
          ),
        ),
        pw.Text(
          'Fecha: ${_fechaController.text}',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildPDFInformacionGeneral() {
    return pw.Table(
      border: _tableBorder,
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Nombre de la obra:', style: _tableHeaderStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_nombreObraController.text, style: _tableTextStyle),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Dirección:', style: _tableHeaderStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_direccionController.text, style: _tableTextStyle),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Empresa instaladora:', style: _tableHeaderStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_empresaInstaladoraController.text, style: _tableTextStyle),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Contacto en obra:', style: _tableHeaderStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_contactoObraController.text.isNotEmpty
                  ? _contactoObraController.text
                  : 'No especificado', style: _tableTextStyle),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Responsable:', style: _tableHeaderStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_responsableController.text, style: _tableTextStyle),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Visita N°:', style: _tableHeaderStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_visitaNumeroController.text.isNotEmpty
                  ? _visitaNumeroController.text
                  : 'No especificado', style: _tableTextStyle),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Modelo del equipo:', style: _tableHeaderStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_modeloEquipoController.text, style: _tableTextStyle),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFFallaError() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'FALLA O ERROR REPORTADO',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#E11931'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            _fallaErrorController.text,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPDFDiagnostico() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DIAGNÓSTICO',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#E11931'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            _diagnosticoController.text,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPDFGarantia() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '¿CORRESPONDE A GARANTÍA?',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#E11931'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Text('SÍ: ', style: _tableTextStyle),
                  _correspondeGarantia == true
                      ? pw.Text(
                    'X',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.green,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  )
                      : pw.Text(''),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Text('NO: ', style: _tableTextStyle),
                  _correspondeGarantia == false
                      ? pw.Text(
                    'X',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.red,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  )
                      : pw.Text(''),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildPDFProcedimiento() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PROCEDIMIENTO PARA LA SOLUCIÓN DEL PROBLEMA',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#E11931'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            _procedimientoController.text,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPDFRepuestos() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'REPUESTOS REQUERIDOS',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#E11931'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: _tableBorder,
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Repuesto', style: _tableHeaderStyle),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Código', style: _tableHeaderStyle),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    _repuestoNecesarioController.text.isNotEmpty
                        ? _repuestoNecesarioController.text
                        : 'No se requirieron repuestos',
                    style: _tableTextStyle,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    _codigoRepuestoController.text.isNotEmpty
                        ? _codigoRepuestoController.text
                        : '-',
                    style: _tableTextStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFImagenes() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'IMÁGENES',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#E11931'),
          ),
        ),
        pw.SizedBox(height: 8),

        // Imagen 1 - Etiqueta del equipo
        pw.Column(
          children: [
            pw.Text(
              'Etiqueta del equipo',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            _imagenes[0] != null
                ? pw.Container(
              width: double.infinity,
              child: pw.Image(
                pw.MemoryImage(_imagenes[0]!.readAsBytesSync()),
                fit: pw.BoxFit.contain,
              ),
            )
                : pw.Text(
              'No disponible',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
          ],
        ),

        // Imagen 2 - Repuesto dañado
        pw.Column(
          children: [
            pw.Text(
              'Repuesto dañado',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            _imagenes[1] != null
                ? pw.Container(
              width: double.infinity,
              child: pw.Image(
                pw.MemoryImage(_imagenes[1]!.readAsBytesSync()),
                fit: pw.BoxFit.contain,
              ),
            )
                : pw.Text(
              'No disponible',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 20),
          ],
        ),

        // Imagen 3 - Otra imagen
        pw.Column(
          children: [
            pw.Text(
              'Otra imagen relevante',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            _imagenes[2] != null
                ? pw.Container(
              width: double.infinity,
              child: pw.Image(
                pw.MemoryImage(_imagenes[2]!.readAsBytesSync()),
                fit: pw.BoxFit.contain,
              ),
            )
                : pw.Text(
              'No disponible',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFFooter(pw.Context pdfContext) {
    return pw.Container(
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Cliente: ${_empresaInstaladoraController.text}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          if (pdfContext.pageNumber != null)
            pw.Text(
              'Página ${pdfContext.pageNumber}',
              style: const pw.TextStyle(fontSize: 10),
            )
          else
            pw.Text(
              'Página -',
              style: const pw.TextStyle(fontSize: 10),
            ),
        ],
      ),
    );
  }

  Future<void> _guardarYAbrirPDF(pw.Document pdf) async {
    final bytes = await pdf.save();

    if (kIsWeb) {
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } else {
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/InformeGarantia_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);

      await file.writeAsBytes(bytes);
      await OpenFile.open(path);
    }
  }

  Future<void> _generarPDF() async {
    if (!_validarCamposCompletos()) return;

    try {
      final pdf = pw.Document();
      final List<pw.Widget> pdfWidgets = [];

      // 1. Añadir todos los widgets excepto imágenes
      pdfWidgets.addAll([
        _buildPDFHeader(),
        pw.SizedBox(height: 20),
        _buildPDFInformacionGeneral(),
        pw.SizedBox(height: 20),
        _buildPDFFallaError(),
        pw.SizedBox(height: 20),
        _buildPDFDiagnostico(),
        pw.SizedBox(height: 20),
        _buildPDFGarantia(),
        _buildPDFProcedimiento(),
        pw.SizedBox(height: 20),
        _buildPDFRepuestos(),
        pw.SizedBox(height: 20),
      ]);

      // 2. Procesar imágenes que ya fueron seleccionadas
      final List<pw.Widget> imageWidgets = [];

      for (int i = 0; i < _imagenesBytes.length; i++) {
        if (_imagenesBytes[i] != null) {
          try {
            imageWidgets.add(
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    i == 0 ? 'Etiqueta del equipo' :
                    i == 1 ? 'Repuesto dañado' : 'Otra imagen relevante',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Image(
                    pw.MemoryImage(_imagenesBytes[i]!),
                    width: 300,
                    height: 200,
                    fit: pw.BoxFit.contain,
                  ),
                  pw.SizedBox(height: 20),
                ],
              ),
            );
          } catch (e) {
            debugPrint('Error procesando imagen $i: $e');
            imageWidgets.add(
              pw.Text('Error al mostrar imagen ${i + 1}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.red)),
            );
          }
        }
      }

      // 3. Añadir sección de imágenes si hay imágenes
      if (imageWidgets.isNotEmpty) {
        pdfWidgets.add(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'IMÁGENES',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#E11931'),
                ),
              ),
              pw.SizedBox(height: 8),
              ...imageWidgets,
            ],
          ),
        );
      }

      // 4. Generar el PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          footer: (pw.Context context) => _buildPDFFooter(context),
          build: (pw.Context context) => pdfWidgets,
        ),
      );

      await _guardarYAbrirPDF(pdf);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SvgPicture.asset(
          'assets/logo.png',
          height: 32,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE00420),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeccion('DATOS GENERALES'),
            _buildTextField(_nombreObraController, 'Nombre de la obra', obligatorio: true),
            _buildTextField(_direccionController, 'Dirección', obligatorio: true),
            _buildTextField(_empresaInstaladoraController, 'Empresa instaladora', obligatorio: true),
            _buildTextField(_contactoObraController, 'Contacto en obra'),
            _buildTextField(_responsableController, 'Supervisor de garantía', obligatorio: true),
            _buildTextField(_fechaController, 'Fecha (dd/mm/aaaa)'),
            _buildTextField(_visitaNumeroController, 'Visita N°'),
            _buildTextField(_modeloEquipoController, 'Modelo de equipo que posee la falla', obligatorio: true),


            _buildSeccion('INDIQUE FALLA O ERROR'),
            _buildTextField(_fallaErrorController, 'Describa la falla o error reportado', obligatorio: true, maxLines: 3),

            _buildSeccion('DIAGNÓSTICO'),
            _buildTextField(_diagnosticoController, 'Describa el diagnóstico realizado', obligatorio: true, maxLines: 3),

            _buildGarantiaSection(),

            _buildSeccion('PROCEDIMIENTO PARA LA SOLUCIÓN DEL PROBLEMA'),
            _buildTextField(_procedimientoController, 'Describa el procedimiento realizado o los pasos a seguir para la solución de la falla', obligatorio: true, maxLines: 4),

            _buildSeccion('REPUESTOS REQUERIDOS'),
            _buildTextField(_repuestoNecesarioController, 'Indique el repuesto necesario (si aplica)'),
            _buildTextField(_codigoRepuestoController, 'Código del repuesto (si aplica)'),

            _buildImagePicker(0, 'IMAGEN DE LA ETIQUETA DEL EQUIPO DAÑADO'),
            _buildImagePicker(1, 'IMAGEN DEL REPUESTO DAÑADO (EN CASO DE SER REQUERIDO)'),
            _buildImagePicker(2, 'OTRA IMAGEN RELEVANTE'),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generarPDF,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11931),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'GENERAR INFORME PDF',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreObraController.dispose();
    _direccionController.dispose();
    _empresaInstaladoraController.dispose();
    _contactoObraController.dispose();
    _responsableController.dispose();
    _fechaController.dispose();
    _visitaNumeroController.dispose();
    _modeloEquipoController.dispose();
    _numeroSerieController.dispose();
    _fallaErrorController.dispose();
    _diagnosticoController.dispose();
    _procedimientoController.dispose();
    _repuestoNecesarioController.dispose();
    _codigoRepuestoController.dispose();
    super.dispose();
  }
}