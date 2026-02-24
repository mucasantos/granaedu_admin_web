# 🚀 Próximos Passos: Implementação do Adaptive Weekly Plan

## ✅ O que já foi criado

### 1. Documentação Completa
- ✅ `ADAPTIVE_WEEKLY_PLAN_IMPLEMENTATION.md` - Documento técnico completo com todas as fases
- ✅ Especificação de tabelas, triggers, edge functions e UI

### 2. Migração SQL (Fase 1)
- ✅ `20260223_adaptive_weekly_plan_phase1.sql`
- ✅ Tabelas: `user_skill_profile`, `weekly_skill_snapshot`
- ✅ Atualizações: `weekly_plans`, `daily_tasks`
- ✅ Trigger automático: `update_skill_profile_from_speaking()`
- ✅ Funções helper: `get_current_week_start()`, `calculate_fi_delta()`

### 3. Edge Functions (Fase 2)
- ✅ `check-weekly-regeneration/index.ts` - Função de regeneração condicional
- ✅ Atualização do `ai-orchestrator` com action `generate_adaptive_weekly_plan`

---

## 📋 Checklist de Implementação

### FASE 1: Base Estrutural (Agora)

#### 1.1 Aplicar Migração SQL
```bash
cd learn_english_application/learn_english_admin

# Aplicar migração no Supabase
supabase db push

# OU via Supabase Dashboard:
# 1. Ir em Database > SQL Editor
# 2. Copiar conteúdo de supabase/migrations/20260223_adaptive_weekly_plan_phase1.sql
# 3. Executar
```

#### 1.2 Testar Trigger de Speaking
```sql
-- Inserir um speaking submission de teste
INSERT INTO public.speaking_submissions (
  user_id, 
  audio_url, 
  transcript, 
  score,
  analysis_json
) VALUES (
  'YOUR_USER_ID',
  'test_audio.m4a',
  'This is a test transcript',
  75,
  '{
    "scores": {
      "grammar": 70,
      "fluency": 80,
      "vocabulary": 75,
      "pronunciation": 72,
      "clarity": 78
    }
  }'::jsonb
);

-- Verificar se user_skill_profile foi atualizado
SELECT * FROM public.user_skill_profile WHERE user_id = 'YOUR_USER_ID';
```

#### 1.3 Verificar Estrutura
```sql
-- Verificar tabelas criadas
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('user_skill_profile', 'weekly_skill_snapshot');

-- Verificar colunas adicionadas
SELECT column_name FROM information_schema.columns 
WHERE table_name = 'weekly_plans' 
AND column_name IN ('primary_focus', 'secondary_focus', 'status');
```

---

### FASE 2: Edge Functions (Próximo)

#### 2.1 Deploy Edge Functions
```bash
cd learn_english_application/learn_english_admin

# Deploy check-weekly-regeneration
supabase functions deploy check-weekly-regeneration

# Deploy ai-orchestrator (atualizado)
supabase functions deploy ai-orchestrator
```

#### 2.2 Configurar Supabase Cron
```sql
-- Adicionar cron job para rodar toda segunda-feira às 00:00
-- Via Supabase Dashboard > Database > Cron Jobs
-- OU via SQL:

SELECT cron.schedule(
  'weekly-plan-regeneration',
  '0 0 * * 1', -- Toda segunda-feira às 00:00
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-weekly-regeneration',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
    body := '{}'::jsonb
  );
  $$
);
```

#### 2.3 Testar Regeneração Manual
```bash
# Testar via curl
curl -X POST \
  https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-weekly-regeneration \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json"
```

#### 2.4 Testar Geração de Plano Adaptativo
```bash
# Testar via curl
curl -X POST \
  https://YOUR_PROJECT_REF.supabase.co/functions/v1/ai-orchestrator \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "action": "generate_adaptive_weekly_plan",
    "user_id": "YOUR_USER_ID",
    "week_start": "2026-02-24",
    "snapshot_id": "SNAPSHOT_UUID",
    "profile": {
      "fluency_index": 65,
      "primary_skill": "grammar",
      "secondary_skill": "vocabulary",
      "grammar_score": 60,
      "fluency_score": 70,
      "vocabulary_score": 65,
      "speaking_score": 68,
      "listening_score": 72
    },
    "user_level": "B1",
    "user_goal": "Business English",
    "user_interests": ["technology", "business"],
    "regeneration_reason": "fi_improvement"
  }'
```

---

### FASE 3: UI Mobile (Flutter)

#### 3.1 Criar Providers
```dart
// lib/providers/skill_profile_provider.dart
final skillProfileProvider = FutureProvider.autoDispose<SkillProfile?>((ref) async {
  final userId = ref.watch(userDataProvider)?.id;
  if (userId == null) return null;
  
  final response = await supabase
    .from('user_skill_profile')
    .select()
    .eq('user_id', userId)
    .maybeSingle();
  
  return response != null ? SkillProfile.fromJson(response) : null;
});

// lib/providers/current_weekly_plan_provider.dart
final currentWeeklyPlanProvider = FutureProvider.autoDispose<WeeklyPlanModel?>((ref) async {
  final userId = ref.watch(userDataProvider)?.id;
  if (userId == null) return null;
  
  final response = await supabase
    .from('weekly_plans')
    .select()
    .eq('user_id', userId)
    .eq('status', 'active')
    .order('week_start', ascending: false)
    .limit(1)
    .maybeSingle();
  
  return response != null ? WeeklyPlanModel.fromJson(response) : null;
});
```

#### 3.2 Criar Models
```dart
// lib/models/skill_profile_model.dart
class SkillProfile {
  final String id;
  final String userId;
  final double speakingScore;
  final double grammarScore;
  final double vocabularyScore;
  final double fluencyScore;
  final double listeningScore;
  final double fluencyIndex;
  final String primarySkill;
  final String secondarySkill;
  
  // ... constructor, fromJson, toJson
}
```

#### 3.3 Criar Widgets
Seguir estrutura documentada em `ADAPTIVE_WEEKLY_PLAN_IMPLEMENTATION.md` Fase 3:
- `FluencyIndexCard`
- `WeeklyFocusCard`
- `TodayTaskCard`
- `UpcomingTasksList`

---

### FASE 4: Professor Mode (Engage & Assess)

#### 4.1 Criar Edge Function
```bash
# Criar supabase/functions/force-weekly-regeneration/index.ts
# (Código já documentado em ADAPTIVE_WEEKLY_PLAN_IMPLEMENTATION.md)

supabase functions deploy force-weekly-regeneration
```

#### 4.2 Criar UI React
```tsx
// engage_assess_english-class-profiler/components/teacher/StudentPlanManager.tsx
// (Código já documentado em ADAPTIVE_WEEKLY_PLAN_IMPLEMENTATION.md)
```

---

## 🧪 Testes Recomendados

### 1. Teste de Trigger
- [ ] Criar speaking submission
- [ ] Verificar atualização de user_skill_profile
- [ ] Verificar cálculo correto de FI
- [ ] Verificar identificação de primary/secondary skills

### 2. Teste de Regeneração
- [ ] Criar snapshot inicial
- [ ] Simular mudança de FI > 3 pontos
- [ ] Rodar check-weekly-regeneration
- [ ] Verificar criação de novo plano
- [ ] Verificar arquivamento de plano anterior

### 3. Teste de Estabilidade
- [ ] Criar plano ativo
- [ ] Simular mudança de FI < 3 pontos
- [ ] Rodar check-weekly-regeneration
- [ ] Verificar que plano foi mantido

### 4. Teste de UI
- [ ] Visualizar Fluency Index
- [ ] Visualizar Weekly Focus
- [ ] Visualizar Today's Task
- [ ] Navegar para task
- [ ] Completar task
- [ ] Verificar atualização de UI

---

## 📊 Monitoramento

### Queries Úteis

```sql
-- Ver todos os skill profiles
SELECT 
  u.name,
  sp.fluency_index,
  sp.primary_skill,
  sp.secondary_skill,
  sp.updated_at
FROM user_skill_profile sp
JOIN users_profile u ON u.id = sp.user_id
ORDER BY sp.updated_at DESC;

-- Ver snapshots da semana
SELECT 
  u.name,
  ws.week_start,
  ws.fluency_index,
  ws.primary_skill
FROM weekly_skill_snapshot ws
JOIN users_profile u ON u.id = ws.user_id
WHERE ws.week_start >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY ws.week_start DESC;

-- Ver planos ativos
SELECT 
  u.name,
  wp.week_start,
  wp.primary_focus,
  wp.secondary_focus,
  wp.status,
  wp.regeneration_reason
FROM weekly_plans wp
JOIN users_profile u ON u.id = wp.user_id
WHERE wp.status = 'active'
ORDER BY wp.week_start DESC;

-- Ver taxa de regeneração
SELECT 
  regeneration_reason,
  COUNT(*) as count
FROM weekly_plans
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY regeneration_reason
ORDER BY count DESC;
```

---

## 🔧 Troubleshooting

### Problema: Trigger não está atualizando skill profile
**Solução:**
```sql
-- Verificar se trigger existe
SELECT * FROM pg_trigger WHERE tgname = 'on_speaking_submission_update_profile';

-- Recriar trigger se necessário
DROP TRIGGER IF EXISTS on_speaking_submission_update_profile ON public.speaking_submissions;
CREATE TRIGGER on_speaking_submission_update_profile
  AFTER INSERT ON public.speaking_submissions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_skill_profile_from_speaking();
```

### Problema: Edge function retorna erro 401
**Solução:**
- Verificar se `SUPABASE_SERVICE_ROLE_KEY` está configurada
- Verificar RLS policies nas tabelas
- Usar service role key, não anon key

### Problema: Plano não está sendo regenerado
**Solução:**
```sql
-- Verificar se snapshot foi criado
SELECT * FROM weekly_skill_snapshot 
WHERE user_id = 'YOUR_USER_ID' 
ORDER BY week_start DESC LIMIT 1;

-- Verificar FI delta
SELECT calculate_fi_delta('YOUR_USER_ID');

-- Forçar regeneração manual
-- Via edge function force-weekly-regeneration
```

---

## 📞 Suporte

Se encontrar problemas:
1. Verificar logs do Supabase Dashboard
2. Verificar logs das Edge Functions
3. Executar queries de monitoramento
4. Consultar documentação completa em `ADAPTIVE_WEEKLY_PLAN_IMPLEMENTATION.md`

---

**Última atualização:** 2026-02-23  
**Status:** Pronto para implementação Fase 1
