import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlannerFitnessScreen extends StatefulWidget {
  const PlannerFitnessScreen({Key? key}) : super(key: key);

  @override
  _PlannerFitnessScreenState createState() => _PlannerFitnessScreenState();
}

class _PlannerFitnessScreenState extends State<PlannerFitnessScreen>
    with TickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final TextEditingController _tipoTreinoController = TextEditingController();
  final TextEditingController _detalhesTreinoController = TextEditingController();

  String? _userUid;
  String _userName = "usuário";

  late AnimationController _animController;
  late AnimationController _fabAnimController;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _offsetAnim;
  late Animation<double> _fabScaleAnim;

  @override
  void initState() {
    super.initState();

    _userUid = FirebaseAuth.instance.currentUser?.uid;

    if (_userUid != null) {
      FirebaseFirestore.instance
          .collection("users")
          .doc(_userUid)
          .get()
          .then((doc) {
        setState(() {
          _userName = doc.data()?["name"] ?? "usuário";
        });
      });
    }

    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    _opacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _offsetAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fabScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimController,
        curve: Curves.elasticOut,
      ),
    );

    _animController.forward();
    Future.delayed(const Duration(milliseconds: 800), () {
      _fabAnimController.forward();
    });
  }

  @override
  void dispose() {
    _tipoTreinoController.dispose();
    _detalhesTreinoController.dispose();
    _animController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  String nomeDiaSemana(int weekday) {
    const dias = [
      'domingo',
      'segunda',
      'terça',
      'quarta',
      'quinta',
      'sexta',
      'sábado'
    ];
    return dias[(weekday - 1) % 7];
  }

  String nomeTreinoPorDia(DateTime dia) {
    switch (dia.weekday) {
      case DateTime.monday:
        return 'Peito';
      case DateTime.tuesday:
        return 'Costas';
      case DateTime.wednesday:
        return 'Pernas';
      case DateTime.thursday:
        return 'Ombros/Braços';
      case DateTime.friday:
        return 'Treino Geral';
      case DateTime.saturday:
        return 'Cardio';
      case DateTime.sunday:
        return 'Descanso';
      default:
        return 'Treino';
    }
  }

  IconData iconePorTreino(String nomeTreino) {
    final nome = nomeTreino.toLowerCase();
    if (nome.contains('peito')) return Icons.self_improvement;
    if (nome.contains('costas')) return Icons.accessibility_new;
    if (nome.contains('perna')) return Icons.directions_run;
    if (nome.contains('ombro') || nome.contains('braço')) return Icons.fitness_center;
    if (nome.contains('cardio')) return Icons.favorite;
    if (nome.contains('descanso')) return Icons.bedtime;
    return Icons.sports_gymnastics;
  }

  void _mostrarDialogoAdicionarOuEditarTreino(
    BuildContext context,
    DateTime dia, [
    String? docId,
    Map<String, dynamic>? treinoData,
  ]) {
    if (_userUid == null) {
      _mostrarSnackBar('Faça login para gerenciar treinos', isError: true);
      return;
    }

    if (treinoData != null) {
      _tipoTreinoController.text = treinoData['nome'] ?? '';
      final exerc = treinoData['exercicios'];
      if (exerc is List) {
        _detalhesTreinoController.text = exerc.join(', ');
      } else {
        _detalhesTreinoController.text = treinoData['exercicios']?.toString() ?? '';
      }
    } else {
      _tipoTreinoController.clear();
      _detalhesTreinoController.clear();
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Container();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1A2634),
                      const Color(0xFF0F1723),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header com ícone
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C9A7), Color(0xFF92FE9D)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C9A7).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            docId == null ? Icons.add_circle_outline : Icons.edit_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          docId == null ? 'Novo Treino' : 'Editar Treino',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${dia.day}/${dia.month}/${dia.year}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 28),
                        
                        // Campo Tipo de Treino
                        _buildTextField(
                          controller: _tipoTreinoController,
                          label: 'Tipo de Treino',
                          hint: 'Ex: Musculação, Cardio, Yoga',
                          icon: Icons.fitness_center,
                        ),
                        const SizedBox(height: 16),
                        
                        // Campo Exercícios
                        _buildTextField(
                          controller: _detalhesTreinoController,
                          label: 'Exercícios',
                          hint: 'Ex: Supino 4x10, Crucifixo 3x12',
                          icon: Icons.format_list_bulleted,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 28),
                        
                        // Botões
                        Row(
                          children: [
                            Expanded(
                              child: _buildOutlineButton(
                                label: 'Cancelar',
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: _buildGradientButton(
                                label: 'Salvar',
                                onPressed: () => _salvarTreino(context, dia, docId),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF00C9A7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutlineButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C9A7), Color(0xFF92FE9D)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C9A7).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _salvarTreino(BuildContext context, DateTime dia, String? docId) async {
    final tipo = _tipoTreinoController.text.trim();
    final detalhes = _detalhesTreinoController.text.trim();

    if (tipo.isEmpty && detalhes.isEmpty) {
      _mostrarSnackBar('Preencha ao menos um campo', isError: true);
      return;
    }

    final treinoMap = {
      'nome': tipo.isNotEmpty ? tipo : nomeTreinoPorDia(dia),
      'exercicios': detalhes.isNotEmpty
          ? detalhes.split(',').map((e) => e.trim()).toList()
          : <String>[],
      'data': Timestamp.fromDate(dia),
      'diaSemana': nomeDiaSemana(dia.weekday),
    };

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(_userUid)
        .collection('workout_plans');

    try {
      if (docId == null) {
        await ref.add(treinoMap);
        _mostrarSnackBar('Treino adicionado com sucesso!');
      } else {
        await ref.doc(docId).update(treinoMap);
        _mostrarSnackBar('Treino atualizado com sucesso!');
      }
      Navigator.pop(context);
    } catch (e) {
      _mostrarSnackBar('Erro ao salvar: $e', isError: true);
    }
  }

  Future<void> _excluirTreino(String docId) async {
    if (_userUid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userUid)
          .collection('workout_plans')
          .doc(docId)
          .delete();
      _mostrarSnackBar('Treino excluído');
    } catch (e) {
      _mostrarSnackBar('Erro ao excluir: $e', isError: true);
    }
  }

  void _mostrarSnackBar(String mensagem, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError 
            ? Colors.red.shade700 
            : const Color(0xFF00C9A7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.03),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: FadeTransition(
              opacity: _opacityAnim,
              child: SlideTransition(
                position: _offsetAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C9A7), Color(0xFF92FE9D)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Olá, $_userName',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Seu Planner',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Organize seus treinos e alcance seus objetivos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person_outline, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }

  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.08),
          Colors.white.withOpacity(0.03),
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userUid == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F1723), Color(0xFF06202A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C9A7), Color(0xFF92FE9D)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_outline, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Faça login para acessar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Conecte-se para gerenciar seus treinos',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F1723), Color(0xFF06202A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),

              // Calendário
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: _glassDecoration(),
                  padding: const EdgeInsets.all(16),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 17,
                        letterSpacing: 0.3,
                      ),
                      leftChevronIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                      ),
                      rightChevronIcon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                      ),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      weekendStyle: TextStyle(
                        color: const Color(0xFFFF6B6B).withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    calendarStyle: CalendarStyle(
                      defaultTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      weekendTextStyle: TextStyle(
                        color: const Color(0xFFFF6B6B).withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                      outsideTextStyle: TextStyle(
                        color: Colors.white.withOpacity(0.25),
                      ),
                      todayDecoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      selectedDecoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C9A7), Color(0xFF92FE9D)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00C9A7).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() => _calendarFormat = format);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Header da lista de treinos
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF00C9A7).withOpacity(0.2),
                            const Color(0xFF92FE9D).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF00C9A7),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Treinos do Dia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            '${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Lista de treinos
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_userUid)
                        .collection('workout_plans')
                        .orderBy('data', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF00C9A7),
                            ),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 64, color: Colors.redAccent.withOpacity(0.7)),
                              const SizedBox(height: 16),
                              Text(
                                'Erro ao carregar treinos',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      final treinosDoDia = docs.where((d) {
                        final treino = d.data() as Map<String, dynamic>;
                        final data = (treino['data'] as Timestamp?)?.toDate();
                        final diaSemana = (treino['diaSemana'] as String?)?.toLowerCase();
                        return (data != null && isSameDay(data, _selectedDay)) ||
                            (diaSemana != null &&
                                diaSemana == nomeDiaSemana(_selectedDay.weekday).toLowerCase());
                      }).toList();

                      if (treinosDoDia.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.05),
                                      Colors.white.withOpacity(0.02),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.fitness_center_outlined,
                                  size: 48,
                                  color: Colors.white.withOpacity(0.4),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Nenhum treino agendado',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C9A7).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFF00C9A7).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      iconePorTreino(nomeTreinoPorDia(_selectedDay)),
                                      size: 16,
                                      color: const Color(0xFF00C9A7),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sugestão: ${nomeTreinoPorDia(_selectedDay)}',
                                      style: const TextStyle(
                                        color: Color(0xFF00C9A7),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Toque no + para adicionar um treino',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: treinosDoDia.length,
                        itemBuilder: (context, index) {
                          final doc = treinosDoDia[index];
                          final treino = doc.data() as Map<String, dynamic>;
                          final nome = treino['nome'] as String? ?? nomeTreinoPorDia(_selectedDay);
                          final exercicios = (treino['exercicios'] as List?)?.cast<String>() ?? <String>[];

                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 400 + (index * 100)),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.08),
                                      Colors.white.withOpacity(0.03),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _mostrarDialogoAdicionarOuEditarTreino(
                                      context,
                                      _selectedDay,
                                      doc.id,
                                      treino,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  gradient: const LinearGradient(
                                                    colors: [Color(0xFF00C9A7), Color(0xFF92FE9D)],
                                                  ),
                                                  borderRadius: BorderRadius.circular(14),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF00C9A7).withOpacity(0.3),
                                                      blurRadius: 10,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  iconePorTreino(nome),
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      nome,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                        fontSize: 17,
                                                        letterSpacing: -0.3,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      exercicios.isEmpty
                                                          ? 'Nenhum exercício adicionado'
                                                          : '${exercicios.length} exercício${exercicios.length > 1 ? 's' : ''}',
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.5),
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Icons.more_vert,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (exercicios.isNotEmpty) ...[
                                            const SizedBox(height: 16),
                                            Container(
                                              height: 1,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.white.withOpacity(0.0),
                                                    Colors.white.withOpacity(0.08),
                                                    Colors.white.withOpacity(0.0),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            ...exercicios.take(3).map((e) => Padding(
                                              padding: const EdgeInsets.only(bottom: 8),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [Color(0xFF00C9A7), Color(0xFF92FE9D)],
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      e,
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.8),
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )),
                                            if (exercicios.length > 3)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  '+${exercicios.length - 3} exercícios',
                                                  style: TextStyle(
                                                    color: const Color(0xFF00C9A7).withOpacity(0.8),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    height: 44,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.05),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: Colors.white.withOpacity(0.08),
                                                      ),
                                                    ),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: () => _mostrarDialogoAdicionarOuEditarTreino(
                                                          context,
                                                          _selectedDay,
                                                          doc.id,
                                                          treino,
                                                        ),
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.edit_outlined,
                                                              color: Colors.white.withOpacity(0.9),
                                                              size: 18,
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              'Editar',
                                                              style: TextStyle(
                                                                color: Colors.white.withOpacity(0.9),
                                                                fontSize: 14,
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Container(
                                                  height: 44,
                                                  width: 44,
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: Colors.red.withOpacity(0.2),
                                                    ),
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: () => _excluirTreino(doc.id),
                                                      borderRadius: BorderRadius.circular(12),
                                                      child: const Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.redAccent,
                                                        size: 20,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // FAB com animação
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C9A7), Color(0xFF92FE9D)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C9A7).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _mostrarDialogoAdicionarOuEditarTreino(context, _selectedDay),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}