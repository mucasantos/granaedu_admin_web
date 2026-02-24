# 🧪 Guia de Teste Rápido: Adaptive Weekly Plan

## ✅ Status Atual

As migrações foram aplicadas com sucesso! Agora vamos testar se tudo está funcionando.

---

## Passo 1: Verificar Tabelas Criadas

### Via Supabase Dashboard

1. Acesse: https://supabase.com/dashboard
2. Selecione seu projeto
3. Vá em **Database** > **SQL Editor**
4. Copie e execute o conteúdo de `verify_tables.sql`

**Resultado esperado:**
```
✅ user_skill_profile - EXISTS
✅ weekly_skill_snapshot - EXISTS
✅ Colunas adicionadas em weekly_plans
✅ Trigger criado
✅ Funções criadas
```

---

## Passo 2: Testar Trigger de Speaking

### 2.1 Inserir Speaking Submission de Teste

Execute no SQL Editor:

```sql
-- Substitua 'YOUR_USER_ID' pelo ID de um usuário real do seu sistema
INSERT INTO public.speaking_submissions (
  user_id, 
  audio_url, 
  transcript, 
  score,
  analysis_json
) VALUES (
  'YOUR_USER_ID',  -- ⚠️ SUBSTITUIR
  'test_audio_adaptive_plan.m4a',
  'This is a test transcript for the adaptive weekly plan system',
  75,
  '{
    "scores": {
      "grammar": 70,
      "fluency": 80,
      "vocabulary": 75,
      "pronunciation": 72,
      "clarity": 78
    },
    "feedback": {
      "strengths": ["Good fluency", "Clear pronunciation"],
      "weaknesses": ["Grammar needs work"]
    }
  }'::jsonb
);
```

### 2.2 Verificar Skill Profile Atualizado

```sql
-- Verificar se user_skill_profile foi criado/atualizado
SELECT 
  user_id,
  speaking_score,
  grammar_score,
  fluency_score,
  vocabulary_score,
  fluency_index,
  primary_skill,
  secondary_skill,
  updated_at
FROM public.user_skill_profile
WHERE user_id = 'YOUR_USER_ID';  -- ⚠️ SUBSTITUIR
```

**Resultado esperado:**
```
user_id: YOUR_USER_ID
speaking_score: 75
grammar_score: 70
fluency_score: 80
vocabulary_score: 75
fluency_index: 74.5  (calculado automaticamente)
primary_skill: grammar  (menor score)
secondary_skill: pronunciation
updated_at: [timestamp recente]
```

### 2.3 Calcular Fluency Index Manualmente (Verificação)

```
FI = (grammar × 0.25) + (fluency × 0.30) + (vocabulary × 0.25) + (pronunciation × 0.10) + (clarity × 0.10)
FI = (70 × 0.25) + (80 × 0.30) + (75 × 0.25) + (72 × 0.10) + (78 × 0.10)
FI = 17.5 + 24 + 18.75 + 7.2 + 7.8
FI = 75.25
```

Se o valor no banco for próximo a 75.25, o trigger está funcionando! ✅

---

## Passo 3: Testar Criação de Snapshot

```sql
-- Criar snapshot manualmente (simular segunda-feira)
INSERT INTO public.weekly_skill_snapshot (
  user_id,
  week_start,
  fluency_index,
  primary_skill,
  secondary_skill,
  speaking_score,
  grammar_score,
  vocabulary_score,
  fluency_score,
  listening_score
)
SELECT 
  user_id,
  CURRENT_DATE as week_start,
  fluency_index,
  primary_skill,
  secondary_skill,
  speaking_score,
  grammar_score,
  vocabulary_score,
  fluency_score,
  listening_score
FROM public.user_skill_profile
WHERE user_id = 'YOUR_USER_ID';  -- ⚠️ SUBSTITUIR

-- Verificar snapshot criado
SELECT * FROM public.weekly_skill_snapshot
WHERE user_id = 'YOUR_USER_ID'  -- ⚠️ SUBSTITUIR
ORDER BY week_start DESC
LIMIT 1;
```

---

## Passo 4: Testar Função de Cálculo de Delta

```sql
-- Testar função calculate_fi_delta
SELECT calculate_fi_delta('YOUR_USER_ID');  -- ⚠️ SUBSTITUIR

-- Deve retornar 0 se houver apenas 1 snapshot
-- Ou a diferença entre FI atual e último snapshot
```

---

## Passo 5: Simular Regeneração (Teste Completo)

### 5.1 Criar Snapshot Inicial

```sql
-- Criar snapshot com FI = 70
INSERT INTO public.weekly_skill_snapshot (
  user_id,
  week_start,
  fluency_index,
  primary_skill,
  secondary_skill,
  speaking_score,
  grammar_score,
  vocabulary_score,
  fluency_score,
  listening_score
) VALUES (
  'YOUR_USER_ID',  -- ⚠️ SUBSTITUIR
  '2026-02-17',  -- Semana passada
  70,
  'grammar',
  'vocabulary',
  68,
  65,
  68,
  72,
  70
);
```

### 5.2 Atualizar Profile com Melhoria

```sql
-- Simular melhoria significativa (FI +5)
UPDATE public.user_skill_profile
SET 
  fluency_index = 75,
  grammar_score = 72,
  fluency_score = 78,
  updated_at = NOW()
WHERE user_id = 'YOUR_USER_ID';  -- ⚠️ SUBSTITUIR
```

### 5.3 Calcular Delta

```sql
-- Verificar delta
SELECT 
  current.fluency_index as current_fi,
  snapshot.fluency_index as last_snapshot_fi,
  (current.fluency_index - snapshot.fluency_index) as fi_delta,
  CASE 
    WHEN ABS(current.fluency_index - snapshot.fluency_index) >= 3 THEN '✅ SHOULD REGENERATE'
    ELSE '❌ KEEP CURRENT PLAN'
  END as decision
FROM public.user_skill_profile current
LEFT JOIN LATERAL (
  SELECT fluency_index
  FROM public.weekly_skill_snapshot
  WHERE user_id = current.user_id
  ORDER BY week_start DESC
  LIMIT 1
) snapshot ON true
WHERE current.user_id = 'YOUR_USER_ID';  -- ⚠️ SUBSTITUIR
```

**Resultado esperado:**
```
current_fi: 75
last_snapshot_fi: 70
fi_delta: 5
decision: ✅ SHOULD REGENERATE
```

---

## Passo 6: Testar Edge Function (Opcional)

Se você já fez deploy das edge functions:

```bash
# Testar check-weekly-regeneration
curl -X POST \
  https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-weekly-regeneration \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json"
```

---

## 📊 Queries de Monitoramento

### Ver Todos os Skill Profiles

```sql
SELECT 
  u.name,
  sp.fluency_index,
  sp.primary_skill,
  sp.secondary_skill,
  sp.updated_at
FROM user_skill_profile sp
JOIN users_profile u ON u.id = sp.user_id
ORDER BY sp.updated_at DESC;
```

### Ver Snapshots da Semana

```sql
SELECT 
  u.name,
  ws.week_start,
  ws.fluency_index,
  ws.primary_skill
FROM weekly_skill_snapshot ws
JOIN users_profile u ON u.id = ws.user_id
WHERE ws.week_start >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY ws.week_start DESC;
```

### Ver Evolução de FI de um Aluno

```sql
SELECT 
  week_start,
  fluency_index,
  primary_skill,
  (fluency_index - LAG(fluency_index) OVER (ORDER BY week_start)) as delta
FROM weekly_skill_snapshot
WHERE user_id = 'YOUR_USER_ID'  -- ⚠️ SUBSTITUIR
ORDER BY week_start DESC;
```

---

## ✅ Checklist de Validação

- [ ] Tabelas criadas (`user_skill_profile`, `weekly_skill_snapshot`)
- [ ] Colunas adicionadas em `weekly_plans` e `daily_tasks`
- [ ] Trigger `update_skill_profile_from_speaking` funciona
- [ ] Fluency Index é calculado corretamente
- [ ] Primary/Secondary skills são identificados
- [ ] Snapshots podem ser criados
- [ ] Função `calculate_fi_delta` funciona
- [ ] Lógica de regeneração está correta (delta >= ±3)

---

## 🔧 Troubleshooting

### Trigger não está atualizando skill profile

```sql
-- Verificar se trigger existe
SELECT * FROM pg_trigger 
WHERE tgname = 'on_speaking_submission_update_profile';

-- Se não existir, executar novamente a migration
-- Ou criar manualmente (ver 20260223_adaptive_weekly_plan_phase1.sql)
```

### Fluency Index está incorreto

```sql
-- Verificar cálculo manual
SELECT 
  user_id,
  grammar_score * 0.25 as grammar_weighted,
  fluency_score * 0.30 as fluency_weighted,
  vocabulary_score * 0.25 as vocabulary_weighted,
  (grammar_score * 0.25 + fluency_score * 0.30 + vocabulary_score * 0.25) as calculated_fi,
  fluency_index as stored_fi
FROM user_skill_profile
WHERE user_id = 'YOUR_USER_ID';
```

### Primary skill está incorreto

```sql
-- Verificar qual é o menor score
SELECT 
  user_id,
  LEAST(grammar_score, fluency_score, vocabulary_score) as lowest_score,
  CASE 
    WHEN grammar_score = LEAST(grammar_score, fluency_score, vocabulary_score) THEN 'grammar'
    WHEN fluency_score = LEAST(grammar_score, fluency_score, vocabulary_score) THEN 'fluency'
    WHEN vocabulary_score = LEAST(grammar_score, fluency_score, vocabulary_score) THEN 'vocabulary'
  END as expected_primary_skill,
  primary_skill as stored_primary_skill
FROM user_skill_profile
WHERE user_id = 'YOUR_USER_ID';
```

---

## 🎉 Próximos Passos

Após validar que tudo está funcionando:

1. **Deploy Edge Functions** (Fase 2)
   - `check-weekly-regeneration`
   - `ai-orchestrator` (atualizado)

2. **Configurar Cron Job** para segunda-feira 00:00

3. **Implementar UI Mobile** (Fase 3)

4. **Implementar Professor Mode** (Fase 4)

Ver detalhes em `ADAPTIVE_PLAN_NEXT_STEPS.md`

---

**Última atualização:** 2026-02-23  
**Status:** Pronto para testes ✅
