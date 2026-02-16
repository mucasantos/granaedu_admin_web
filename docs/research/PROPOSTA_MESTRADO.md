# Proposta de Pesquisa - Mestrado em Sistemas Inteligentes (LP2)

**Título Provisório:** Sistema de Tutoria Inteligente com Reading Engine Adaptativo baseado em IA Generativa e na Hipótese do Input de Stephen Krashen para Otimização da Aquisição de Vocabulário em Leitura

**Linha de Pesquisa:** LP2 – Sistemas Inteligentes
**Eixo:** Educação / Tecnologia Educacional

---

## 1. Resumo da Proposta

Este projeto propõe o desenvolvimento e validação de um **Sistema de Tutoria Inteligente (ITS)** focado na competência de leitura (*Reading*) em língua inglesa. O sistema utiliza **Large Language Models (LLMs)** para gerar e adaptar textos em tempo real, ajustando a complexidade lexical ao nível de proficiência do aluno conforme a **Hipótese do Input (i+1)** de Stephen Krashen.

O objetivo é otimizar a aquisição de vocabulário em escolas públicas, onde a heterogeneidade das turmas torna impossível para o professor fornecer textos individualizados manualmente. O sistema atua como um "Tutor Assistente", garantindo que cada aluno receba um texto desafiador, porém compreensível.

---

## 2. Aderência à Linha de Pesquisa (LP2)

O projeto se enquadra nos seguintes tópicos da descrição da LP2:

| Tópico da Linha | Aplicação no Projeto |
| :--- | :--- |
| **Inteligência Artificial** | Utilização de IA Generativa (Gemini/OpenAI) para **Reescrita Textual Adaptativa** e geração de definições contextuais (Glossário Dinâmico). |
| **Aprendizagem de Máquina** | Implementação de algoritmos de **Recomendação** que analisam o histórico de SRS (Spaced Repetition System) do aluno para calcular seu "nível i" atual. |
| **Ciência de Dados / Big Data** | Mineração de dados de interação com o texto (tempo de leitura, cliques em palavras) para inferir o nível de compreensão real versus o estimado. |
| **Educação** | Aplicação direta da teoria de Krashen (Input Compreensível) em um ambiente digital escalável. |

---

## 3. Problema e Hipótese de Pesquisa

*   **Problema:** Em turmas numerosas de escolas públicas, o material didático é estático ("one size fits all"). Alunos avançados ficam entediados e alunos iniciantes frustrados, violando o princípio do *Input Compreensível* necessário para a aquisição de linguagem.
*   **Hipótese:** Um *Reading Engine* capaz de adaptar dinamicamente o mesmo texto base para diferentes níveis de complexidade (L1, L2, L3), mantendo a narrativa original, aumentará significativamente a taxa de retenção de novo vocabulário comparado ao método tradicional.

### Metodologia Proposta (Estudo de Caso)
1.  **Grupo Controle:** Lê o texto original do livro didático.
2.  **Grupo Experimental:** Lê o texto adaptado pelo ITS para seu nível (i+1), com suporte de glossário gerado por IA.
3.  **Métrica:** Teste de vocabulário passivo e ativo pré e pós-intervenção.

---

## 4. Fundamentação Teórica (Breve)

A pesquisa se ancora na **Hipótese do Input** (*The Input Hypothesis*) de Stephen Krashen (1985), que postula que a aquisição de uma segunda língua ocorre apenas quando o aprendiz é exposto a um input que está ligeiramente além do seu nível atual de competência (denotado como *i + 1*).

A IA Generativa atua aqui como o motor que viabiliza a criação desse material *i + 1* em escala, algo humanamente inviável para um único professor com 40 alunos.

---

### Tema C: Mineração de Dados Educacionais (EDM) para Apoio à Decisão
*   **Problema:** O professor só descobre que a turma não entendeu um tópico na hora da prova.
*   **Hipótese:** A análise de micro-dados de exercícios diários (App) pode prever lacunas de aprendizado coletivo a tempo de intervenção.
*   **Metodologia:** Correlacionar métricas de engajamento no app (tempo de uso, taxa de erro em tópicos específicos) com o desempenho em avaliações formais (ETEC/Vestibulinho).

---

## 4. Contribuições Esperadas

1.  **Técnica:** Uma arquitetura de referência para integração de LLMs em sistemas de gestão escolar (LMS) de baixo custo.
2.  **Social:** Uma ferramenta validada para aumentar a eficiência do professor de escola pública, permitindo que ele foque em mentorias humanas em vez de correção mecânica.
3.  **Científica:** Dados empíricos sobre a eficácia de feedback generativo no contexto de falantes brasileiros de inglês.

---

## 5. Próximos Passos (Para o Mestrado)

1.  **Definir o Recorte:** Escolher UM dos temas acima (não tente fazer tudo). O Tema A (Avaliação) ou B (Adaptação) são os mais fortes para "Sistemas Inteligentes".
2.  **Implementar o "Módulo de Pesquisa":** O software precisa salvar os logs detalhados (input do aluno, output da IA, interação do usuário) para análise posterior.
3.  **Validação de Campo:** Firmar parceria com uma escola (ETEC?) para rodar o piloto.
