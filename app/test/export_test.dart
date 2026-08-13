import 'package:calistenia/models/exercicio.dart';
import 'package:calistenia/models/treino.dart';
import 'package:calistenia/util/exportar_treino.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guarda o formato do texto de compartilhar treino (detalhes por exercício).
void main() {
  test('compartilhar: detalhes por exercício + duração + assinatura', () {
    final t = Treino(nome: 'Peitoral Foco', exercicios: [
      Exercicio(
          nome: 'Flexão arqueiro',
          preparacaoSeg: 10,
          execucaoSeg: 5,
          descansoSeg: 60,
          repeticoes: 6,
          series: 3),
      Exercicio(
          nome: 'Prancha',
          preparacaoSeg: 0,
          execucaoSeg: 40,
          descansoSeg: 0,
          repeticoes: 1,
          series: 1),
    ]);
    final txt = treinoParaTexto(t);
    expect(txt, contains('Peitoral Foco'));
    expect(txt, contains('1. Flexão arqueiro:'));
    expect(txt, contains('3×6 repetições · execução 5s/rep'));
    expect(txt, contains('descanso 1min/série'));
    expect(txt, contains('(preparação 10s)'));
    expect(txt, contains('2. Prancha:'));
    expect(txt, contains('(isométrico)')); // reps == 1
    expect(txt, contains('feito no Calis Timer'));
  });

  test('compartilhar: descanso variável por série vira faixa min–max', () {
    final t = Treino(nome: 'X', exercicios: [
      Exercicio(
          nome: 'A',
          preparacaoSeg: 5,
          execucaoSeg: 3,
          descansoSeg: 60,
          repeticoes: 8,
          series: 2,
          descansos: [60, 90]),
    ]);
    expect(treinoParaTexto(t), contains('descanso 1min–1min 30s/série'));
  });

  test('compartilhar semana: agrupa por dia (Seg→Dom), dias vazios = descanso',
      () {
    final t = Treino(nome: 'Peito', dias: [0, 3], exercicios: [
      Exercicio(
          nome: 'Flexão',
          preparacaoSeg: 10,
          execucaoSeg: 5,
          descansoSeg: 60,
          repeticoes: 6,
          series: 3),
    ]);
    final txt = semanaParaTexto([t]);
    expect(txt, contains('MINHA SEMANA'));
    expect(txt, contains('▶ SEGUNDA'));
    expect(txt, contains('▶ QUINTA'));
    expect(txt, contains('Peito')); // aparece nos dias agendados
    // Seg (0) e Qui (3) têm treino; os outros 5 dias = descanso.
    expect('(descanso)'.allMatches(txt).length, 5);
  });
}
