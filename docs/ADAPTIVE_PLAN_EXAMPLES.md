# 📚 Exemplos Práticos: Adaptive Weekly Plan System

## 🎯 Cenários de Uso

---

## Cenário 1: Primeiro Plano do Aluno

### Situação
Maria acabou de se cadastrar no app e completou sua primeira avaliação de speaking.

### Dados Iniciais
```json
{
  "user_id": "uuid-maria",
  "speaking_submission": {
    "score": 65,
    "analysis_json": {
      "scores": {
        "grammar": 55,
        "fluency": 70,
        "vocabulary": 60,
        "pronunciation": 75,
        "clarity": 65
      }
    }
  }
}
```

### Processamento Automático

#### 1. Trigger atualiza skill profile
```sql
-- Resultado em user_skill_profile
{
  "user_id": "uuid-maria",
  "speaking_score": 65,
  "grammar_score": 55,
  "fluency_score": 70,
  "vocabulary_score": 60,
  "pronunciation_score": 75,
  "clarity_score": 65,
  "fluency_index": 63.5,  -- Calculado: (55*0.25 + 70*0.30 + 60*0.25 + 75*0.10 + 65*0.10)
  "primary_skill": "grammar",  -- Menor score
  "secondary_skill": "vocabulary"  -- Segundo menor
}
```

#### 2. Segunda-feira: Check de regeneração
```javascript
// check-weekly-regeneration detecta primeiro plano
{
  "regenerate": true,
  "reason": "first_plan"
}
```

#### 3. IA gera plano adaptativo
```json
{
  "primary_focus": "grammar",
  "secondary_focus": "vocabulary",
  "tasks": [
    {
      "day": 1,
      "task_type": "speaking",
      "skill": "speaking",
      "title": "Describing Your Daily Routine",
      "difficulty": "medium",
      "estimated_minutes": 15
    },
    {
      "day": 2,
      "task_type": "grammar",
      "skill": "grammar",
      "title": "Present Simple vs Present Continuous",
      "difficulty": "medium",
      "estimated_minutes": 20
    },
    {
      "day": 3,
      "task_type": "listening",
      "skill": "listening",
      "title": "Podcast: Morning Routines",
      "difficulty": "medium",
      "estimated_minutes": 15
    },
    {
      "day": 4,
      "task_type": "speaking",
      "skill": "speaking",
      "title": "Talking About Your Hobbies",
      "difficulty": "medium",
      "estimated_minutes": 15
    },
    {
      "day": 5,
      "task_type": "vocabulary",
      "skill": "vocabulary",
      "title": "Common Phrasal Verbs",
      "difficulty": "medium",
      "estimated_minutes": 20
    },
    {
      "day": 6,
      "task_type": "review",
      "skill": "mixed",
      "title": "Weekly Review Quiz",
      "difficulty": "medium",
      "estimated_minutes": 15
    },
    {
      "day": 7,
      "task_type": "speaking",
      "skill": "speaking",
      "title": "Re-evaluation: Tell Me About Yourself",
      "difficulty": "medium",
      "estimated_minutes": 20
    }
  ]
}
```

### Resultado na UI Mobile
```
┌─────────────────────────────────────┐
│ Fluency Index                       │
│                                     │
│         63.5                        │
│      ●────────●                     │
│     /          \                    │
│    ●            ●                   │
│     \          /                    │
│      ●────────●                     │
│                                     │
│ ↗ First assessment completed        │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ This Week Focus                     │
│                                     │
│ ⭐ Primary: Grammar                 │
│ 📈 Secondary: Vocabulary            │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Today's Task                        │
│                                     │
│ 🎤 Describing Your Daily Routine    │
│ ⏱ 15 min  📊 Medium                 │
│                                     │
│ [Start Task]                        │
└─────────────────────────────────────┘
```

---

## Cenário 2: Melhoria Significativa (FI +5)

### Situação
João completou a semana com sucesso e melhorou significativamente.

### Dados da Semana Anterior
```json
{
  "last_snapshot": {
    "week_start": "2026-02-17",
    "fluency_index": 58,
    "primary_skill": "fluency",
    "secondary_skill": "grammar"
  }
}
```

### Dados Atuais (após speaking de domingo)
```json
{
  "current_profile": {
    "fluency_index": 68,  // +10 pontos!
    "primary_skill": "grammar",  // Mudou de fluency para grammar
    "secondary_skill": "vocabulary",
    "grammar_score": 62,
    "fluency_score": 75,  // Melhorou muito
    "vocabulary_score": 65,
    "speaking_score": 70,
    "listening_score": 68
  }
}
```

### Processamento na Segunda-feira

#### 1. Cálculo de delta
```javascript
FI_delta = 68 - 58 = +10  // Excede threshold de +3
primary_changed = true  // "fluency" → "grammar"
```

#### 2. Decisão de regeneração
```javascript
{
  "regenerate": true,
  "reason": "fi_improvement",
  "fiDelta": 10,
  "primaryChanged": true
}
```

#### 3. Novo plano gerado
```json
{
  "primary_focus": "grammar",
  "secondary_focus": "vocabulary",
  "regeneration_reason": "fi_improvement",
  "tasks": [
    // Tarefas mais desafiadoras (difficulty: "hard")
    {
      "day": 1,
      "title": "Advanced Grammar: Conditionals",
      "difficulty": "hard"  // Aumentou dificuldade
    }
  ]
}
```

### Notificação para o Aluno
```
🎉 Great progress!

Your Fluency Index improved by 10 points!
We've updated your weekly plan to match your new level.

New focus: Grammar & Vocabulary
```

---

## Cenário 3: Estabilidade (Sem Mudança)

### Situação
Ana completou a semana, mas não houve mudança significativa.

### Dados
```json
{
  "last_snapshot": {
    "fluency_index": 72,
    "primary_skill": "vocabulary"
  },
  "current_profile": {
    "fluency_index": 74,  // +2 pontos (abaixo do threshold)
    "primary_skill": "vocabulary"  // Não mudou
  }
}
```

### Processamento
```javascript
FI_delta = 74 - 72 = +2  // Abaixo do threshold de ±3
primary_changed = false

{
  "regenerate": false,
  "reason": "stable",
  "fiDelta": 2
}
```

### Resultado
- Plano atual é mantido
- Ana continua com as mesmas tarefas da semana
- Sem notificação (comportamento esperado)

---

## Cenário 4: Declínio (FI -4)

### Situação
Pedro teve uma semana difícil e seu desempenho caiu.

### Dados
```json
{
  "last_snapshot": {
    "fluency_index": 65,
    "primary_skill": "grammar"
  },
  "current_profile": {
    "fluency_index": 61,  // -4 pontos
    "primary_skill": "grammar",
    "grammar_score": 52,  // Piorou
    "fluency_score": 68,
    "vocabulary_score": 60
  }
}
```

### Processamento
```javascript
FI_delta = 61 - 65 = -4  // Excede threshold de -3

{
  "regenerate": true,
  "reason": "fi_decline",
  "fiDelta": -4
}
```

### Novo Plano (Adaptado para Recuperação)
```json
{
  "primary_focus": "grammar",
  "secondary_focus": "fluency",
  "tasks": [
    {
      "day": 1,
      "title": "Grammar Basics Review",
      "difficulty": "easy"  // Reduzido para easy
    },
    {
      "day": 2,
      "title": "Simple Sentence Structure",
      "difficulty": "easy"
    }
    // Mais tarefas de revisão e reforço
  ]
}
```

### Notificação
```
📚 Let's get back on track!

We noticed you had a challenging week.
Your new plan focuses on reviewing fundamentals.

Take it easy and build confidence! 💪
```

---

## Cenário 5: Professor Força Regeneração

### Situação
Professora detecta que aluno precisa de foco diferente.

### Ação do Professor (Engage & Assess)
```typescript
// Via UI do professor
await supabase.functions.invoke('force-weekly-regeneration', {
  body: {
    user_id: 'uuid-aluno',
    teacher_id: 'uuid-professora'
  }
});
```

### Processamento
```javascript
{
  "regenerate": true,
  "reason": "teacher_forced"
}
```

### Novo Plano
- Gerado imediatamente (não espera segunda-feira)
- Professor pode editar tasks manualmente
- Flag `teacher_adjusted = true`

### UI do Professor
```
┌─────────────────────────────────────────┐
│ Student: João Silva                     │
│ Current FI: 68                          │
│                                         │
│ [Force Regeneration] [Edit Plan]       │
│                                         │
│ Weekly Plan (Teacher Adjusted)          │
│ ├─ Day 1: Custom Speaking Task         │
│ ├─ Day 2: Grammar Focus (edited)       │
│ └─ ...                                  │
└─────────────────────────────────────────┘
```

---

## Cenário 6: Mudança de Primary Skill

### Situação
Carla melhorou sua fraqueza principal, agora outra skill é a mais fraca.

### Dados
```json
{
  "last_snapshot": {
    "primary_skill": "pronunciation",
    "secondary_skill": "grammar",
    "pronunciation_score": 55,
    "grammar_score": 60
  },
  "current_profile": {
    "primary_skill": "grammar",  // Mudou!
    "secondary_skill": "vocabulary",
    "pronunciation_score": 70,  // Melhorou muito
    "grammar_score": 58  // Agora é o mais fraco
  }
}
```

### Processamento
```javascript
primary_changed = true  // "pronunciation" → "grammar"

{
  "regenerate": true,
  "reason": "primary_skill_changed",
  "primaryChanged": true
}
```

### Novo Plano
```json
{
  "primary_focus": "grammar",  // Novo foco
  "secondary_focus": "vocabulary",
  "tasks": [
    {
      "day": 1,
      "title": "Grammar: Verb Tenses",
      "task_type": "grammar"
    },
    {
      "day": 2,
      "title": "Speaking with Correct Grammar",
      "task_type": "speaking"
    }
    // Mais tarefas focadas em grammar
  ]
}
```

---

## 🧪 Testes de Integração

### Teste 1: Fluxo Completo de Speaking → Regeneração

```bash
# 1. Criar speaking submission
curl -X POST https://YOUR_PROJECT.supabase.co/rest/v1/speaking_submissions \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer USER_JWT" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "uuid-test",
    "audio_url": "test.m4a",
    "transcript": "This is a test",
    "score": 75,
    "analysis_json": {
      "scores": {
        "grammar": 70,
        "fluency": 80,
        "vocabulary": 75,
        "pronunciation": 72,
        "clarity": 78
      }
    }
  }'

# 2. Verificar skill profile atualizado
curl https://YOUR_PROJECT.supabase.co/rest/v1/user_skill_profile?user_id=eq.uuid-test \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer USER_JWT"

# 3. Simular segunda-feira (rodar regeneração)
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/check-weekly-regeneration \
  -H "Authorization: Bearer SERVICE_ROLE_KEY"

# 4. Verificar plano criado
curl https://YOUR_PROJECT.supabase.co/rest/v1/weekly_plans?user_id=eq.uuid-test&status=eq.active \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer USER_JWT"
```

### Teste 2: Verificar Estabilidade (Não Regenerar)

```sql
-- 1. Criar snapshot com FI = 70
INSERT INTO weekly_skill_snapshot (user_id, week_start, fluency_index, primary_skill)
VALUES ('uuid-test', '2026-02-17', 70, 'grammar');

-- 2. Atualizar profile com FI = 72 (delta = +2, abaixo do threshold)
UPDATE user_skill_profile
SET fluency_index = 72, primary_skill = 'grammar'
WHERE user_id = 'uuid-test';

-- 3. Rodar regeneração
-- Resultado esperado: regenerate = false, reason = 'stable'
```

### Teste 3: Professor Force Regeneration

```bash
curl -X POST https://YOUR_PROJECT.supabase.co/functions/v1/force-weekly-regeneration \
  -H "Authorization: Bearer SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "uuid-student",
    "teacher_id": "uuid-teacher"
  }'
```

---

## 📊 Queries de Análise

### Ver evolução de FI de um aluno

```sql
SELECT 
  week_start,
  fluency_index,
  primary_skill,
  secondary_skill
FROM weekly_skill_snapshot
WHERE user_id = 'uuid-aluno'
ORDER BY week_start DESC
LIMIT 10;
```

### Ver taxa de regeneração por razão

```sql
SELECT 
  regeneration_reason,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM weekly_plans
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY regeneration_reason
ORDER BY count DESC;
```

### Ver alunos com maior melhoria

```sql
WITH latest_snapshots AS (
  SELECT 
    user_id,
    fluency_index,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY week_start DESC) as rn
  FROM weekly_skill_snapshot
),
current_fi AS (
  SELECT user_id, fluency_index as current_fi
  FROM latest_snapshots WHERE rn = 1
),
previous_fi AS (
  SELECT user_id, fluency_index as previous_fi
  FROM latest_snapshots WHERE rn = 2
)
SELECT 
  u.name,
  c.current_fi,
  p.previous_fi,
  (c.current_fi - p.previous_fi) as improvement
FROM current_fi c
JOIN previous_fi p ON c.user_id = p.user_id
JOIN users_profile u ON u.id = c.user_id
ORDER BY improvement DESC
LIMIT 10;
```

---

**Documento criado em:** 2026-02-23  
**Versão:** 1.0  
**Status:** Exemplos práticos completos
