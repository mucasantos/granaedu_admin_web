# 🏗️ Arquitetura: Adaptive Weekly Plan System

## 📊 Visão Geral do Sistema

```
┌─────────────────────────────────────────────────────────────────────┐
│                    ADAPTIVE WEEKLY PLAN SYSTEM                       │
│                  (Regeneração Condicional - Modelo 2)                │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐
│   STUDENT    │
│  (Mobile)    │
└──────┬───────┘
       │
       │ 1. Completes Speaking Task
       ↓
┌──────────────────────────────────────────────────────────────────────┐
│                        SPEAKING SUBMISSION                            │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ speaking_submissions table                                      │  │
│  │ - audio_url, transcript, analysis_json, score                  │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────┬───────────────────────────────────────────┘
                           │
                           │ 2. Trigger: update_skill_profile_from_speaking()
                           ↓
┌──────────────────────────────────────────────────────────────────────┐
│                      USER SKILL PROFILE                               │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ user_skill_profile table                                        │  │
│  │ - speaking_score, grammar_score, vocabulary_score               │  │
│  │ - fluency_score, listening_score                                │  │
│  │ - fluency_index (calculated)                                    │  │
│  │ - primary_skill, secondary_skill (weakest areas)                │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────┬───────────────────────────────────────────┘
                           │
                           │ 3. Monday 00:00 - Cron Job
                           ↓
┌──────────────────────────────────────────────────────────────────────┐
│              WEEKLY REGENERATION CHECK (Edge Function)                │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ check-weekly-regeneration                                       │  │
│  │                                                                  │  │
│  │ FOR EACH STUDENT:                                               │  │
│  │   1. Create weekly_skill_snapshot                               │  │
│  │   2. Compare with last snapshot                                 │  │
│  │   3. Check regeneration rules:                                  │  │
│  │      - FI delta >= ±3?                                          │  │
│  │      - Primary skill changed?                                   │  │
│  │      - Teacher forced?                                          │  │
│  │   4. IF YES → Generate new plan                                 │  │
│  │      IF NO  → Keep current plan                                 │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────┬───────────────────────────────────────────────────────┘
               │
               │ 4a. Regenerate (if needed)
               ↓
┌──────────────────────────────────────────────────────────────────────┐
│                  ADAPTIVE PLAN GENERATION (AI)                        │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ ai-orchestrator: generate_adaptive_weekly_plan                  │  │
│  │                                                                  │  │
│  │ INPUT:                                                           │  │
│  │ - User skill profile (FI, primary/secondary skills)             │  │
│  │ - User level, goal, interests                                   │  │
│  │ - Regeneration reason                                           │  │
│  │                                                                  │  │
│  │ GEMINI AI GENERATES:                                            │  │
│  │ - 7-day adaptive plan                                           │  │
│  │ - Focus on primary weakness                                     │  │
│  │ - Balanced skill mix                                            │  │
│  │ - Appropriate difficulty                                        │  │
│  │                                                                  │  │
│  │ OUTPUT:                                                          │  │
│  │ - Weekly plan with primary/secondary focus                      │  │
│  │ - 7 daily tasks (speaking, grammar, vocab, listening, review)   │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────┬───────────────────────────────────────────────────────┘
               │
               │ 5. Save to database
               ↓
┌──────────────────────────────────────────────────────────────────────┐
│                        WEEKLY PLAN STORAGE                            │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ weekly_plans table                                              │  │
│  │ - primary_focus, secondary_focus                                │  │
│  │ - generated_from_snapshot (link to snapshot)                    │  │
│  │ - status (active / archived)                                    │  │
│  │ - teacher_adjusted (boolean)                                    │  │
│  │ - regeneration_reason                                           │  │
│  └────────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ daily_tasks table                                               │  │
│  │ - task_type, skill, title                                       │  │
│  │ - difficulty, estimated_minutes                                 │  │
│  │ - generated_by (ai / teacher)                                   │  │
│  │ - completed, score                                              │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────┬───────────────────────────────────────────────────────┘
               │
               │ 6. Display to student
               ↓
┌──────────────────────────────────────────────────────────────────────┐
│                      MOBILE APP HOME (Flutter)                        │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ BLOCO 1: Fluency Index Card                                     │  │
│  │ - Current FI score                                              │  │
│  │ - Radar chart (5 skills)                                        │  │
│  │ - Trend indicator                                               │  │
│  └────────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ BLOCO 2: This Week Focus                                        │  │
│  │ - Primary focus (orange badge)                                  │  │
│  │ - Secondary focus (blue badge)                                  │  │
│  └────────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ BLOCO 3: Today's Task                                           │  │
│  │ - Task title, type, difficulty                                  │  │
│  │ - Estimated time                                                │  │
│  │ - "Start Task" button                                           │  │
│  └────────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ BLOCO 4: Upcoming Tasks                                         │  │
│  │ - List of remaining tasks for the week                          │  │
│  └────────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ BLOCO 5: Tools (secondary)                                      │  │
│  │ - Flashcards, History, Recovery, Insights                       │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────┬───────────────────────────────────────────────────────┘
               │
               │ 7. Execute tasks during week
               ↓
┌──────────────────────────────────────────────────────────────────────┐
│                         TASK EXECUTION                                │
│  - Student completes tasks                                            │
│  - Scores recorded                                                    │
│  - Speaking tasks update skill profile                                │
│  - Cycle repeats                                                      │
└───────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│                    TEACHER MODE (Engage & Assess)                     │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │ Teacher Dashboard                                               │  │
│  │ - View student skill profiles                                   │  │
│  │ - View current weekly plans                                     │  │
│  │ - Edit tasks manually                                           │  │
│  │ - Force plan regeneration                                       │  │
│  │ - View regeneration history                                     │  │
│  └────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Fluxo de Dados Detalhado

### 1. Speaking Task Completion → Skill Profile Update

```
Student completes speaking task
         ↓
Audio sent to speaking-analyzer edge function
         ↓
Analysis returns: {
  scores: { grammar, fluency, vocabulary, pronunciation, clarity },
  transcript,
  feedback
}
         ↓
Insert into speaking_submissions table
         ↓
TRIGGER: update_skill_profile_from_speaking()
         ↓
Calculate Fluency Index:
  FI = (grammar * 0.25) + (fluency * 0.30) + (vocabulary * 0.25) 
       + (pronunciation * 0.10) + (clarity * 0.10)
         ↓
Identify primary_skill (lowest score)
Identify secondary_skill (second lowest)
         ↓
UPSERT into user_skill_profile
```

### 2. Weekly Regeneration Check (Monday 00:00)

```
Cron job triggers check-weekly-regeneration edge function
         ↓
FOR EACH active student:
         ↓
  1. Fetch last snapshot from weekly_skill_snapshot
         ↓
  2. Fetch current profile from user_skill_profile
         ↓
  3. Create new snapshot for current week
         ↓
  4. Calculate FI delta = current_FI - last_snapshot_FI
         ↓
  5. Check primary skill change
         ↓
  6. Apply regeneration rules:
     
     IF (FI_delta >= +3 OR FI_delta <= -3) THEN
       regenerate = TRUE
       reason = 'fi_improvement' OR 'fi_decline'
     
     ELSE IF (primary_skill changed) THEN
       regenerate = TRUE
       reason = 'primary_skill_changed'
     
     ELSE IF (teacher forced) THEN
       regenerate = TRUE
       reason = 'teacher_forced'
     
     ELSE
       regenerate = FALSE
       reason = 'stable'
         ↓
  7. IF regenerate = TRUE:
       - Archive current active plan (status = 'archived')
       - Call ai-orchestrator to generate new plan
       - Create new weekly_plan with status = 'active'
       - Create 7 daily_tasks
     
     ELSE:
       - Keep current plan active
```

### 3. Adaptive Plan Generation (AI)

```
ai-orchestrator receives generate_adaptive_weekly_plan action
         ↓
INPUT:
  - user_id
  - week_start (Monday date)
  - snapshot_id (link to snapshot)
  - profile (FI, primary_skill, secondary_skill, all scores)
  - user_level (A1-C2)
  - user_goal (e.g., "Business English")
  - user_interests (array)
  - regeneration_reason
         ↓
Build prompt for Gemini AI:
  "Generate 7-day adaptive plan focusing on {primary_skill}
   Current FI: {fluency_index}/100
   Weaknesses: {primary_skill}, {secondary_skill}
   Level: {user_level}
   Interests: {user_interests}"
         ↓
Gemini AI generates:
  {
    "primary_focus": "grammar",
    "secondary_focus": "vocabulary",
    "tasks": [
      { day: 1, task_type: "speaking", title: "...", difficulty: "medium" },
      { day: 2, task_type: "grammar", title: "...", difficulty: "medium" },
      ...
    ]
  }
         ↓
Save to database:
  1. INSERT into weekly_plans
  2. INSERT 7 rows into daily_tasks
         ↓
Return success response
```

---

## 🗄️ Estrutura de Banco de Dados

### Tabelas Principais

```sql
-- 1. User Skill Profile (atualizado após cada speaking)
user_skill_profile
├── id (UUID)
├── user_id (UUID) → auth.users
├── speaking_score (FLOAT)
├── grammar_score (FLOAT)
├── vocabulary_score (FLOAT)
├── fluency_score (FLOAT)
├── listening_score (FLOAT)
├── fluency_index (FLOAT) -- Calculated
├── primary_skill (VARCHAR) -- Weakest skill
├── secondary_skill (VARCHAR)
├── updated_at (TIMESTAMP)
└── created_at (TIMESTAMP)

-- 2. Weekly Skill Snapshot (criado toda segunda-feira)
weekly_skill_snapshot
├── id (UUID)
├── user_id (UUID) → auth.users
├── week_start (DATE) -- Monday
├── fluency_index (FLOAT)
├── primary_skill (VARCHAR)
├── secondary_skill (VARCHAR)
├── speaking_score (FLOAT)
├── grammar_score (FLOAT)
├── vocabulary_score (FLOAT)
├── fluency_score (FLOAT)
├── listening_score (FLOAT)
└── created_at (TIMESTAMP)

-- 3. Weekly Plans (plano ativo ou arquivado)
weekly_plans
├── id (UUID)
├── user_id (UUID) → auth.users
├── week_start (DATE)
├── level (VARCHAR)
├── focus (JSONB)
├── logic (TEXT)
├── primary_focus (VARCHAR) -- NEW
├── secondary_focus (VARCHAR) -- NEW
├── generated_from_snapshot (UUID) → weekly_skill_snapshot -- NEW
├── teacher_adjusted (BOOLEAN) -- NEW
├── status (VARCHAR) -- NEW: 'active' / 'archived'
├── regeneration_reason (VARCHAR) -- NEW
├── evaluation (JSONB)
└── created_at (TIMESTAMP)

-- 4. Daily Tasks (tarefas do plano)
daily_tasks
├── id (UUID)
├── plan_id (UUID) → weekly_plans
├── user_id (UUID) → auth.users
├── day_of_week (INT)
├── skill (VARCHAR)
├── task_type (VARCHAR) -- NEW: 'speaking', 'grammar', etc.
├── content (JSONB)
├── completed (BOOLEAN)
├── score (INT)
├── estimated_minutes (INT)
├── difficulty (VARCHAR)
├── generated_by (VARCHAR) -- NEW: 'ai' / 'teacher'
└── completed_at (TIMESTAMP)
```

### Relacionamentos

```
auth.users (1) ──→ (1) user_skill_profile
auth.users (1) ──→ (N) weekly_skill_snapshot
auth.users (1) ──→ (N) weekly_plans
weekly_skill_snapshot (1) ──→ (N) weekly_plans (via generated_from_snapshot)
weekly_plans (1) ──→ (N) daily_tasks
auth.users (1) ──→ (N) speaking_submissions
```

---

## 🎯 Regras de Negócio

### Regeneração Condicional

| Condição | Threshold | Ação | Razão |
|----------|-----------|------|-------|
| FI aumentou | ≥ +3 pontos | Regenerar | `fi_improvement` |
| FI diminuiu | ≤ -3 pontos | Regenerar | `fi_decline` |
| Primary skill mudou | Diferente | Regenerar | `primary_skill_changed` |
| Professor forçou | Manual | Regenerar | `teacher_forced` |
| Primeiro plano | Sem snapshot | Regenerar | `first_plan` |
| Estável | < ±3 pontos | Manter | `stable` |

### Cálculo de Fluency Index

```
FI = (Grammar × 0.25) + (Fluency × 0.30) + (Vocabulary × 0.25) 
     + (Pronunciation × 0.10) + (Clarity × 0.10)
```

**Pesos:**
- Fluency: 30% (mais importante)
- Grammar: 25%
- Vocabulary: 25%
- Pronunciation: 10%
- Clarity: 10%

### Identificação de Skills Dominantes

```sql
-- Primary skill = menor score (área mais fraca)
-- Secondary skill = segundo menor score

WITH skill_scores AS (
  SELECT 'grammar' as skill, grammar_score as score
  UNION ALL SELECT 'fluency', fluency_score
  UNION ALL SELECT 'vocabulary', vocabulary_score
  UNION ALL SELECT 'pronunciation', pronunciation_score
  UNION ALL SELECT 'clarity', clarity_score
),
ranked AS (
  SELECT skill, score, ROW_NUMBER() OVER (ORDER BY score ASC) as rank
  FROM skill_scores
)
SELECT 
  MAX(CASE WHEN rank = 1 THEN skill END) as primary_skill,
  MAX(CASE WHEN rank = 2 THEN skill END) as secondary_skill
FROM ranked;
```

### Estrutura do Plano Semanal

| Dia | Tipo de Task | Foco |
|-----|--------------|------|
| 1 | Speaking | Primary weakness |
| 2 | Grammar / Vocabulary | Reinforcement |
| 3 | Listening | Comprehension |
| 4 | Speaking | Secondary weakness |
| 5 | Vocabulary / Reading | Expansion |
| 6 | Review | Mixed skills |
| 7 | Re-evaluation Speaking | Assessment |

### Dificuldade Adaptativa

| Fluency Index | Dificuldade |
|---------------|-------------|
| 0-30 | Easy |
| 31-60 | Medium |
| 61-100 | Hard |

---

## 🔐 Segurança e Permissões

### RLS Policies

```sql
-- user_skill_profile
- Users can view their own profile
- Service role can manage all profiles

-- weekly_skill_snapshot
- Users can view their own snapshots
- Service role can manage all snapshots

-- weekly_plans
- Users can view their own plans
- Teachers can view their students' plans
- Service role can manage all plans

-- daily_tasks
- Users can view and update their own tasks
- Teachers can view their students' tasks
- Service role can manage all tasks
```

### Edge Function Authentication

```typescript
// Service role key required for:
- check-weekly-regeneration (cron job)
- force-weekly-regeneration (teacher action)

// User JWT required for:
- generate_task_content (student action)
- complete_task (student action)
```

---

## 📊 Métricas e Analytics

### KPIs a Monitorar

1. **Taxa de Regeneração**
   - % de planos regenerados vs mantidos
   - Distribuição por razão (FI improvement, decline, skill change)

2. **Evolução de FI**
   - FI médio por semana
   - Taxa de crescimento
   - Distribuição de FI (histograma)

3. **Engajamento**
   - Taxa de conclusão de tasks
   - Tempo médio por task
   - Tasks completadas por dia da semana

4. **Efetividade**
   - Correlação entre FI e conclusão de tasks
   - Melhoria de primary skill após foco
   - Satisfação do aluno (surveys)

5. **Custos**
   - Chamadas de IA por mês
   - Custo por aluno
   - Redução vs modelo anterior

---

## 🚀 Escalabilidade

### Performance Considerations

1. **Cron Job Optimization**
   - Processar usuários em batches (100 por vez)
   - Usar queue para grandes volumes
   - Timeout de 5 minutos por batch

2. **Database Indexes**
   - `user_skill_profile(user_id)` - UNIQUE
   - `weekly_skill_snapshot(user_id, week_start)` - UNIQUE
   - `weekly_plans(user_id, status)` - Composite
   - `daily_tasks(plan_id, day_of_week)` - Composite

3. **Caching Strategy**
   - Cache skill profiles no app (5 min TTL)
   - Cache planos ativos (1 hora TTL)
   - Invalidar cache após speaking submission

4. **AI Rate Limiting**
   - Max 1 plano por usuário por semana
   - Retry com exponential backoff
   - Fallback para plano genérico se IA falhar

---

**Documento criado em:** 2026-02-23  
**Versão:** 1.0  
**Status:** Arquitetura completa documentada
