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
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;


class PuestaMarchaScreen extends StatefulWidget {
  const PuestaMarchaScreen({super.key});

  @override
  State<PuestaMarchaScreen> createState() => _PuestaMarchaScreenState();
}

class _PuestaMarchaScreenState extends State<PuestaMarchaScreen> {
  // Controladores para campos de texto
  final TextEditingController _nombreObraController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _empresaInstaladoraController = TextEditingController();
  final TextEditingController _contactoObraController = TextEditingController();
  final TextEditingController _responsableController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _visitaNumeroController = TextEditingController();
  final TextEditingController _modeloPrincipalController = TextEditingController();
  final TextEditingController _modeloEsclava1Controller = TextEditingController();
  final TextEditingController _modeloEsclava2Controller = TextEditingController();
  final TextEditingController _modeloEsclava3Controller = TextEditingController();
  final TextEditingController _modeloEsclava4Controller = TextEditingController();
  final TextEditingController _relacionCombinacionController = TextEditingController();
  final TextEditingController _capacidadInterruptorController = TextEditingController();
  final TextEditingController _observacionesController = TextEditingController();

  // Respuestas del checklist
  late List<List<String?>> _respuestas;
  final List<Map<String, dynamic>> _respuestasMainEsclavas = [
    {
      'pregunta': 'Capacidad de los módulos, ¿Es correcta la configuración del bloque DSW2 para todos los módulos exteriores?',
      'main': false,
      'slave1': false,
      'slave2': false,
      'slave3': false,
    },
    {
      'pregunta': 'Combinación de unidades base, ¿Es correcta la configuración del bloque DSW6 para todos los módulos exteriores?',
      'main': false,
      'slave1': false,
      'slave2': false,
      'slave3': false,
    },
    {
      'pregunta': "Modo de operación, ¿Es correcta la configuración del bloque DSW7 para todos los módulos exteriores?",
      'main': false,
      'slave1': false,
      'slave2': false,
      'slave3': false,
    },
    {
      'pregunta': 'Flujo de aire de la unidad exterior, ¿Es correcta la configuración del bloque DSW8 para todos los módulos exteriores?',
      'main': false,
      'slave1': false,
      'slave2': false,
      'slave3': false,
    },
  ];

  final List<File?> _imagenes = List.filled(2, null);
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List?> _imagenesBytes = List.filled(3, null);

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
    _inicializarRespuestas();
    _fechaController.text = _formatearFecha(DateTime.now());
  }

  void _inicializarRespuestas() {
    _respuestas = [
      List.filled(3, null),
      List.filled(5, null),
      List.filled(4, null),
      List.filled(6, null),
      List.filled(3, null),
      List.filled(5, null),
    ];
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

  Widget _buildTextField(TextEditingController controller, String label, {bool obligatorio = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: '$label${obligatorio ? '*' : ''}',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(int sectionIndex, int questionIndex, String pregunta) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              '${questionIndex + 1}. $pregunta',
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

  Widget _buildChecklistSection(int sectionIndex, String titulo, List<String> preguntas) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        _buildSeccion(titulo),
    Column(
    children: List.generate(
    preguntas.length,
    (questionIndex) => _buildChecklistItem(sectionIndex, questionIndex, preguntas[questionIndex]),
    ),
    ),
    ],
    );
  }

  Widget _buildMainEsclavaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSeccion('CONFIGURACIÓN'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 12,
            columns: const [
              DataColumn(
                label: Text('Pregunta', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              DataColumn(label: Text('Main', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('Slave 1', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('Slave 2', style: TextStyle(fontSize: 12))),
              DataColumn(label: Text('Slave 3', style: TextStyle(fontSize: 12))),
            ],
            rows: _respuestasMainEsclavas.map((pregunta) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 400,
                      child: Text(
                        '${_respuestasMainEsclavas.indexOf(pregunta) + 1}. ${pregunta['pregunta']}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Checkbox(
                        value: pregunta['main'],
                        onChanged: (value) => setState(() => pregunta['main'] = value),
                      ),
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Checkbox(
                        value: pregunta['slave1'],
                        onChanged: (value) => setState(() => pregunta['slave1'] = value),
                      ),
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Checkbox(
                        value: pregunta['slave2'],
                        onChanged: (value) => setState(() => pregunta['slave2'] = value),
                      ),
                    ),
                  ),
                  DataCell(
                    Center(
                      child: Checkbox(
                        value: pregunta['slave3'],
                        onChanged: (value) => setState(() => pregunta['slave3'] = value),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
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

  Widget _buildNumericalField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  bool _validarChecklistCompleto() {
    for (int i = 0; i < _respuestas.length; i++) {
      for (int j = 0; j < _respuestas[i].length; j++) {
        if (_respuestas[i][j] == null) {
          debugPrint('Falta responder: Sección $i, Pregunta ${j + 1}');
          return false;
        }
      }
    }

    for (var pregunta in _respuestasMainEsclavas) {
      if (pregunta['main'] == null ||
          pregunta['slave1'] == null ||
          pregunta['slave2'] == null ||
          pregunta['slave3'] == null) {
        debugPrint('Falta responder pregunta Main-Esclavas');
        return false;
      }
    }

    if (_relacionCombinacionController.text.isEmpty ||
        _capacidadInterruptorController.text.isEmpty) {
      debugPrint('Falta completar campos numéricos');
      return false;
    }

    return true;
  }

  pw.Widget _buildPDFHeader(pw.Context pdfContext) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'INFORME DE ARRANQUE PARA EQUIPOS DE VRF',
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
              child: pw.Text('Responsable de la puesta en marcha:', style: _tableHeaderStyle),
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
              child: pw.Text('Modelo de unidad exterior principal:', style: _tableHeaderStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_modeloPrincipalController.text.isNotEmpty
                  ? _modeloPrincipalController.text
                  : 'No especificado', style: _tableTextStyle),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Modelo de unidad exterior esclava 1:', style: _tableHeaderStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_modeloEsclava1Controller.text.isNotEmpty
                  ? _modeloEsclava1Controller.text
                  : 'No especificado', style: _tableTextStyle),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Modelo de unidad exterior esclava 2:', style: _tableHeaderStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_modeloEsclava2Controller.text.isNotEmpty
                  ? _modeloEsclava2Controller.text
                  : 'No especificado', style: _tableTextStyle),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Modelo de unidad exterior esclava 3:', style: _tableHeaderStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_modeloEsclava3Controller.text.isNotEmpty
                  ? _modeloEsclava3Controller.text
                  : 'No especificado', style: _tableTextStyle),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Modelo de unidad exterior esclava 4:', style: _tableHeaderStyle),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_modeloEsclava4Controller.text.isNotEmpty
                  ? _modeloEsclava4Controller.text
                  : 'No especificado', style: _tableTextStyle),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPDFImagenDiagrama() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DIAGRAMA DE TUBERÍAS',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#E11931'),
          ),
        ),
        pw.SizedBox(height: 8),
        _imagenes[0] != null || _imagenesBytes[0] != null
            ? pw.Image(
          pw.MemoryImage(
              kIsWeb
                  ? _imagenesBytes[0]!
                  : _imagenes[0]!.readAsBytesSync()
          ),
          width: 400,
          height: 250,
          fit: pw.BoxFit.contain,
        )
            : pw.Text(
          'No se adjuntó diagrama de tuberías',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  List<pw.Widget> _buildPDFChecklist() {
    final secciones = [
      {
        'titulo': 'INSTALADOR',
        'preguntas': [
          'Participó en el curso de entrenamiento de instalación y puesta en marcha',
          'Cuenta con la herramienta necesaria (Vacuómetro, báscula digital, manómetros para refrigerante R-410, herramienta de mano)',
          'El instalador cuenta con los planos o diagramas del proyecto y están corresponde a lo instalado en sitio',
        ],
        'campoNumerico': 'Relación de combinación del sistema %:'
      },
      {
        'titulo': 'UNIDAD EXTERIOR',
        'preguntas': [
          'La unidad cuenta con los espacios requeridos para operación y servicio',
          'La unidad cuenta con la base de concreto y/o acero además del aislamiento de neopreno',
          'La unidad cuenta con tratamiento anticorrosivo y barrera contra brisa marina',
          'La unidad cuenta con dispositivo local de desconexión de energía eléctrica',
          'La unidad cuenta con los deflectores adecuados para su óptima operación',
        ]
      },
      {
        'titulo': 'SUMINISTRO ELECTRICO',
        'preguntas': [
          'La unidad cuenta con terminales eléctricas en el suministro de fuerza',
          'La unidad cuenta con tierra física',
          'El calibre del cable conductor de la línea de fuerza es el adecuado',
          'La canalización del cable de fuerza va separada de la de control en condensador y evaporadores',
        ],
        'campoNumerico': 'Capacidad del interruptor termomagnético (A):'
      },
      {
        'titulo': 'COMUNICACIÓN',
        'preguntas': [
          'El calibre del cable conductor de la línea de señal es el adecuado',
          'La línea de comunicación unidad cuenta con blindaje',
          'El blindaje de la línea de comunicación tiene continuidad y está aterrizado en la unidad exterior',
          'La unidad cuenta con terminales eléctricas en la línea de comunicación',
          'La canalización del cable de fuerza va separada de la de control en condensador y evaporadores',
          'La línea de comunicación es independiente para cada sistema',
        ]
      },
      {
        'titulo': 'CARGA DE REFRIGERANTE',
        'preguntas': [
          'Prueba de hermeticidad 24 hs a 500 psig',
          'Carga de refrigerante por peso',
          'Carga de refrigerante en fase líquida',
        ]
      },
      {
        'titulo': 'CICLO REFRIGERANTE',
        'preguntas': [
          'Operan todas las unidades exteriores en modo de prueba de enfriamiento y calefacción',
          'Operan todas las unidades interiores en velocidad alta',
          'Verificación de los datos de funcionamiento después de 20 minutos de operación',
          'Verifique la presión de descarga (Pd) y la temperatura de descarga (Td). ¿La temperatura del sobrecalentamiento en la descarga (TdSH) es de 15 a 45 °C?',
          '¿La presión de succión Ps está entre 0.15 a 1.3 Mpa (21.76 a 188.55 psi)?',
        ]
      },
    ];

    List<pw.Widget> widgets = [];

    for (int sectionIndex = 0; sectionIndex < secciones.length; sectionIndex++) {
      final seccion = secciones[sectionIndex];

      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              seccion['titulo'] as String,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#E11931'),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: _tableBorder,
              columnWidths: {
                0: const pw.FlexColumnWidth(5),
                1: const pw.FixedColumnWidth(45),
                2: const pw.FixedColumnWidth(45),
                3: const pw.FixedColumnWidth(45),
              },
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Pregunta', style: _tableHeaderStyle),
                    ),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('SI', style: _tableHeaderStyle),
                    ),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('NO', style: _tableHeaderStyle),
                    ),
                    pw.Container(
                      alignment: pw.Alignment.center,
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('N/C', style: _tableHeaderStyle),
                    ),
                  ],
                ),
                ...List.generate((seccion['preguntas'] as List).length, (questionIndex) {
                  final respuesta = _respuestas[sectionIndex][questionIndex];

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.white),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '${questionIndex + 1}. ${(seccion['preguntas'] as List)[questionIndex]}',
                          style: _tableTextStyle,
                        ),
                      ),
                      pw.Center(
                        child: respuesta == 'SI'
                            ? pw.Text(
                          'X',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColor.fromHex('#4CAF50'),
                            fontWeight: pw.FontWeight.bold,
                          ),
                        )
                            : pw.Text(' '),
                      ),
                      pw.Center(
                        child: respuesta == 'NO'
                            ? pw.Text(
                          'X',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColor.fromHex('#F44336'),
                            fontWeight: pw.FontWeight.bold,
                          ),
                        )
                            : pw.Text(' '),
                      ),
                      pw.Center(
                        child: respuesta == 'N/C'
                            ? pw.Text(
                          'X',
                          style: pw.TextStyle(
                            fontSize: 10,
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
            if (seccion['campoNumerico'] != null)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: pw.Row(
                  children: [
                    pw.Text(
                      '${seccion['campoNumerico']} ',
                      style: _tableTextStyle,
                    ),
                    pw.Text(
                      sectionIndex == 0
                          ? _relacionCombinacionController.text.isNotEmpty
                          ? _relacionCombinacionController.text
                          : 'No especificado'
                          : _capacidadInterruptorController.text.isNotEmpty
                          ? _capacidadInterruptorController.text
                          : 'No especificado',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            pw.SizedBox(height: 20),
          ],
        ),
      );
    }

    return widgets;
  }

  pw.Widget _buildPDFMainEsclavaTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CONFIGURACIÓN',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#E11931'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: _tableBorder,
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FixedColumnWidth(50),
            2: const pw.FixedColumnWidth(60),
            3: const pw.FixedColumnWidth(60),
            4: const pw.FixedColumnWidth(60),
          },
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Pregunta', style: _tableHeaderStyle),
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('MAIN', style: _tableHeaderStyle),
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('SLAVE 1', style: _tableHeaderStyle),
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('SLAVE 2', style: _tableHeaderStyle),
                ),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('SLAVE 3', style: _tableHeaderStyle),
                ),
              ],
            ),
            ..._respuestasMainEsclavas.map((pregunta) {
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      '${_respuestasMainEsclavas.indexOf(pregunta) + 1}. ${pregunta['pregunta']}',
                      style: _tableTextStyle,
                    ),
                  ),
                  pw.Center(
                    child: pregunta['main'] == true
                        ? pw.Text('SI', style: pw.TextStyle(color: PdfColor.fromHex('#4CAF50'), fontWeight: pw.FontWeight.bold))
                        : pw.Text(''),
                  ),
                  pw.Center(
                    child: pregunta['slave1'] == true
                        ? pw.Text('SI', style: pw.TextStyle(color: PdfColor.fromHex('#4CAF50'), fontWeight: pw.FontWeight.bold))
                        : pw.Text(''),
                  ),
                  pw.Center(
                    child: pregunta['slave2'] == true
                        ? pw.Text('SI', style: pw.TextStyle(color: PdfColor.fromHex('#4CAF50'), fontWeight: pw.FontWeight.bold))
                        : pw.Text(''),
                  ),
                  pw.Center(
                    child: pregunta['slave3'] == true
                        ? pw.Text('SI', style: pw.TextStyle(color: PdfColor.fromHex('#4CAF50'), fontWeight: pw.FontWeight.bold))
                        : pw.Text(''),
                  ),
                ],
              );
            }),
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
            _observacionesController.text.isNotEmpty
                ? _observacionesController.text
                : 'No se registraron observaciones',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPDFImagenServiceChecker() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SERVICE CHECKER',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#E11931'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Tabla de datos indicada en el Service Checker:',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 8),
        _imagenes[1] != null || _imagenesBytes[1] != null
            ? pw.Image(
          pw.MemoryImage(
              kIsWeb
                  ? _imagenesBytes[1]!
                  : _imagenes[1]!.readAsBytesSync()
          ),
          width: 500,
          height: 300,
          fit: pw.BoxFit.contain,
        )
            : pw.Text(
          'No se adjuntó imagen del Service Checker',
          style: const pw.TextStyle(fontSize: 10),
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
          pw.Text(
            'Página ${pdfContext.pageNumber}',
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
      final path = '${directory.path}/InformeArranqueVRF_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(path);

      await file.writeAsBytes(bytes);
      await OpenFile.open(path);
    }
  }

  Future<void> _generarPDF() async {
    if (!_validarChecklistCompleto()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todas las preguntas del checklist y campos requeridos')),
      );
      return;
    }

    try {
      final pdf = pw.Document();

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
              _buildPDFImagenDiagrama(),
              pw.SizedBox(height: 20),
              ..._buildPDFChecklist(),
              pw.SizedBox(height: 20),
              _buildPDFMainEsclavaTable(),
              pw.SizedBox(height: 20),
              _buildPDFObservaciones(),
              pw.SizedBox(height: 20),
              _buildPDFImagenServiceChecker(),
              pw.SizedBox(height: 30),
            ];
          },
        ),
      );

      await _guardarYAbrirPDF(pdf);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e')),
      );
    }
  }

       

  // -------------------------------- Función para generar el Excel ------------------------------------------------


Future<void> _generarExcel() async {
  final workbook = xlsio.Workbook();
  final sheet = workbook.worksheets[0];
  sheet.name = 'Informe VRF';

  // Estilos
  final titleStyle = workbook.styles.add('TitleStyle')
    ..bold = true
    ..fontSize = 14
    ..fontColor = '#E11931';

  final headerStyle = workbook.styles.add('HeaderStyle')
    ..bold = true
    ..fontColor = '#000000';

  final greenStyle = workbook.styles.add('GreenStyle')
    ..bold = true
    ..fontColor = '#4CAF50';

  final redStyle = workbook.styles.add('RedStyle')
    ..bold = true
    ..fontColor = '#F44336';

  final yellowStyle = workbook.styles.add('YellowStyle')
    ..bold = true
    ..fontColor = '#FF9800';

  int row = 1;

  // Título
  sheet.getRangeByIndex(row, 1).setText('INFORME DE ARRANQUE PARA EQUIPOS DE VRF');
  sheet.getRangeByIndex(row, 1).cellStyle = titleStyle;
  sheet.getRangeByIndex(row, 1, row, 4).merge();
  row += 2;

  // Información general
  final info = {
    'Fecha': _fechaController.text,
    'Nombre de la obra': _nombreObraController.text,
    'Dirección': _direccionController.text,
    'Empresa instaladora': _empresaInstaladoraController.text,
    'Contacto en obra': _contactoObraController.text,
    'Responsable de la puesta en marcha': _responsableController.text,
    'Visita N°': _visitaNumeroController.text,
    'Modelo unidad exterior principal': _modeloPrincipalController.text,
    'Modelo unidad exterior esclava 1': _modeloEsclava1Controller.text,
    'Modelo unidad exterior esclava 2': _modeloEsclava2Controller.text,
    'Modelo unidad exterior esclava 3': _modeloEsclava3Controller.text,
    'Modelo unidad exterior esclava 4': _modeloEsclava4Controller.text,
  };

  info.forEach((label, value) {
    sheet.getRangeByIndex(row, 1).setText(label);
    sheet.getRangeByIndex(row, 1).cellStyle = headerStyle;
    sheet.getRangeByIndex(row, 2).setText(value.isNotEmpty ? value : 'No especificado');
    row++;
  });

  row += 2;
  sheet.getRangeByIndex(row, 1).setText('Checklist');
  sheet.getRangeByIndex(row, 1).cellStyle = headerStyle;
  row++;


  sheet.getRangeByIndex(row, 2).setText('SI');
  sheet.getRangeByIndex(row, 3).setText('NO');
  sheet.getRangeByIndex(row, 4).setText('N/C');
  for (int col = 1; col <= 4; col++) {
    sheet.getRangeByIndex(row, col).cellStyle = headerStyle;
  }
  row++;

  final secciones = [
    { 'titulo': 'INSTALADOR',
        'preguntas': [
          'Participó en el curso de entrenamiento de instalación y puesta en marcha',
          'Cuenta con la herramienta necesaria (Vacuómetro, báscula digital, manómetros para refrigerante R-410, herramienta de mano)',
          'El instalador cuenta con los planos o diagramas del proyecto y están corresponde a lo instalado en sitio',
        ],
        'campoNumerico': 'Relación de combinación del sistema (%):',
        'valorCampo': _relacionCombinacionController.text,
      },
      {
        'titulo': 'UNIDAD EXTERIOR',
        'preguntas': [
          'La unidad cuenta con los espacios requeridos para operación y servicio',
          'La unidad cuenta con la base de concreto y/o acero además del aislamiento de neopreno',
          'La unidad cuenta con tratamiento anticorrosivo y barrera contra brisa marina',
          'La unidad cuenta con dispositivo local de desconexión de energía eléctrica',
          'La unidad cuenta con los deflectores adecuados para su óptima operación',
        ]
      },
      {
        'titulo': 'SUMINISTRO ELECTRICO',
        'preguntas': [
          'La unidad cuenta con terminales eléctricas en el suministro de fuerza',
          'La unidad cuenta con tierra física',
          'El calibre del cable conductor de la línea de fuerza es el adecuado',
          'La canalización del cable de fuerza va separada de la de control en condensador y evaporadores',
        ],
        'campoNumerico': 'Capacidad del interruptor termomagnético (A):',
        'valorCampo': _capacidadInterruptorController.text,
      },
      {
        'titulo': 'COMUNICACIÓN',
        'preguntas': [
          'El calibre del cable conductor de la línea de señal es el adecuado',
          'La línea de comunicación unidad cuenta con blindaje',
          'El blindaje de la línea de comunicación tiene continuidad y está aterrizado en la unidad exterior',
          'La unidad cuenta con terminales eléctricas en la línea de comunicación',
          'La canalización del cable de fuerza va separada de la de control en condensador y evaporadores',
          'La línea de comunicación es independiente para cada sistema',
        ]
      },
      {
        'titulo': 'CARGA DE REFRIGERANTE',
        'preguntas': [
          'Prueba de hermeticidad 24 hs a 500 psig',
          'Carga de refrigerante por peso',
          'Carga de refrigerante en fase líquida',
        ]
      },
      {
        'titulo': 'CICLO REFRIGERANTE',
        'preguntas': [
          'Operan todas las unidades exteriores en modo de prueba de enfriamiento y calefacción',
          'Operan todas las unidades interiores en velocidad alta',
          'Verificación de los datos de funcionamiento después de 20 minutos de operación',
          'Verifique la presión de descarga (Pd) y la temperatura de descarga (Td). ¿La temperatura del sobrecalentamiento en la descarga (TdSH) es de 15 a 45 °C?',
          '¿La presión de succión Ps está entre 0.15 a 1.3 Mpa (21.76 a 188.55 psi)?',
        ]
      
    },
    // Agregá las demás secciones como en tu PDF...
  ];

  for (var seccion in secciones) {
    sheet.getRangeByIndex(row, 1).setText(seccion['titulo'] as String);
    sheet.getRangeByIndex(row, 1).cellStyle = headerStyle;
    row++;

    final preguntas = seccion['preguntas'] as List<String>;
    for (int i = 0; i < preguntas.length; i++) {
      final respuesta = _respuestas[secciones.indexOf(seccion)][i];
      sheet.getRangeByIndex(row, 1).setText('${i + 1}. ${preguntas[i]}');
      if (respuesta == 'SI') {
        sheet.getRangeByIndex(row, 2).setText('X');
        sheet.getRangeByIndex(row, 2).cellStyle = greenStyle;
      } else if (respuesta == 'NO') {
        sheet.getRangeByIndex(row, 3).setText('X');
        sheet.getRangeByIndex(row, 3).cellStyle = redStyle;
      } else if (respuesta == 'N/C') {
        sheet.getRangeByIndex(row, 4).setText('X');
        sheet.getRangeByIndex(row, 4).cellStyle = yellowStyle;
      }
      row++;
    }

    if (seccion['campoNumerico'] != null) {
      sheet.getRangeByIndex(row, 1).setText(seccion['campoNumerico']?.toString() ?? '');
      sheet.getRangeByIndex(row, 2).setText('${seccion['valorCampo'] ?? 'No especificado'}');
      row++;
    }

    row++;
  }

  // Observaciones
  sheet.getRangeByIndex(row, 1).setText('OBSERVACIONES');
  sheet.getRangeByIndex(row, 1).cellStyle = headerStyle;
  row++;
  sheet.getRangeByIndex(row, 1).setText(_observacionesController.text.isNotEmpty
      ? _observacionesController.text
      : 'No se registraron observaciones');
  row += 2;

  // Imágenes
  for (int i = 0; i < _imagenes.length; i++) {
    final image = _imagenes[i];
    final bytes = _imagenesBytes[i];
    if (image != null || bytes != null) {
      final imgBytes = bytes ?? await image!.readAsBytes();
      sheet.pictures.addStream(row, 1, imgBytes);
      row += 50;
    }
  }

  sheet.autoFitColumn(1);
  final bytes = workbook.saveAsStream();
  workbook.dispose();

  if (kIsWeb) {
    await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: 'InformeArranqueVRF.xlsx');
  } else {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/InformeArranqueVRF_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    await OpenFile.open(path);
  }
}


// ------------------------------------------ PRUEBA -------------------------------------

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
            _buildTextField(_responsableController, 'Responsable de la puesta en marcha', obligatorio: true),
            _buildTextField(_fechaController, 'Fecha (dd/mm/aaaa)'),
            _buildTextField(_visitaNumeroController, 'Visita N°'),
            _buildTextField(_modeloPrincipalController, 'Modelo de unidad exterior principal'),
            _buildTextField(_modeloEsclava1Controller, 'Modelo de unidad exterior esclava 1'),
            _buildTextField(_modeloEsclava2Controller, 'Modelo de unidad exterior esclava 2'),
            _buildTextField(_modeloEsclava3Controller, 'Modelo de unidad exterior esclava 3'),
            _buildTextField(_modeloEsclava4Controller, 'Modelo de unidad exterior esclava 4'),

            _buildImagePicker(0, 'INSERTE IMAGEN DEL DIAGRAMA DE TUBERÍAS'),

            const Padding(
              padding: EdgeInsets.only(top: 20, bottom: 10),
              child: Text(
                'Por favor complete cada una de las secciones con SI, NO o N/C (no corresponde)',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.red,
                ),
              ),
            ),

            // INSTALADOR
            _buildChecklistSection(0, 'INSTALADOR', [
              'Participó en el curso de entrenamiento de instalación y puesta en marcha',
              'Cuenta con la herramienta necesaria (Vacuómetro, báscula digital, manómetros para refrigerante R-410, herramienta de mano)',
              'El instalador cuenta con los planos o diagramas del proyecto y están corresponde a lo instalado en sitio',
            ]),
            _buildNumericalField(_relacionCombinacionController, 'Relación de combinación del sistema (%)'),

            // UNIDAD EXTERIOR
            _buildChecklistSection(1, 'UNIDAD EXTERIOR', [
              'La unidad cuenta con los espacios requeridos para operación y servicio',
              'La unidad cuenta con la base de concreto y/o acero además del aislamiento de neopreno',
              'La unidad cuenta con tratamiento anticorrosivo y barrera contra brisa marina',
              'La unidad cuenta con dispositivo local de desconexión de energía eléctrica',
              'La unidad cuenta con los deflectores adecuados para su óptima operación',
            ]),

            // SUMINISTRO ELECTRICO
            _buildChecklistSection(2, 'SUMINISTRO ELECTRICO', [
              'La unidad cuenta con terminales eléctricas en el suministro de fuerza',
              'La unidad cuenta con tierra física',
              'El calibre del cable conductor de la línea de fuerza es el adecuado',
              'La canalización del cable de fuerza va separada de la de control en condensador y evaporadores',
            ]),
            _buildNumericalField(_capacidadInterruptorController, 'Capacidad del interruptor termomagnético (A)'),

            // COMUNICACIÓN
            _buildChecklistSection(3, 'COMUNICACIÓN', [
              'El calibre del cable conductor de la línea de señal es el adecuado',
              'La línea de comunicación unidad cuenta con blindaje',
              'El blindaje de la línea de comunicación tiene continuidad y está aterrizado en la unidad exterior',
              'La unidad cuenta con terminales eléctricas en la línea de comunicación',
              'La canalización del cable de fuerza va separada de la de control en condensador y evaporadores',
              'La línea de comunicación es independiente para cada sistema',
            ]),

            // CARGA DE REFRIGERANTE
            _buildChecklistSection(4, 'CARGA DE REFRIGERANTE', [
              'Prueba de hermeticidad 24 hs a 500 psig',
              'Carga de refrigerante por peso',
              'Carga de refrigerante en fase líquida',
            ]),

            // CICLO REFRIGERANTE
            _buildChecklistSection(5, 'CICLO REFRIGERANTE', [
              'Operan todas las unidades exteriores en modo de prueba de enfriamiento y calefacción',
              'Operan todas las unidades interiores en velocidad alta',
              'Verificación de los datos de funcionamiento después de 20 minutos de operación',
              'Verifique la presión de descarga (Pd) y la temperatura de descarga (Td). ¿La temperatura del sobrecalentamiento en la descarga (TdSH) es de 15 a 45 °C?',
              '¿La presión de succión Ps está entre 0.15 a 1.3 Mpa (21.76 a 188.55 psi)?',
            ]),

            // CHECK LIST MAIN-ESCLAVAS (formato especial)
            _buildMainEsclavaSection(),

            _buildImagePicker(1, 'INSERTE IMAGEN DE LA TABLA DE DATOS INDICADA EN EL SERVICE CHECKER'),

            _buildSeccion('OBSERVACIONES'),
            TextFormField(
              controller: _observacionesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Escriba observaciones adicionales...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),

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
            // Agregar el botón debajo del de PDF
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generarExcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 4, 129, 6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'GENERAR EXCEL',
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
    _modeloPrincipalController.dispose();
    _modeloEsclava1Controller.dispose();
    _modeloEsclava2Controller.dispose();
    _modeloEsclava3Controller.dispose();
    _modeloEsclava4Controller.dispose();
    _relacionCombinacionController.dispose();
    _capacidadInterruptorController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }
}