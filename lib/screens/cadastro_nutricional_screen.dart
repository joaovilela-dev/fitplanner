import 'dart:ui';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser; // 🔧 NOVO IMPORT
import 'main_menu_screen.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class CadastroNutricional extends StatefulWidget {
  const CadastroNutricional({super.key});

  @override
  _CadastroNutricionalState createState() => _CadastroNutricionalState();
}

class _CadastroNutricionalState extends State<CadastroNutricional>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _alturaController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  
  double _bfValue = 18;
  String _sexoSelecionado = 'Masculino';
  String _objetivoSelecionado = 'Ganhar massa muscular';
  String _atividadeSelecionado = 'Moderadamente ativo';
  
  bool _bfEstimadoPorIA = false;
  bool _isLoading = false;
  bool _hoveringButton = false;
  bool _pesoFocused = false;
  bool _alturaFocused = false;
  bool _idadeFocused = false;
  bool _dadosSalvos = false;
  
  File? _foto;
  Uint8List? _fotoBytes;
  bool _mostrarReferencias = false;

  late AnimationController _animationController;
  late Animation<double> _glowPulse;
  late Animation<double> _scalePulse;

  final List<_Particle> _particles = List.generate(60, (index) => _Particle());
  final List<_Particle> _clickParticles = [];
  Offset _pointer = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat(reverse: true);

    _glowPulse = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scalePulse = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    for (var p in _particles) p.randomize();
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _alturaController.dispose();
    _idadeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _spawnClickParticles(Offset position) {
    for (int i = 0; i < 8; i++) {
      _clickParticles.add(_Particle(
        position: position,
        dx: (Random().nextDouble() - 0.5) * 3,
        dy: (Random().nextDouble() - 0.5) * 3,
        radius: Random().nextDouble() * 2.5 + 1,
        color: Color.lerp(
          const Color(0xFF00F5C8),
          const Color(0xFF00E5FF),
          Random().nextDouble(),
        )!.withOpacity(0.6),
      ));
    }
  }

  void _removerFoto() {
    setState(() {
      _foto = null;
      _fotoBytes = null;
      _bfEstimadoPorIA = false;
      _dadosSalvos = false;
    });
  }

  Future<void> _selecionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _fotoBytes = bytes;
        _foto = null;
        _bfEstimadoPorIA = false;
        _dadosSalvos = false;
      });
    } else {
      setState(() {
        _foto = File(picked.path);
        _fotoBytes = null;
        _bfEstimadoPorIA = false;
        _dadosSalvos = false;
      });
    }
  }

  Future<Map<String, dynamic>?> enviarParaIA() async {
    if (_foto == null && _fotoBytes == null) return null;

    // Log dos dados que serão enviados
    debugPrint('=== ENVIANDO DADOS PARA API ===');
    debugPrint('Idade: ${_idadeController.text}');
    debugPrint('Peso: ${_pesoController.text}');
    debugPrint('Altura: ${_alturaController.text}');
    debugPrint('Sexo: ${_sexoSelecionado == 'Masculino' ? 'male' : 'female'}');

    final uri = Uri.parse('http://127.0.0.1:8000/estimate-body-composition');
    final request = http.MultipartRequest('POST', uri);

    try {
      // Adicionar a imagem com contentType explícito
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image', 
            _fotoBytes!, 
            filename: 'foto.jpg',
            contentType: http_parser.MediaType('image', 'jpeg'), // 🔧 CORREÇÃO
          ),
        );
        debugPrint('Imagem web adicionada: ${_fotoBytes!.length} bytes');
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image', 
            _foto!.path,
            contentType: http_parser.MediaType('image', 'jpeg'), // 🔧 CORREÇÃO
          ),
        );
        debugPrint('Imagem arquivo adicionada: ${_foto!.path}');
      }

      // Adicionar campos - VALIDAÇÃO IMPORTANTE
      if (_idadeController.text.isEmpty || 
          _pesoController.text.isEmpty || 
          _alturaController.text.isEmpty) {
        throw Exception('Preencha todos os campos antes de enviar a foto.');
      }

      request.fields['age'] = _idadeController.text;
      request.fields['weight_kg'] = _pesoController.text;
      request.fields['height_cm'] = _alturaController.text;
      request.fields['sex'] = _sexoSelecionado == 'Masculino' ? 'male' : 'female';

      debugPrint('Enviando requisição...');
      final response = await request.send();
      final body = await response.stream.bytesToString();

      debugPrint('=== RESPOSTA DA API ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: $body');

      if (response.statusCode == 200) {
        final result = json.decode(body) as Map<String, dynamic>;
        
        // Verificar se há erro na resposta
        if (result['error'] != null) {
          final reason = result['reason'] ?? '';
          final alerts = result['alerts'] as List<dynamic>?;
          
          String mensagemErro = 'Não foi possível analisar a imagem.';
          
          if (reason == 'NO_PERSON_DETECTED') {
            mensagemErro = 'Nenhuma pessoa detectada na imagem.\n\n'
                '📸 Dicas:\n'
                '• Tire uma foto de corpo inteiro\n'
                '• Fique de frente para a câmera\n'
                '• Use boa iluminação\n'
                '• Evite roupas muito largas';
          } else if (reason == 'POOR_IMAGE_QUALITY') {
            mensagemErro = 'Qualidade da imagem insuficiente.\n\n'
                '📸 Dicas:\n'
                '• Use uma câmera melhor\n'
                '• Melhore a iluminação\n'
                '• Evite fotos muito escuras ou tremidas';
          } else if (alerts != null && alerts.isNotEmpty) {
            mensagemErro = 'Problemas detectados:\n\n';
            for (var alert in alerts) {
              mensagemErro += '• ${alert.toString()}\n';
            }
          } else if (result['error'] != null) {
            mensagemErro = result['error'].toString();
          }
          
          throw Exception(mensagemErro);
        }
        
        // Validar se o body_fat_percentage existe e não é nulo
        if (result['body_fat_percentage'] == null) {
          throw Exception('A IA não conseguiu estimar o BF.\n\n'
              'Possíveis causas:\n'
              '• Pose inadequada na foto\n'
              '• Pessoa não visível por completo\n'
              '• Iluminação insuficiente\n\n'
              'Tente outra foto ou use o valor manual.');
        }
        
        // Validar tipo do valor
        final bfValue = result['body_fat_percentage'];
        if (bfValue is! num) {
          throw Exception('Valor de BF retornado em formato inválido.');
        }
        
        final bfDouble = bfValue.toDouble();
        
        // Validar range
        if (bfDouble < 0 || bfDouble > 100) {
          throw Exception('Valor de BF fora do esperado: ${bfDouble.toStringAsFixed(1)}%\n\n'
              'Por favor, tente outra foto ou use o valor manual.');
        }
        
        debugPrint('BF estimado com sucesso: $bfDouble%');
        return result;
        
      } else if (response.statusCode == 400) {
        // Tentar extrair mensagem de erro do body
        try {
          final errorData = json.decode(body);
          final detail = errorData['detail'] ?? errorData['error'] ?? 'Erro desconhecido';
          throw Exception('Erro na requisição:\n$detail');
        } catch (e) {
          throw Exception('Erro ao processar a imagem (código 400).\n\n'
              'Verifique se:\n'
              '• Todos os campos estão preenchidos\n'
              '• A foto é válida (JPG ou PNG)\n'
              '• O servidor está funcionando corretamente\n\n'
              'Detalhes: $body');
        }
      } else if (response.statusCode == 500) {
        throw Exception('Erro interno do servidor.\n\n'
            'A API encontrou um problema ao processar sua requisição.\n'
            'Tente novamente ou use o valor manual.');
      } else {
        throw Exception('Erro ao conectar com o servidor (código ${response.statusCode}).');
      }
      
    } on http.ClientException catch (e) {
      debugPrint('Erro de conexão: $e');
      throw Exception('Erro de conexão com o servidor.\n\n'
          'Verifique se:\n'
          '• O servidor está rodando (start_api.bat)\n'
          '• A porta 8000 está livre\n'
          '• Não há firewall bloqueando');
    } catch (e) {
      debugPrint('Erro geral: $e');
      rethrow;
    }
  }

  Future<void> _salvarDados() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Preencha todos os campos obrigatórios',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final userId = user.uid;
      double bfFinal;
      Map<String, dynamic>? iaResult;
      bool usouFoto = _foto != null || _fotoBytes != null;

      if (usouFoto) {
        debugPrint('Iniciando análise de imagem...');
        
        try {
          iaResult = await enviarParaIA();
          
          if (iaResult == null) {
            throw Exception('Erro ao processar a foto. Nenhum resultado retornado.');
          }
          
          // Converter com segurança o valor do BF
          final bfValue = iaResult['body_fat_percentage'];
          if (bfValue == null) {
            throw Exception('A IA não retornou um percentual de gordura válido.');
          }
          
          bfFinal = (bfValue as num).toDouble();
          
          // Validar se o valor está em um range razoável
          if (bfFinal < 0 || bfFinal > 100) {
            throw Exception('Valor de BF fora do esperado: ${bfFinal.toStringAsFixed(1)}%');
          }
          
          debugPrint('✅ BF estimado pela IA: ${bfFinal.toStringAsFixed(1)}%');
          
          setState(() {
            _bfValue = bfFinal;
            _bfEstimadoPorIA = true;
          });
          
          // Mostrar sucesso da análise
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Análise concluída!',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'BF estimado: ${bfFinal.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Você pode ajustar o valor no slider acima se necessário.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF00E5FF),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 5),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          
        } catch (e) {
          debugPrint('❌ Erro na análise da imagem: $e');
          
          if (mounted) {
            // Extrair mensagem de erro limpa
            String mensagemErro = e.toString().replaceAll('Exception: ', '');
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Erro na análise da imagem',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        mensagemErro,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '💡 Soluções:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• Envie outra foto seguindo as dicas\n'
                      '• Remova a imagem e use o valor manual\n'
                      '• Verifique se o servidor está rodando',
                      style: TextStyle(fontSize: 11, height: 1.5),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFFF6B6B),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 8),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          
          // NÃO salvar e NÃO permitir continuar
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      } else {
        bfFinal = _bfValue;
        debugPrint('Usando BF manual: ${bfFinal.toStringAsFixed(1)}%');
      }

      // Salvar no Firestore
      debugPrint('Salvando dados no Firestore...');
      
      final dadosNutricionais = {
        'peso': double.parse(_pesoController.text),
        'altura': int.parse(_alturaController.text),
        'idade': int.parse(_idadeController.text),
        'sexo': _sexoSelecionado,
        'objetivo': _objetivoSelecionado,
        'atividade': _atividadeSelecionado,
        'dataCadastro': Timestamp.now(),
        'dadosCorporais': {
          'bf': bfFinal,
          'origem': usouFoto ? 'ia' : 'manual',
        },
        if (iaResult != null) 'ia_result': iaResult,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('nutritional_data')
          .doc('user_info')
          .set(dadosNutricionais, SetOptions(merge: true));

      debugPrint('✅ Dados salvos com sucesso!');

      if (mounted) {
        setState(() {
          _dadosSalvos = true;
          _isLoading = false;
        });

        // Mostra mensagem de sucesso apenas se não tiver usado foto
        if (!usouFoto) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Dados salvos com sucesso!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF00F5C8),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
      
    } catch (e) {
      debugPrint('❌ Erro ao salvar: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Erro ao salvar os dados',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  e.toString().replaceAll('Exception: ', ''),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _continuarParaMenu() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  Color _getSliderColor(double bf, String sexo) {
    if ((sexo == 'Masculino' && bf < 5) ||
        (sexo == 'Feminino' && bf < 10) ||
        bf > 50) {
      return Colors.redAccent.shade200;
    } else if ((sexo == 'Masculino' && bf < 10) ||
               (sexo == 'Feminino' && bf < 15) ||
               bf > 25) {
      return Colors.amberAccent.shade200;
    } else {
      return Colors.greenAccent.shade400;
    }
  }

  bool _isBfAtypical(double bf, String sexo) {
    return (sexo == 'Masculino' && bf < 5) ||
           (sexo == 'Feminino' && bf < 10) ||
           bf > 50;
  }

  String _getBfCategory(double bf, String sexo) {
    if (sexo == 'Masculino') {
      if (bf < 6) return 'Essencial';
      if (bf < 14) return 'Atleta';
      if (bf < 18) return 'Fitness';
      if (bf < 25) return 'Normal';
      return 'Alto';
    } else {
      if (bf < 14) return 'Essencial';
      if (bf < 21) return 'Atleta';
      if (bf < 25) return 'Fitness';
      if (bf < 32) return 'Normal';
      return 'Alto';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: MouseRegion(
        onHover: (event) => setState(() => _pointer = event.localPosition),
        child: GestureDetector(
          onTapDown: (details) => _spawnClickParticles(details.localPosition),
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(const Color(0xFF0A0E27), const Color(0xFF16213E),
                              _animationController.value)!,
                          const Color(0xFF0F1624),
                          Color.lerp(const Color(0xFF16213E), const Color(0xFF0A0E27),
                              _animationController.value)!,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: -100,
                right: -100,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFF00F5C8).withOpacity(0.12 * _glowPulse.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: -150,
                left: -100,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Color(0xFF00E5FF).withOpacity(0.1 * _glowPulse.value),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              CustomPaint(
                painter: _ParticlePainter(_particles, _pointer, size),
                size: Size.infinite,
              ),
              CustomPaint(
                painter: _ParticlePainter(_clickParticles, _pointer, size),
                size: Size.infinite,
              ),
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.05,
                    vertical: size.height * 0.04,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              padding: const EdgeInsets.all(36),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.08),
                                    Colors.white.withOpacity(0.04),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  width: 1.5,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                  BoxShadow(
                                    color: Color(0xFF00F5C8).withOpacity(0.08 * _glowPulse.value),
                                    blurRadius: 60,
                                    spreadRadius: -10,
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    ScaleTransition(
                                      scale: _scalePulse,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF00F5C8).withOpacity(0.2),
                                              Color(0xFF00E5FF).withOpacity(0.1),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF00F5C8)
                                                  .withOpacity(0.3 * _glowPulse.value),
                                              blurRadius: 25,
                                              spreadRadius: 3,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.restaurant_menu_rounded,
                                          size: 48,
                                          color: Color(0xFF00F5C8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ShaderMask(
                                      shaderCallback: (bounds) => LinearGradient(
                                        colors: [
                                          const Color(0xFF00F5C8),
                                          const Color(0xFF00E5FF),
                                        ],
                                      ).createShader(bounds),
                                      child: const Text(
                                        "Perfil Nutricional",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontWeight: FontWeight.w800,
                                          fontSize: 30,
                                          color: Colors.white,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Complete seu perfil para resultados personalizados",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 14,
                                        fontFamily: 'Inter',
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        bool isCompact = constraints.maxWidth < 500;
                                        if (isCompact) {
                                          return Column(
                                            children: [
                                              Focus(
                                                onFocusChange: (f) =>
                                                    setState(() => _pesoFocused = f),
                                                child: _buildField(
                                                  "Peso (kg)",
                                                  _pesoController,
                                                  Icons.monitor_weight_rounded,
                                                  _pesoFocused,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Focus(
                                                onFocusChange: (f) =>
                                                    setState(() => _alturaFocused = f),
                                                child: _buildField(
                                                  "Altura (cm)",
                                                  _alturaController,
                                                  Icons.height_rounded,
                                                  _alturaFocused,
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                              Focus(
                                                onFocusChange: (f) =>
                                                    setState(() => _idadeFocused = f),
                                                child: _buildField(
                                                  "Idade",
                                                  _idadeController,
                                                  Icons.cake_rounded,
                                                  _idadeFocused,
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: Focus(
                                                onFocusChange: (f) =>
                                                    setState(() => _pesoFocused = f),
                                                child: _buildField(
                                                  "Peso (kg)",
                                                  _pesoController,
                                                  Icons.monitor_weight_rounded,
                                                  _pesoFocused,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Focus(
                                                onFocusChange: (f) =>
                                                    setState(() => _alturaFocused = f),
                                                child: _buildField(
                                                  "Altura (cm)",
                                                  _alturaController,
                                                  Icons.height_rounded,
                                                  _alturaFocused,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Focus(
                                                onFocusChange: (f) =>
                                                    setState(() => _idadeFocused = f),
                                                child: _buildField(
                                                  "Idade",
                                                  _idadeController,
                                                  Icons.cake_rounded,
                                                  _idadeFocused,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 28),
                                    _buildSection("Sexo"),
                                    const SizedBox(height: 12),
                                    RadioGroup(
                                      options: ['Masculino', 'Feminino'],
                                      selected: _sexoSelecionado,
                                      onChanged: (v) => setState(() => _sexoSelecionado = v),
                                      icons: [Icons.male_rounded, Icons.female_rounded],
                                    ),
                                    const SizedBox(height: 24),
                                    _buildSection("Objetivo"),
                                    const SizedBox(height: 12),
                                    RadioGroup(
                                      options: [
                                        'Perder peso',
                                        'Manter peso',
                                        'Ganhar massa muscular',
                                        'Recomposição muscular'
                                      ],
                                      selected: _objetivoSelecionado,
                                      onChanged: (v) => setState(() => _objetivoSelecionado = v),
                                      icons: [
                                        Icons.trending_down_rounded,
                                        Icons.balance_rounded,
                                        Icons.fitness_center_rounded,
                                        Icons.transform_rounded,
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    _buildSection("Nível de Atividade"),
                                    const SizedBox(height: 12),
                                    RadioGroup(
                                      options: [
                                        'Sedentário',
                                        'Levemente ativo',
                                        'Moderadamente ativo',
                                        'Muito ativo'
                                      ],
                                      selected: _atividadeSelecionado,
                                      onChanged: (v) => setState(() => _atividadeSelecionado = v),
                                      icons: [
                                        Icons.weekend_rounded,
                                        Icons.directions_walk_rounded,
                                        Icons.directions_run_rounded,
                                        Icons.sports_gymnastics_rounded,
                                      ],
                                    ),
                                    const SizedBox(height: 32),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildSection("Percentual de Gordura (BF)"),
                                        TextButton.icon(
                                          onPressed: () {
                                            setState(() => _mostrarReferencias = !_mostrarReferencias);
                                          },
                                          icon: Icon(
                                            _mostrarReferencias 
                                              ? Icons.visibility_off_rounded 
                                              : Icons.info_outline_rounded,
                                            size: 16,
                                            color: const Color(0xFF00E5FF),
                                          ),
                                          label: Text(
                                            _mostrarReferencias ? 'Ocultar' : 'Referências',
                                            style: const TextStyle(
                                              color: Color(0xFF00E5FF),
                                              fontSize: 12,
                                              fontFamily: 'Inter',
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      ],
                                    ),

                                    AnimatedCrossFade(
                                      duration: const Duration(milliseconds: 300),
                                      crossFadeState: _mostrarReferencias 
                                        ? CrossFadeState.showSecond 
                                        : CrossFadeState.showFirst,
                                      firstChild: const SizedBox.shrink(),
                                      secondChild: Container(
                                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF00E5FF).withOpacity(0.1),
                                              Colors.white.withOpacity(0.05),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF00E5FF).withOpacity(0.3),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Faixas de BF por categoria:',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            _buildReferenceRow('Essencial', 
                                              _sexoSelecionado == 'Masculino' ? '2-5%' : '10-13%',
                                              Colors.redAccent.shade200),
                                            _buildReferenceRow('Atleta', 
                                              _sexoSelecionado == 'Masculino' ? '6-13%' : '14-20%',
                                              Colors.greenAccent.shade400),
                                            _buildReferenceRow('Fitness', 
                                              _sexoSelecionado == 'Masculino' ? '14-17%' : '21-24%',
                                              Colors.greenAccent.shade400),
                                            _buildReferenceRow('Normal', 
                                              _sexoSelecionado == 'Masculino' ? '18-24%' : '25-31%',
                                              Colors.amberAccent.shade200),
                                            _buildReferenceRow('Alto', 
                                              _sexoSelecionado == 'Masculino' ? '25%+' : '32%+',
                                              Colors.amberAccent.shade200),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          colors: [
                                            (_foto == null && _fotoBytes == null)
                                                ? const Color(0xFF00F5C8).withOpacity(0.15)
                                                : Colors.white.withOpacity(0.05),
                                            Colors.white.withOpacity(0.02),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: (_foto == null && _fotoBytes == null)
                                              ? const Color(0xFF00F5C8)
                                              : Colors.white.withOpacity(0.12),
                                          width: (_foto == null && _fotoBytes == null) ? 2 : 1.2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.tune_rounded,
                                                color: (_foto == null && _fotoBytes == null)
                                                    ? const Color(0xFF00F5C8)
                                                    : Colors.white.withOpacity(0.6),
                                                size: 22,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  "Informar manualmente",
                                                  style: TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: (_foto == null && _fotoBytes == null)
                                                        ? Colors.white
                                                        : Colors.white.withOpacity(0.6),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          Slider(
                                            value: _bfValue,
                                            min: 5,
                                            max: 60,
                                            divisions: 55,
                                            label: "${_bfValue.toStringAsFixed(0)}%",
                                            activeColor: _getSliderColor(_bfValue, _sexoSelecionado),
                                            inactiveColor: Colors.white.withOpacity(0.1),
                                            onChanged: (_foto == null && _fotoBytes == null)
                                                ? (v) => setState(() {
                                                    _bfValue = v;
                                                    _bfEstimadoPorIA = false;
                                                  })
                                                : null,
                                          ),
                                          
                                          Center(
                                            child: Column(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: _getSliderColor(_bfValue, _sexoSelecionado).withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                      color: _getSliderColor(_bfValue, _sexoSelecionado),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      if (_bfEstimadoPorIA) ...[
                                                        Icon(
                                                          Icons.auto_awesome_rounded,
                                                          size: 16,
                                                          color: _getSliderColor(_bfValue, _sexoSelecionado),
                                                        ),
                                                        const SizedBox(width: 6),
                                                      ],
                                                      Text(
                                                        "${_bfValue.toStringAsFixed(1)}%",
                                                        style: TextStyle(
                                                          color: _getSliderColor(_bfValue, _sexoSelecionado),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 18,
                                                          fontFamily: 'Montserrat',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    _getBfCategory(_bfValue, _sexoSelecionado),
                                                    style: TextStyle(
                                                      color: Colors.white.withOpacity(0.7),
                                                      fontSize: 11,
                                                      fontFamily: 'Inter',
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          if (_bfEstimadoPorIA)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 12),
                                              child: Center(
                                                child: Text(
                                                  "✨ Estimado pela IA • Ajuste se necessário",
                                                  style: TextStyle(
                                                    color: const Color(0xFF00E5FF).withOpacity(0.8),
                                                    fontSize: 12,
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          
                                          if (_isBfAtypical(_bfValue, _sexoSelecionado))
                                            Padding(
                                              padding: const EdgeInsets.only(top: 12),
                                              child: Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        "Valor fora do padrão populacional. Verifique se está correto.",
                                                        style: TextStyle(
                                                          color: Colors.amber.shade200,
                                                          fontSize: 11,
                                                          fontFamily: 'Inter',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    Row(
                                      children: [
                                        Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            "OU",
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.5),
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Montserrat',
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: LinearGradient(
                                          colors: [
                                            (_foto != null || _fotoBytes != null)
                                                ? const Color(0xFF00E5FF).withOpacity(0.15)
                                                : Colors.white.withOpacity(0.05),
                                            Colors.white.withOpacity(0.02),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: (_foto != null || _fotoBytes != null)
                                              ? const Color(0xFF00E5FF)
                                              : Colors.white.withOpacity(0.12),
                                          width: (_foto != null || _fotoBytes != null) ? 2 : 1.2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.photo_camera_rounded,
                                                color: (_foto != null || _fotoBytes != null)
                                                    ? const Color(0xFF00E5FF)
                                                    : Colors.white.withOpacity(0.6),
                                                size: 22,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  "Estimar por foto (IA)",
                                                  style: TextStyle(
                                                    fontFamily: 'Montserrat',
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: (_foto != null || _fotoBytes != null)
                                                        ? Colors.white
                                                        : Colors.white.withOpacity(0.6),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          
                                          if (_foto != null || _fotoBytes != null)
                                            Container(
                                              margin: const EdgeInsets.only(bottom: 12),
                                              height: 200,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(0xFF00E5FF).withOpacity(0.3),
                                                ),
                                              ),
                                              child: Stack(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Center(
                                                      child: kIsWeb
                                                          ? Image.memory(
                                                              _fotoBytes!,
                                                              fit: BoxFit.contain,
                                                            )
                                                          : Image.file(
                                                              _foto!,
                                                              fit: BoxFit.contain,
                                                            ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 8,
                                                    right: 8,
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: _removerFoto,
                                                        borderRadius: BorderRadius.circular(20),
                                                        child: Container(
                                                          padding: const EdgeInsets.all(6),
                                                          decoration: BoxDecoration(
                                                            color: Colors.black.withOpacity(0.6),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(
                                                            Icons.close_rounded,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: _selecionarFoto,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: (_foto != null || _fotoBytes != null)
                                                    ? const Color(0xFF00E5FF).withOpacity(0.2)
                                                    : const Color(0xFF00E5FF).withOpacity(0.1),
                                                foregroundColor: const Color(0xFF00E5FF),
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                elevation: 0,
                                              ),
                                              icon: Icon(
                                                (_foto != null || _fotoBytes != null)
                                                    ? Icons.change_circle_rounded
                                                    : Icons.add_photo_alternate_rounded,
                                                size: 20,
                                              ),
                                              label: Text(
                                                (_foto != null || _fotoBytes != null)
                                                    ? 'Trocar foto'
                                                    : 'Enviar foto',
                                                style: const TextStyle(
                                                  fontFamily: 'Montserrat',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ),
                                          
                                          if (_foto != null || _fotoBytes != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 12),
                                              child: Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF00E5FF).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.info_outline_rounded, color: Color(0xFF00E5FF), size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        "A IA estimará seu BF quando você salvar. O valor aparecerá no slider acima para ajuste.",
                                                        style: TextStyle(
                                                          color: const Color(0xFF00E5FF).withOpacity(0.9),
                                                          fontSize: 11,
                                                          fontFamily: 'Inter',
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          
                                          if (_foto == null && _fotoBytes == null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 12),
                                              child: Text(
                                                "💡 Tire uma foto de corpo inteiro, bem iluminada, de frente ou de lado.",
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.5),
                                                  fontSize: 11,
                                                  fontFamily: 'Inter',
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    MouseRegion(
                                      onEnter: (_) => setState(() => _hoveringButton = true),
                                      onExit: (_) => setState(() => _hoveringButton = false),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        height: 56,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: _hoveringButton
                                                ? [
                                                    const Color(0xFF00F5C8),
                                                    const Color(0xFF00E5FF),
                                                  ]
                                                : [
                                                    const Color(0xFF00E5D1),
                                                    const Color(0xFF00CDB8),
                                                  ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0xFF00F5C8)
                                                  .withOpacity(_hoveringButton ? 0.5 : 0.3),
                                              blurRadius: _hoveringButton ? 25 : 15,
                                              offset: Offset(0, _hoveringButton ? 8 : 4),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _isLoading 
                                                ? null 
                                                : (_dadosSalvos ? _continuarParaMenu : _salvarDados),
                                            borderRadius: BorderRadius.circular(16),
                                            child: Center(
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child: CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5,
                                                      ),
                                                    )
                                                  : Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          _dadosSalvos 
                                                              ? Icons.arrow_forward_rounded
                                                              : Icons.save_rounded,
                                                          color: Colors.white,
                                                          size: 22,
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Text(
                                                          _dadosSalvos 
                                                              ? "Continuar"
                                                              : "Salvar Informações",
                                                          style: const TextStyle(
                                                            fontSize: 17,
                                                            fontFamily: 'Montserrat',
                                                            fontWeight: FontWeight.w700,
                                                            color: Colors.white,
                                                            letterSpacing: 0.5,
                                                          ),
                                                        ),
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
                            ),
                          ),
                        );
                      },
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

  Widget _buildReferenceRow(String category, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              border: Border.all(color: color, width: 1.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              category,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            range,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF00F5C8), Color(0xFF00E5FF)]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.9),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, bool focused) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: const Color(0xFF00F5C8).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        validator: (v) {
          if (v == null || v.isEmpty) return 'Obrigatório';
          final n = double.tryParse(v);
          if (n == null || n <= 0) return 'Inválido';
          return null;
        },
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: focused ? const Color(0xFF00F5C8) : Colors.white.withOpacity(0.5),
            size: 22,
          ),
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: focused ? const Color(0xFF00F5C8) : Colors.white.withOpacity(0.5),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(focused ? 0.08 : 0.04),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF00F5C8), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: const Color(0xFFFF6B6B).withOpacity(0.5), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
          ),
          errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11, fontFamily: 'Inter'),
        ),
      ),
    );
  }
}

class RadioGroup extends StatefulWidget {
  final List<String> options;
  final String selected;
  final Function(String) onChanged;
  final List<IconData>? icons;

  const RadioGroup({
    Key? key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.icons,
  }) : super(key: key);

  @override
  _RadioGroupState createState() => _RadioGroupState();
}

class _RadioGroupState extends State<RadioGroup> {
  String? hovered;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.options.asMap().entries.map((e) {
        final idx = e.key;
        final opt = e.value;
        final sel = widget.selected == opt;
        final hov = hovered == opt;
        final icon = widget.icons != null && idx < widget.icons!.length ? widget.icons![idx] : null;

        return MouseRegion(
          onEnter: (_) => setState(() => hovered = opt),
          onExit: (_) => setState(() => hovered = null),
          child: GestureDetector(
            onTap: () => widget.onChanged(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: sel
                      ? [
                          const Color(0xFF00F5C8).withOpacity(0.15),
                          const Color(0xFF00E5FF).withOpacity(0.08),
                        ]
                      : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
                ),
                border: Border.all(
                  color: sel ? const Color(0xFF00F5C8) : Colors.white.withOpacity(0.12),
                  width: sel ? 2 : 1.2,
                ),
                boxShadow: hov || sel
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00F5C8).withOpacity(0.2),
                          blurRadius: hov ? 15 : 10,
                          offset: Offset(0, hov ? 4 : 2),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: sel ? const Color(0xFF00F5C8) : Colors.white.withOpacity(0.6),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        color: sel ? Colors.white : Colors.white.withOpacity(0.7),
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (sel)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00F5C8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Particle {
  Offset position = Offset.zero;
  double radius = 1;
  double dx = 0;
  double dy = 0;
  Color color = Colors.white54;
  double life = 1.0;

  _Particle({Offset? position, double? radius, double? dx, double? dy, Color? color}) {
    this.position = position ?? Offset.zero;
    this.radius = radius ?? 1;
    this.dx = dx ?? 0;
    this.dy = dy ?? 0;
    this.color = color ?? Colors.white54;
  }

  void randomize([Size? size]) {
    final r = Random();
    position = Offset(
      r.nextDouble() * (size?.width ?? 800),
      r.nextDouble() * (size?.height ?? 1200),
    );
    radius = r.nextDouble() * 2.5 + 0.8;
    dx = (r.nextDouble() - 0.5) * 0.4;
    dy = (r.nextDouble() - 0.4) * 0.4;
    color = Colors.white.withOpacity(r.nextDouble() * 0.35 + 0.1);
    life = 1.0;
  }

  void move() {
    position = position.translate(dx, dy);
    life -= 0.005;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Offset pointer;
  final Size screenSize;

  _ParticlePainter(this.particles, this.pointer, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    particles.removeWhere((p) => p.life <= 0);
    for (var p in particles) {
      paint.color = p.color.withOpacity(p.color.opacity * p.life);
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(p.position, p.radius, paint);
      final d = (p.position - pointer).distance;
      if (d < 100 && d > 0) {
        final dir = (p.position - pointer) / d;
        p.position += dir * 0.3;
      }
      p.move();
      if (p.position.dx > size.width ||
          p.position.dx < 0 ||
          p.position.dy > size.height ||
          p.position.dy < 0 ||
          p.life <= 0) {
        p.randomize(size);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}