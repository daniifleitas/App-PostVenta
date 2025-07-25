import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

final List<Map<String, dynamic>> _seccionesChecklist = [
  {
    'titulo': 'CAÑERÍA DE REFRIGERANTE',
    'preguntas': [
      'La cañería está limpia y bien estibada',
      'Los diámetros y espesores son correctos',
      'La posición de las derivaciones es correcta',
      'La posición de los cabezales es correcta',
      'La distancia entre soportes es la correcta',
      'La soldadura fue realizada con nitrógeno',
      'La aislación es correcta',
      'La distribución es correcta según Reporte',
      'Las distancias son correctas según Reporte',
      'Se realizó prueba de hermeticidad',
      'Las herramientas son las adecuadas',
    ]
  },
  {
    'titulo': 'TUBERÍAS DE DESAGOTE',
    'preguntas': [
      'Las tuberías están instaladas',
      'Los materiales utilizados son adecuados',
      'El recorrido es correcto, pendientes y elevaciones correctas',
      'La tubería está bien soportada',
    ]
  },
  {
    'titulo': 'SUMINISTRO ELÉCTRICO Y BUS DE COMUNICACIÓN',
    'preguntas': [
      'El cable de comunicación es blindado',
      'La interconexión es en forma de guirnalda',
      'El cable de comunicación es de sección igual o mayor a 0,75mm2',
      'Hay terminales instalados',
      'La distancia entre cable de comunicación y suministro eléctrico es la correcta',
      'El suministro de potencia es correcto',
    ]
  },
  {
    'titulo': 'CAJA HEAT RECOVERY',
    'preguntas': [
      'La posición de las cajas es correcta',
      'Están bien soportadas',
      'Se respetó distancia entre caja y derivaciones',
    ]
  },
  {
    'titulo': 'UNIDADES INTERIORES',
    'preguntas': [
      'La ubicación es correcta',
      'Se instalaron accesos de servicio',
      'Se cubrió con nylon una vez instalada',
      'El acceso a la caja eléctrica es correcto',
    ]
  },
  {
    'titulo': 'UNIDAD EXTERIOR',
    'preguntas': [
      'La base es adecuada, tiene goma antivibración',
      'Se fijó la unidad a la base',
      'La cañería cuenta con protección',
      'La ubicación es correcta',
      'El área de servicio es correcta',
      'La ventilación es correcta',
      'EN CASO DE CONDUCTOS DE DESCARGA: la instalación es correcta',
      'La comunicación entre unidades exteriores es correcta',
    ]
  },
];

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  final TextEditingController _nombreObraController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _empresaInstaladoraController = TextEditingController();
  final TextEditingController _sistemaAuditarController = TextEditingController();
  final TextEditingController _contactoObraController = TextEditingController();
  final TextEditingController _auditorController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _visitaNumeroController = TextEditingController();
  final TextEditingController _modeloUnidadController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();

  late List<List<String?>> _respuestas;
  final List<File?> _imagenes = List.filled(3, null);
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List?> _imagenesBytes = List.filled(3, null);

  @override
  void initState() {
    super.initState();
    _inicializarRespuestas();
    _fechaController.text = _formatearFecha(DateTime.now());
  }

  void _inicializarRespuestas() {
    _respuestas = List.generate(
      _seccionesChecklist.length,
          (i) => List.filled(_seccionesChecklist[i]['preguntas'].length, null),
    );
    _respuestas.add([null]); // Para el resultado final
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
      final XFile? image = await _picker.pickImage(source: option);
      if (image != null) {
        if (kIsWeb) {
          // Para web: leer como bytes
          final bytes = await image.readAsBytes();
          setState(() {
            _imagenesBytes[index] = bytes;
            _imagenes[index] = null; // Asegurarse que el File sea null en web
          });
        } else {
          // Para móvil/desktop: usar File normalmente
          setState(() {
            _imagenes[index] = File(image.path);
            _imagenesBytes[index] = null;
          });
        }
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

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(int sectionIndex, int questionIndex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${questionIndex + 1}. ${_seccionesChecklist[sectionIndex]['preguntas'][questionIndex]}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Row(
            children: [
              Radio<String?>(
                value: 'SI',
                groupValue: _respuestas[sectionIndex][questionIndex],
                onChanged: (String? value) {
                  setState(() {
                    _respuestas[sectionIndex][questionIndex] = value;
                  });
                },
                activeColor: const Color(0xFFE00420),
              ),
              const Text('SI', style: TextStyle(fontSize: 12)),
              Radio<String?>(
                value: 'NO',
                groupValue: _respuestas[sectionIndex][questionIndex],
                onChanged: (String? value) {
                  setState(() {
                    _respuestas[sectionIndex][questionIndex] = value;
                  });
                },
                activeColor: const Color(0xFFE00420),
              ),
              const Text('NO', style: TextStyle(fontSize: 12)),
              Radio<String?>(
                value: 'N/C',
                groupValue: _respuestas[sectionIndex][questionIndex],
                onChanged: (String? value) {
                  setState(() {
                    _respuestas[sectionIndex][questionIndex] = value;
                  });
                },
                activeColor: const Color(0xFFE00420),
              ),
              const Text('N/C', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistSection(int sectionIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sectionIndex == 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Por favor complete cada una de las secciones con SI, NO o N/C (no corresponde)',
              style: TextStyle(
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        _buildSeccion(_seccionesChecklist[sectionIndex]['titulo']),
        Column(
          children: List.generate(
            _seccionesChecklist[sectionIndex]['preguntas'].length,
                (questionIndex) => _buildChecklistItem(sectionIndex, questionIndex),
          ),
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
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE00420), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _imagenes[index] != null || _imagenesBytes[index] != null
                ? Stack(
              children: [
                kIsWeb
                    ? Image.memory(_imagenesBytes[index]!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
                    : Image.file(_imagenes[index]!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
                const Positioned(
                  right: 5,
                  top: 5,
                  child: Icon(Icons.edit, color: Colors.white),
                ),
              ],
            )
                : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate,
                  size: 40,
                  color: Color(0xFFE00420),
                ),
                SizedBox(height: 8),
                Text('Toca para agregar imagen',
                    style: TextStyle(color: Color(0xFFE00420))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildObservaciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSeccion('OBSERVACIONES'),
        TextFormField(
          controller: _observacionesController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Escriba observaciones adicionales...',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE00420)),
            ),
            contentPadding: EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _generarPDF() async {
    final currentContext = context;
    if (!mounted) return;

    // Validación de campos obligatorios
    final camposRequeridos = {
      'Nombre de la obra': _nombreObraController.text,
      'Dirección': _direccionController.text,
      'Empresa instaladora': _empresaInstaladoraController.text,
      'Sistema a auditar': _sistemaAuditarController.text,
      'Auditor': _auditorController.text,
    };

    for (var entry in camposRequeridos.entries) {
      if (entry.value.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('${entry.key} es obligatorio')),
        );
        return;
      }
    }

    // Verificar checklist completo
    for (int i = 0; i < _seccionesChecklist.length; i++) {
      for (int j = 0; j < _seccionesChecklist[i]['preguntas'].length; j++) {
        if (_respuestas[i][j] == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Responda la pregunta ${j+1} de ${_seccionesChecklist[i]['titulo']}')),
          );
          return;
        }
      }
    }

    // Verificar resultado final
    if (_respuestas.last[0] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Seleccione si la auditoría está aprobada o rechazada')),
      );
      return;
    }

    try {
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Generando PDF...')),
      );

      final pdf = pw.Document();
      final imageWidgets = await _buildPDFImagenes();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          footer: (pw.Context context) => _buildPDFFooter(context),
          build: (pw.Context pdfContext) {
            return [
              _buildPDFHeader(pdfContext),
              pw.SizedBox(height: 20),
              _buildPDFInformacionGeneral(),
              pw.SizedBox(height: 20),
              ..._buildPDFChecklist(),
              pw.SizedBox(height: 20),
              _buildPDFResultadoFinal(),
              pw.SizedBox(height: 20),
              _buildPDFObservaciones(),
              pw.SizedBox(height: 20),
              ...imageWidgets,
              pw.SizedBox(height: 30),
            ];
          },
        ),
      );

      await _guardarYAbrirPDF(pdf);

      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('PDF generado con éxito')),
      );
    } catch (e, stackTrace) {
      debugPrint('Error al generar PDF: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Widget _buildPDFHeader(pw.Context pdfContext) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'INFORME DE AUDITORÍA',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#E11931'),
          ),
        ),
        pw.Text(
          'Fecha: ${_fechaController.text}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildPDFInformacionGeneral() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColor.fromHex('#E11931'), width: 0.5),
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Nombre de la obra:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_nombreObraController.text),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Dirección:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_direccionController.text),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Empresa instaladora:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_empresaInstaladoraController.text),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Sistema a auditar:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_sistemaAuditarController.text),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Contacto en obra:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_contactoObraController.text.isNotEmpty
                  ? _contactoObraController.text
                  : 'No especificado'),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Auditor:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_auditorController.text),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Visita N°:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_visitaNumeroController.text.isNotEmpty
                  ? _visitaNumeroController.text
                  : 'No especificado'),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Modelo de unidad/es exterior/es:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_modeloUnidadController.text.isNotEmpty
                  ? _modeloUnidadController.text
                  : 'No especificado'),
            ),
          ],
        ),
      ],
    );
  }

  List<pw.Widget> _buildPDFChecklist() {
    List<pw.Widget> widgets = [];

    for (int sectionIndex = 0; sectionIndex < _seccionesChecklist.length; sectionIndex++) {
      final seccion = _seccionesChecklist[sectionIndex];

      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              seccion['titulo'],
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#E11931'),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(5),
                1: const pw.FixedColumnWidth(50),
                2: const pw.FixedColumnWidth(50),
                3: const pw.FixedColumnWidth(50),
              },
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                // Encabezado de la tabla
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Pregunta',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.left, // Alineación izquierda
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'SI',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'NO',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'N/C',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),

                // Filas de preguntas
                ...List.generate(seccion['preguntas'].length, (questionIndex) {
                  final respuesta = _respuestas[sectionIndex][questionIndex];

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.white),
                    children: [
                      // Texto de la pregunta (alineado a la izquierda)
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${questionIndex + 1}. ${seccion['preguntas'][questionIndex]}',
                          style: const pw.TextStyle(fontSize: 10),
                          textAlign: pw.TextAlign.left,
                        ),
                      ),

                      // Columna SI
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: respuesta == 'SI'
                            ? pw.Text(
                          'X',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColor.fromHex('#4CAF50'),
                            fontWeight: pw.FontWeight.bold,
                          ),
                        )
                            : pw.Text(' '),
                      ),

                      // Columna NO
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: respuesta == 'NO'
                            ? pw.Text(
                          'X',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColor.fromHex('#F44336'),
                            fontWeight: pw.FontWeight.bold,
                          ),
                        )
                            : pw.Text(' '),
                      ),

                      // Columna N/C
                      pw.Container(
                        alignment: pw.Alignment.center,
                        child: respuesta == 'N/C'
                            ? pw.Text(
                          'X',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColor.fromHex('#FF9800'),
                            fontWeight: pw.FontWeight.bold,
                          ),
                        )
                            : pw.Text(' '),
                      ),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
          ],
        ),
      );
    }
    return widgets;
  }

  pw.Widget _buildPDFResultadoFinal() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F5F5F5')),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(
                'RESULTADO DE LA AUDITORÍA',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(
                'APROBADA',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(
                'RECHAZADA',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Text(
                'La auditoría se encuentra aprobada',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              child: _respuestas.last[0] == 'SI'
                  ? pw.Text(
                'SI',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromHex('#4CAF50'),
                  fontWeight: pw.FontWeight.bold,
                ),
              )
                  : pw.Container(),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              child: _respuestas.last[0] == 'NO'
                  ? pw.Text(
                'NO',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColor.fromHex('#F44336'),
                  fontWeight: pw.FontWeight.bold,
                ),
              )
                  : pw.Container(),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFObservaciones() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'OBSERVACIONES',
          style: pw.TextStyle(
            fontSize: 14,
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
            _observacionesController.text.isNotEmpty
                ? _observacionesController.text
                : 'No se registraron observaciones',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<List<pw.Widget>> _buildPDFImagenes() async {
    final widgets = <pw.Widget>[
      pw.Text(
        'IMÁGENES',
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#E11931'),
        ),
      ),
      pw.SizedBox(height: 8),
    ];

    for (int i = 0; i < 3; i++) { // Para las 3 imágenes
      Uint8List? imageBytes;

      if (kIsWeb) {
        imageBytes = _imagenesBytes[i];
      } else {
        final image = _imagenes[i];
        if (image != null && image.existsSync()) {
          imageBytes = await image.readAsBytes();
        }
      }

      if (imageBytes == null) continue;

      String getImageTitle(int index) {
        switch (index) {
          case 0: return 'Unidad exterior o lugar de instalación';
          case 1: return 'Corte de cañería';
          case 2: return 'Derivaciones';
          default: return 'Imagen ${index + 1}';
        }
      }

      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              getImageTitle(i),
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Image(
              pw.MemoryImage(imageBytes),
              width: 300,
              height: 200,
              fit: pw.BoxFit.contain,
            ),
            pw.SizedBox(height: 12),
          ],
        ),
      );
    }

    if (widgets.length == 2) {
      widgets.add(
        pw.Text(
          'No se adjuntaron imágenes',
          style: const pw.TextStyle(fontSize: 12),
        ),
      );
    }

    return widgets;
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
      final path = '${directory.path}/InformeAuditoria_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);

      await file.writeAsBytes(bytes);
      await OpenFile.open(path);
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
            _buildTextField(_nombreObraController, 'Nombre de la obra*'),
            _buildTextField(_direccionController, 'Dirección*'),
            _buildTextField(_empresaInstaladoraController, 'Empresa instaladora*'),
            _buildTextField(_sistemaAuditarController, 'Sistema a auditar*'),
            _buildTextField(_contactoObraController, 'Contacto en obra'),
            _buildTextField(_auditorController, 'Auditor*'),
            _buildTextField(_fechaController, 'Fecha (dd/mm/aaaa)'),
            _buildTextField(_visitaNumeroController, 'Visita N°'),
            _buildTextField(_modeloUnidadController, 'Modelo de unidad/es exterior/es'),

            ...List.generate(_seccionesChecklist.length, (index) {
              return _buildChecklistSection(index);
            }),

            _buildSeccion('RESULTADO DE LA AUDITORÍA'),
            Row(
              children: [
                const Expanded(child: Text('La auditoría se encuentra aprobada')),
                Row(
                  children: [
                    Radio<String?>(
                      value: 'SI',
                      groupValue: _respuestas.last[0],
                      onChanged: (String? value) {
                        setState(() {
                          _respuestas.last[0] = value;
                        });
                      },
                      activeColor: const Color(0xFFE11931),
                    ),
                    const Text('SI'),
                    Radio<String?>(
                      value: 'NO',
                      groupValue: _respuestas.last[0],
                      onChanged: (String? value) {
                        setState(() {
                          _respuestas.last[0] = value;
                        });
                      },
                      activeColor: const Color(0xFFE11931),
                    ),
                    const Text('NO'),
                  ],
                ),
              ],
            ),

            _buildSeccion('IMÁGENES REQUERIDAS'),
            _buildImagePicker(0, 'Unidad exterior o lugar de instalación'),
            _buildImagePicker(1, 'Corte de cañería'),
            _buildImagePicker(2, 'Derivaciones'),

            _buildObservaciones(),

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
    _sistemaAuditarController.dispose();
    _contactoObraController.dispose();
    _auditorController.dispose();
    _fechaController.dispose();
    _visitaNumeroController.dispose();
    _modeloUnidadController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }
}