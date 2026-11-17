import 'package:calistenia/models/checkin.dart';
import 'package:calistenia/models/conclusao.dart';
import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/medida.dart';
import 'package:calistenia/models/nota.dart';
import 'package:calistenia/models/registro_progressao.dart';
import 'package:calistenia/models/treino.dart';
import 'package:calistenia/services/resumo_claude_service.dart';
import 'package:flutter_test/flutter_test.dart';

final _hoje = DateTime(2026, 11, 16);

CheckIn _ci(int diaOffset, String ex) => CheckIn(
      data: _hoje.subtract(Duration(days: diaOffset)),
      exercicio: ex,
      corIndex: 0,
    );

Conclusao _cc(int diaOffset, String treino, {bool completo = true}) =>
    Conclusao(
      data: _hoje.subtract(Duration(days: diaOffset)),
      treinoId: 't1',
      treino: treino,
      completo: completo,
    );

void main() {
  group('fraseStreak', () {
    test('treino completo hoje conta hoje na sequência', () {
      final s = ResumoClaude.fraseStreak(
        _hoje,
        [_ci(0, 'Flexão'), _ci(1, 'Flexão'), _ci(2, 'Flexão')],
        [_cc(0, 'Peito')],
      );
      expect(
        s,
        'Completei o treino hoje, agora são 3 dias seguidos.',
      );
    });

    test('1 dia seguido no singular', () {
      final s = ResumoClaude.fraseStreak(_hoje, [], [_cc(0, 'Peito')]);
      expect(s, 'Completei o treino hoje, agora é 1 dia seguido.');
    });

    test('sem treino hoje mostra sequência e gap do último completo', () {
      final s = ResumoClaude.fraseStreak(
        _hoje,
        [_ci(1, 'Flexão'), _ci(2, 'Flexão')],
        [_cc(3, 'Peito')],
      );
      expect(s, contains('Ainda não treinei hoje.'));
      expect(s, contains('Sequência atual: 3 dias seguidos.'));
      expect(s, contains('há 3 dias'));
    });

    test('treinou mas não completou hoje', () {
      final s = ResumoClaude.fraseStreak(
        _hoje,
        [_ci(0, 'Flexão')],
        [_cc(0, 'Peito', completo: false), _cc(1, 'Peito')],
      );
      expect(s, contains('Treinei hoje mas não completei o treino.'));
    });

    test('vazio não quebra', () {
      final s = ResumoClaude.fraseStreak(_hoje, [], []);
      expect(s, contains('Ainda não treinei hoje.'));
      expect(s, contains('Sequência atual: 0 dias.'));
    });
  });

  group('textoHoje', () {
    test('traz plano, feito, números e rating', () {
      final t = Treino(id: 't1', nome: 'Peito', dias: const [0], exercicios: [
        Exercicio(nome: 'Flexão', series: 3, repeticoes: 10),
      ]);
      final txt = ResumoClaude.textoHoje(
        hoje: _hoje,
        checkins: [_ci(0, 'Flexão')],
        conclusoes: [_cc(0, 'Peito')],
        progressoes: [
          RegistroProgressao(
              exercicio: 'Flexão', valor: 12, data: _hoje),
        ],
        treinos: [t],
      );
      expect(txt, contains('Completei o treino hoje'));
      expect(txt, contains('Treino: Peito (completo).'));
      expect(txt, contains('Flexão 3×10'));
      expect(txt, contains('Números de hoje: Flexão 12 reps.'));
      expect(txt, contains(RegExp(r'Rating: \d+/1000 \([+-]?\d+ hoje\)\.')));
    });
  });

  group('blocoPlanoSemanal', () {
    Treino mkTreino(String nome, List<int> dias, [String ex = 'Flexão']) =>
        Treino(id: nome, nome: nome, dias: dias, exercicios: [
          Exercicio(nome: ex, series: 3, repeticoes: 10),
        ]);

    test('dias variados, dois treinos no mesmo dia, descanso e sem dia', () {
      final txt = ResumoClaude.blocoPlanoSemanal(
        [
          mkTreino('Peito', [0]),
          mkTreino('Costas', [1]),
          mkTreino('Ombro', [1]),
          mkTreino('Avulso', []),
        ],
        '16/11',
      );
      expect(txt, contains('## Plano semanal (atualizado em 16/11)'));
      expect(txt, contains('- Segunda: Peito (Flexão 3×10 · 3s/rep · desc 1min)'));
      expect(txt, contains('Costas (Flexão 3×10 · 3s/rep · desc 1min) ;; Ombro (Flexão 3×10 · 3s/rep · desc 1min)'));
      expect(txt, contains('- Quarta: — descanso —'));
      expect(txt, contains('- Sem dia definido: Avulso (Flexão 3×10 · 3s/rep · desc 1min)'));
      for (final proibido in ['uid', 'viniciostristao', 'peso:', 'cintura', 'token', 'nota']) {
        expect(txt.contains(proibido), isFalse, reason: proibido);
      }
    });

    test('sem treinos omite a seção', () {
      expect(ResumoClaude.blocoPlanoSemanal(const [], '16/11'), isEmpty);
    });
  });

  group('arquivoQuinzena', () {
    test('15 linhas de dia + totais + progressão 3 meses', () {
      final txt = ResumoClaude.arquivoQuinzena(
        hoje: _hoje,
        checkins: [_ci(0, 'Flexão'), _ci(1, 'Flexão'), _ci(20, 'Barra')],
        conclusoes: [_cc(0, 'Peito'), _cc(5, 'Costas')],
        progressoes: [
          RegistroProgressao(
              exercicio: 'Flexão',
              valor: 10,
              data: _hoje.subtract(const Duration(days: 80))),
          RegistroProgressao(
              exercicio: 'Flexão', valor: 12, data: _hoje),
          RegistroProgressao(
              exercicio: 'Barra',
              valor: 5,
              data: _hoje.subtract(const Duration(days: 100))),
        ],
        treinos: const [],
        conquistas: const [],
        insignias: const [],
        escudos: const [],
      );
      expect(txt, contains('# Treino — resumo para a Muse (16/11)'));
      expect(txt, contains('Completei o treino hoje'));
      // 15 linhas de dia
      expect('## Últimos 15 dias'.allMatches(txt).length, 1);
      expect(txt, contains('- 16/11 (seg):'));
      expect(txt, contains('sem treino.'));
      // progressão 3 meses: Barra (100 dias) fica fora, Flexão entra
      expect(txt, contains('Flexão [fora dos treinos]: 10 reps → 12 reps'));
      expect(txt.contains('Barra'), isFalse);
      // totais: 15 dias = 3 treinados (0,1,5... 20 fica fora) × 12 sem
      expect(txt, contains('15 dias: 3 treinados × 12 sem treino.'));
      expect(txt, contains('Check-ins: 3; conclusões: 2 (2 completas).'));
      expect(txt, contains('## Rating'));
      expect(txt, contains(RegExp(r'Rating: \d+/1000')));
    });

    test('plano semanal entra após a frase e antes dos 15 dias', () {
      final t = Treino(id: 't1', nome: 'Peito', dias: const [1], exercicios: [
        Exercicio(nome: 'Flexão', series: 3, repeticoes: 10),
      ]);
      final txt = ResumoClaude.arquivoQuinzena(
        hoje: _hoje,
        checkins: const [],
        conclusoes: const [],
        progressoes: const [],
        treinos: [t],
        conquistas: const [],
        insignias: const [],
        escudos: const [],
      );
      expect(txt, contains('- Terça: Peito (Flexão 3×10 · 3s/rep · desc 1min)'));
      expect(
        txt.indexOf('## Plano semanal'),
        lessThan(txt.indexOf('## Últimos 15 dias')),
      );
    });

    test('medidas: últimas 5 + evolução primeira→última', () {
      final txt = ResumoClaude.arquivoQuinzena(
        hoje: _hoje,
        checkins: const [],
        conclusoes: const [],
        progressoes: const [],
        treinos: const [],
        conquistas: const [],
        insignias: const [],
        escudos: const [],
        medidas: [
          Medida(data: _hoje.subtract(const Duration(days: 30)), peso: 70, cintura: 80),
          Medida(data: _hoje.subtract(const Duration(days: 1)), peso: 71.5, cintura: 79, braco: 32),
        ],
      );
      expect(txt, contains('## Medidas corporais (peso em kg, resto em cm)'));
      expect(txt, contains('peso 70kg'));
      expect(txt, contains('peso 71,5kg'));
      expect(txt, contains('cintura 80.'));
      expect(txt, contains('braço 32.'));
      expect(txt, contains('Evolução ('));
      expect(txt, contains('peso 70kg → 71,5kg'));
      expect(txt, contains('cintura 80 → 79'));
      expect(txt.contains('## Notas'), isFalse);
    });

    test('notas entram em seção própria; vazias somem', () {
      final comNotas = ResumoClaude.arquivoQuinzena(
        hoje: _hoje,
        checkins: const [],
        conclusoes: const [],
        progressoes: const [],
        treinos: const [],
        conquistas: const [],
        insignias: const [],
        escudos: const [],
        notas: [Nota(texto: 'joelho direito reclamou na bike')],
      );
      expect(comNotas, contains('## Notas'));
      expect(comNotas, contains('joelho direito reclamou na bike'));

      final semNada = ResumoClaude.arquivoQuinzena(
        hoje: _hoje,
        checkins: const [],
        conclusoes: const [],
        progressoes: const [],
        treinos: const [],
        conquistas: const [],
        insignias: const [],
        escudos: const [],
        notas: [Nota()],
      );
      expect(semNada.contains('## Notas'), isFalse);
      expect(semNada.contains('## Medidas'), isFalse);
    });
  });
}
