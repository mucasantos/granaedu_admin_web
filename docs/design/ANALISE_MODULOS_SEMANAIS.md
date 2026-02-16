# DOCUMENTO NORTEADOR TÉCNICO — v2
*Estruturado para execução por etapas*

## Visão Geral

**Objetivo:** Evoluir os 4 pilares do aprendizado:
*   **Reading:** Input (Leitura Guiada)
*   **Listening:** Input Auditivo (Compreensão Real)
*   **Speaking:** Output (Feedback de Pronúncia e Fluência)
*   **Grammar:** Estrutura (Contextual e Prática)

**Base Pedagógica:** Learning Graph + Adaptive Engine + AI Content.
**Estratégia:** Execução em **ETAPAS INCREMENTAIS** para não quebrar o sistema atual.

---

## FASE 1 — READING ENGINE (GUTENBERG)

### Objetivo
Criar motor de conteúdo infinito usando material público de alta qualidade (Project Gutenberg).

### Arquitetura
`Gutenberg Source` → `Downloader` → `Cleaner` → `Chunk Engine` → `AI Generator` → `App UI`

### Backend — Componentes
1.  **Gutenberg Downloader:** Job para baixar livros (Crawler/Script).
2.  **Text Processor:** Limpeza, Chunking (divisão por parágrafos), Classificação de Nível (CEFR).
3.  **Lesson Generator (AI):** Gera explicações, vocabulário e exercícios a partir do chunk.

### Mobile — Implementação
*   **Tela Reading:** Texto com scroll, highlight de vocabulário, perguntas.
*   **Highlight Tappable:** Ao tocar na palavra, ver definição contextual (não apenas dicionário).

### Etapas de Execução
1.  **ETAPA 1:** Script de Ingestão (Download + Clean + Chunk + Vector DB).
2.  **ETAPA 2:** AI Generator (Edge Function) + Reading UI (Flutter).

---

## FASE 2 — SPEAKING ENGINE

### Objetivo
Avaliar fala real e gerar feedback pedagógico automático.

### Arquitetura
`Record` → `Upload` → `STT (Whisper)` → `AI Analysis` → `Feedback JSON` → `App UI`

### Backend — Pipeline
1.  **Speech-to-Text:** Whisper Large v3 (via API) para transcrição fiel.
2.  **Speaking Analyzer:** LLM recebe transcrição + métricas e gera JSON com scores (Fluência, Gramática, Pronúncia) e dicas.

### Mobile — Implementação
*   **Tela Speaking:** Gravador (10s/30s), Loading State, Resultado Visual (Radar Chart, Texto Corrigido).

### Etapas de Execução
1.  **ETAPA 1:** Gravação e Upload (Flutter) + Whisper (Backend).
2.  **ETAPA 2:** Análise IA + Feedback Textual.
3.  **ETAPA 3:** Score Visual + Tracking no Learning Graph.

---

## FASE 3 — LISTENING ENGINE

### Objetivo
Treinar compreensão auditiva com conteúdo gerado e adaptativo.

### Arquitetura
`Text Source` → `TTS Neural` → `Audio File` → `App Player` → `Questions`

### Backend
1.  **Generator:** Cria roteiros baseados no nível/interesse.
2.  **TTS Engine:** Gera áudio de alta fidelidade (OpenAI TTS / Azure).

### Mobile — Implementação
*   **Tela Listening:** Player com controle de velocidade, exercícios de preenchimento/múltipla escolha.

### Etapas de Execução
1.  **ETAPA 1:** TTS básico + Player + Perguntas simples.
2.  **ETAPA 2:** Velocidade variável + Conteúdo adaptativo.

---

## FASE 4 — GRAMMAR ENGINE (CONTEXTUAL)

### Objetivo
Transformar gramática de "regras abstratas" em "ferramentas contextuais", usando os textos lidos como base.

### Arquitetura
`Text Chunk` → `NLP Tagger` → `Pattern Matcher` → `Contextual Drill` → `App UI`

### Backend — Componentes
1.  **Grammar Tagger:** Identifica estruturas (Present Perfect, Conditionals) dentro dos chunks do Reading.
2.  **Explanation Generator:** Gera explicações curtas ("Por que foi usado 'had been' aqui?") linkadas à frase exata do texto.
3.  **Drill Generator:** Cria exercícios de "Reescrita" ou "Preenchimento" usando as frases reais do texto.

### Mobile — Implementação
*   **Contextual Tooltips:** Ao clicar numa frase sublinhada no Reading, ver a análise gramatical (Overlay).
*   **Tela Grammar Drill:** Exercícios rápidos focados em *pattern recognition* (não apenas regras).
    *   *Ex:* "Transforme esta frase do texto para o Futuro."

### Etapas de Execução
1.  **ETAPA 1:** Tagging Automático dos Chunks (durante a Ingestão no Python).
2.  **ETAPA 2:** UI de Tooltips/Bottom Sheet no Reading (Flutter).
3.  **ETAPA 3:** Gerador de Drills Dinâmicos (Edge Function).

---

# ANÁLISE DO ESTADO ATUAL (AS-IS)
*Levantamento realizado na base de código atual (`learn_english_app` e `learn_english_admin`)*

## 1. Módulo Speaking
*   **Status Atual:** **Básico / Incipiente**
*   **O que existe:** `ChatScreen` com `speech_to_text` (local).
*   **Gap:** Falta upload de áudio, análise de pronúncia real e feedback visual estruturado.

## 2. Módulo Listening
*   **Status Atual:** **Básico**
*   **O que existe:** `flutter_tts` (robótico).
*   **Gap:** Falta áudio neural e player dedicado a exercícios de compreensão.

## 3. Módulo Reading (Conteúdo Infinito)
*   **Status Atual:** **Inexistente**
*   **Gap Total:** Necessário pipeline Gutenberg e banco vetorial.

## 4. Módulo Grammar
*   **Status Atual:** **Inexistente**
*   **Gap Total:** Não há sistema de tag de gramática em textos, nem exercícios contextuais. Hoje o app foca em tarefas genéricas geradas por IA.

---

# REFINAMENTO TÉCNICO & PLANO DE AÇÃO

## A. Estrutura de Dados (Supabase)
Necessário criar via Migration ou Dashboard:

```sql
-- READING & GRAMMAR ENGINE
create table books (
  id uuid primary key default gen_random_uuid(),
  gutenberg_id int unique,
  title text,
  author text,
  metadata jsonb
);

create table book_chunks (
  id uuid primary key default gen_random_uuid(),
  book_id uuid references books(id),
  chunk_index int,
  content text,
  cefr_level text, -- 'A1', 'B2', etc.
  grammar_tags jsonb, -- ['present_perfect', 'conditionals']
  embedding vector(1536) -- Para busca semântica
);

create table grammar_drills (
  id uuid primary key default gen_random_uuid(),
  chunk_id uuid references book_chunks(id),
  sentence text,
  grammar_point text,
  drill_type text, -- 'rewrite', 'fill_gap'
  correct_answer text,
  explanation text
);

-- SPEAKING ENGINE
create table speaking_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id),
  transcript text,
  audio_url text, -- Storage Path
  scores jsonb, -- { fluency: 80, grammar: 70 ... }
  feedback jsonb,
  created_at timestamp default now()
);
```

## B. Pipeline de Ingestão (Python Script)
**Local ou Worker Separado** (Não rodar na Edge Function):
1.  Download do .txt do Gutenberg.
2.  Clean e Chunking.
3.  **Grammar Tagging (Novo):** Usar Spacy ou OpenAI para identificar estruturas gramaticais no texto.
4.  Inserir no Supabase com tags.

## C. Flutter Implementation (Ordem de Prioridade)

### Prioridade 1: Speaking Module
*   **Feature:** `features/speaking`
*   **State:** `SpeakingCubit`.

### Prioridade 2: Reading & Grammar Module
*   **Feature:** `features/reading`
*   **Sub-feature:** `features/grammar` (Tooltip, Drills).
*   **State:** `ReadingCubit`.

### Prioridade 3: Listening Module
*   **Feature:** `features/listening`.
