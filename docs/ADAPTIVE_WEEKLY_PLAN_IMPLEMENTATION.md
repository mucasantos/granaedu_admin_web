# 📘 IMPLEMENTAÇÃO: Adaptive Weekly Plan – Modelo 2
## Regeneração Condicional com Speaking como Motor Principal

---

## 🎯 VISÃO GERAL

Sistema adaptativo que gera planos semanais baseados em Speaking + Fluency Index, regenerando **apenas quando necessário** para evitar:
- ❌ Mudanças automáticas caóticas
- ❌ Custos excessivos com IA
- ❌ Instabilidade pedagógica

### Conceito Central
```
Speaking → FI → Skill Profile → Weekly Plan → Execução → Nova Speaking
```
**Plano só muda quando há mudança significativa.**

---

## 📊 FASE 1: BASE ESTRUTURAL (Semanas 1-2)

### 1.1 Novas Tabelas Supabase

#### `user_skill_profile`
Perfil de habilidades atualizado após cada Speaking.

```sql
CREATE TABLE IF NOT EXISTS public.user_skill_profile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Scores individuais (0-100)
  speaking_score FLOAT DEFAULT 0,
  grammar_score FLOAT DEFAULT 0,
  vocabulary_score FLOAT DEFAULT 0,
  fluency_score FLOAT DEFAULT 0,
  listening_score FLOAT DEFAULT 0,
  
  -- Fluency Index calculado
  fluency_index FLOAT DEFAULT 0,
  
  -- Skills dominantes
  primary_skill VARCHAR(50), -- skill com menor score
  secondary_skill VARCHAR(50),
  
  -- Metadados
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id)
);

CREATE INDEX idx_user_skill_profile_user_id ON public.user_skill_profile(user_id);
```

#### `weekly_skill_snapshot`
Snapshot do estado no início da semana (segunda-feira).

```sql
CREATE TABLE IF NOT EXISTS public.weekly_skill_snapshot (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start DATE NOT NULL,
  
  -- Estado capturado
  fluency_index FLOAT NOT NULL,
  primary_skill VARCHAR(50),
  secondary_skill VARCHAR(50),
  
  -- Scores snapshot
  speaking_score FLOAT,
  grammar_score FLOAT,
  vocabulary_score FLOAT,
  fluency_score FLOAT,
  listening_score FLOAT,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(user_id, week_start)
);

CREATE INDEX idx_weekly_snapshot_user_week ON public.weekly_skill_snapshot(user_id, week_start);
```

#### Atualizar `weekly_plans`
Adicionar campos para regeneração condicional.

```sql
ALTER TABLE public.weekly_plans
ADD COLUMN IF NOT EXISTS primary_focus VARCHAR(50),
ADD COLUMN IF NOT EXISTS secondary_focus VARCHAR(50),
ADD COLUMN IF NOT EXISTS generated_from_snapshot UUID REFERENCES public.weekly_skill_snapshot(id),
ADD COLUMN IF NOT EXISTS teacher_adjusted BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active'; -- active / archived

CREATE INDEX idx_weekly_plans_status ON public.weekly_plans(status);
CREATE INDEX idx_weekly_plans_snapshot ON public.weekly_plans(generated_from_snapshot);
```

#### Atualizar `daily_tasks`
Adicionar campos para rastreamento.

```sql
ALTER TABLE public.daily_tasks
ADD COLUMN IF NOT EXISTS task_type VARCHAR(50), -- speaking / grammar / vocabulary / listening / review
ADD COLUMN IF NOT EXISTS generated_by VARCHAR(20) DEFAULT 'ai'; -- ai / teacher

CREATE INDEX idx_daily_tasks_type ON public.daily_tasks(task_type);
```

### 1.2 Função: Atualizar Skill Profile após Speaking

```sql
CREATE OR REPLACE FUNCTION public.update_skill_profile_from_speaking()
RETURNS TRIGGER AS $$
DECLARE
  v_grammar FLOAT;
  v_fluency FLOAT;
  v_vocabulary FLOAT;
  v_pronunciation FLOAT;
  v_clarity FLOAT;
  v_fi FLOAT;
  v_primary VARCHAR(50);
  v_secondary VARCHAR(50);
BEGIN
  -- Extrair scores do analysis_json
  v_grammar := COALESCE((NEW.analysis_json->'scores'->>'grammar')::FLOAT, 0);
  v_fluency := COALESCE((NEW.analysis_json->'scores'->>'fluency')::FLOAT, 0);
  v_vocabulary := COALESCE((NEW.analysis_json->'scores'->>'vocabulary')::FLOAT, 0);
  v_pronunciation := COALESCE((NEW.analysis_json->'scores'->>'pronunciation')::FLOAT, 0);
  v_clarity := COALESCE((NEW.analysis_json->'scores'->>'clarity')::FLOAT, 0);
  
  -- Calcular Fluency Index (média ponderada)
  v_fi := (v_grammar * 0.25 + v_fluency * 0.30 + v_vocabulary * 0.25 + v_pronunciation * 0.10 + v_clarity * 0.10);
  
  -- Determinar primary e secondary skills (menores scores)
  WITH skill_scores AS (
    SELECT 'grammar' as skill, v_grammar as score
    UNION ALL SELECT 'fluency', v_fluency
    UNION ALL SELECT 'vocabulary', v_vocabulary
    UNION ALL SELECT 'pronunciation', v_pronunciation
    UNION ALL SELECT 'clarity', v_clarity
  ),
  ranked AS (
    SELECT skill, score, ROW_NUMBER() OVER (ORDER BY score ASC) as rank
    FROM skill_scores
  )
  SELECT 
    MAX(CASE WHEN rank = 1 THEN skill END),
    MAX(CASE WHEN rank = 2 THEN skill END)
  INTO v_primary, v_secondary
  FROM ranked;
  
  -- Upsert no user_skill_profile
  INSERT INTO public.user_skill_profile (
    user_id, speaking_score, grammar_score, vocabulary_score, 
    fluency_score, listening_score, fluency_index, 
    primary_skill, secondary_skill, updated_at
  )
  VALUES (
    NEW.user_id, NEW.score, v_grammar, v_vocabulary,
    v_fluency, 0, -- listening será atualizado por outra fonte
    v_fi, v_primary, v_secondary, NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    speaking_score = EXCLUDED.speaking_score,
    grammar_score = EXCLUDED.grammar_score,
    vocabulary_score = EXCLUDED.vocabulary_score,
    fluency_score = EXCLUDED.fluency_score,
    fluency_index = EXCLUDED.fluency_index,
    primary_skill = EXCLUDED.primary_skill,
    secondary_skill = EXCLUDED.secondary_skill,
    updated_at = NOW();
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
DROP TRIGGER IF EXISTS on_speaking_submission_update_profile ON public.speaking_submissions;
CREATE TRIGGER on_speaking_submission_update_profile
  AFTER INSERT ON public.speaking_submissions
  FOR EACH ROW
  EXECUTE FUNCTION public.update_skill_profile_from_speaking();
```

---

## 🔄 FASE 2: REGENERAÇÃO CONDICIONAL (Semanas 3-4)

### 2.1 Edge Function: `check-weekly-regeneration`

Rodar toda segunda-feira às 00:00 via Supabase Cron.

```typescript
// supabase/functions/check-weekly-regeneration/index.ts

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"

const FI_THRESHOLD = 3; // ±3 pontos

serve(async (req: Request) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

  // Buscar todos os usuários ativos
  const { data: users } = await supabase
    .from('users_profile')
    .select('id')
    .eq('role', 'student');

  if (!users) {
    return new Response(JSON.stringify({ message: 'No users found' }), { status: 200 });
  }

  const today = new Date().toISOString().split('T')[0];
  const results = [];

  for (const user of users) {
    const shouldRegenerate = await checkRegenerationRules(supabase, user.id, today);
    
    if (shouldRegenerate.regenerate) {
      await generateNewPlan(supabase, user.id, today, shouldRegenerate.reason);
      results.push({ user_id: user.id, action: 'regenerated', reason: shouldRegenerate.reason });
    } else {
      results.push({ user_id: user.id, action: 'kept', reason: 'no significant change' });
    }
  }

  return new Response(JSON.stringify({ results }), { status: 200 });
});

async function checkRegenerationRules(supabase: any, userId: string, weekStart: string) {
  // 1. Buscar snapshot anterior
  const { data: lastSnapshot } = await supabase
    .from('weekly_skill_snapshot')
    .select('*')
    .eq('user_id', userId)
    .order('week_start', { ascending: false })
    .limit(1)
    .maybeSingle();

  // 2. Buscar perfil atual
  const { data: currentProfile } = await supabase
    .from('user_skill_profile')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();

  if (!currentProfile) {
    return { regenerate: false, reason: 'no profile' };
  }

  // 3. Criar snapshot atual
  await supabase.from('weekly_skill_snapshot').insert({
    user_id: userId,
    week_start: weekStart,
    fluency_index: currentProfile.fluency_index,
    primary_skill: currentProfile.primary_skill,
    secondary_skill: currentProfile.secondary_skill,
    speaking_score: currentProfile.speaking_score,
    grammar_score: currentProfile.grammar_score,
    vocabulary_score: currentProfile.vocabulary_score,
    fluency_score: currentProfile.fluency_score,
    listening_score: currentProfile.listening_score
  });

  // 4. Verificar regras
  if (!lastSnapshot) {
    return { regenerate: true, reason: 'first_plan' };
  }

  const fiDelta = currentProfile.fluency_index - lastSnapshot.fluency_index;
  const primaryChanged = currentProfile.primary_skill !== lastSnapshot.primary_skill;

  if (Math.abs(fiDelta) >= FI_THRESHOLD) {
    return { regenerate: true, reason: `fi_delta_${fiDelta > 0 ? 'positive' : 'negative'}` };
  }

  if (primaryChanged) {
    return { regenerate: true, reason: 'primary_skill_changed' };
  }

  return { regenerate: false, reason: 'stable' };
}

async function generateNewPlan(supabase: any, userId: string, weekStart: string, reason: string) {
  // Arquivar plano anterior
  await supabase
    .from('weekly_plans')
    .update({ status: 'archived' })
    .eq('user_id', userId)
    .eq('status', 'active');

  // Buscar perfil e snapshot
  const { data: profile } = await supabase
    .from('user_skill_profile')
    .select('*')
    .eq('user_id', userId)
    .single();

  const { data: snapshot } = await supabase
    .from('weekly_skill_snapshot')
    .select('id')
    .eq('user_id', userId)
    .eq('week_start', weekStart)
    .single();

  // Chamar ai-orchestrator para gerar plano
  await supabase.functions.invoke('ai-orchestrator', {
    body: {
      action: 'generate_adaptive_weekly_plan',
      user_id: userId,
      week_start: weekStart,
      snapshot_id: snapshot.id,
      profile: profile,
      regeneration_reason: reason
    }
  });
}
```

### 2.2 Atualizar `ai-orchestrator` com nova action

```typescript
// Adicionar em ai-orchestrator/index.ts

if (action === 'generate_adaptive_weekly_plan') {
  const { week_start, snapshot_id, profile, regeneration_reason } = body;

  const prompt = `You are generating an adaptive weekly English learning plan.

Student Profile:
- Level: ${profile.fluency_index}/100
- Primary weakness: ${profile.primary_skill}
- Secondary weakness: ${profile.secondary_skill}
- Recent scores: Grammar ${profile.grammar_score}, Fluency ${profile.fluency_score}, Vocabulary ${profile.vocabulary_score}

Regeneration Reason: ${regeneration_reason}

Generate a 7-day plan with:
- 2 Speaking Sessions (focus on ${profile.primary_skill})
- 1 Grammar Reinforcement
- 1 Vocabulary Expansion
- 1 Listening Task
- 1 Re-evaluation Speaking (end of week)
- 1 Review Day

Return JSON:
{
  "primary_focus": "${profile.primary_skill}",
  "secondary_focus": "${profile.secondary_skill}",
  "tasks": [
    {
      "day": 1,
      "task_type": "speaking",
      "skill": "speaking",
      "title": "...",
      "difficulty": "medium",
      "estimated_minutes": 15
    }
  ]
}`;

  const geminiKey = await getGeminiKey();
  const model = await getModel(geminiKey);

  const response = await fetch(`https://generativelanguage.googleapis.com/v1/${model}:generateContent?key=${geminiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generation_config: { response_mime_type: "application/json" }
    })
  });

  const result = await response.json();
  const planData = extractJSON(result.candidates[0].content.parts[0].text);

  // Criar plano
  const { data: newPlan } = await supabase
    .from('weekly_plans')
    .insert({
      user_id: user_id,
      week_start: week_start,
      primary_focus: planData.primary_focus,
      secondary_focus: planData.secondary_focus,
      generated_from_snapshot: snapshot_id,
      status: 'active',
      teacher_adjusted: false
    })
    .select()
    .single();

  // Criar tasks
  const tasks = planData.tasks.map((t: any) => ({
    plan_id: newPlan.id,
    user_id: user_id,
    day_of_week: t.day,
    task_type: t.task_type,
    skill: t.skill,
    content: { title: t.title },
    estimated_minutes: t.estimated_minutes,
    difficulty: t.difficulty,
    generated_by: 'ai'
  }));

  await supabase.from('daily_tasks').insert(tasks);

  return new Response(JSON.stringify({ success: true, plan_id: newPlan.id }), { headers: corsHeaders });
}
```

---

## 📱 FASE 3: UI ATUALIZADA (Semanas 5-6)

### 3.1 Nova Home Mobile (Flutter)

Estrutura de blocos:

```dart
// lib/features/home/widgets/adaptive_home_view.dart

class AdaptiveHomeView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // BLOCO 1: Fluency Index
          FluencyIndexCard(),
          
          // BLOCO 2: This Week Focus
          WeeklyFocusCard(),
          
          // BLOCO 3: Today's Task
          TodayTaskCard(),
          
          // BLOCO 4: Upcoming Tasks
          UpcomingTasksList(),
          
          // BLOCO 5: Tools (secundário)
          ToolsSection(),
        ],
      ),
    );
  }
}
```

#### Bloco 1: Fluency Index Card

```dart
class FluencyIndexCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(skillProfileProvider);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Fluency Index', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            
            // Score circular
            CircularPercentIndicator(
              radius: 60,
              percent: profile.fluencyIndex / 100,
              center: Text('${profile.fluencyIndex.toInt()}', style: TextStyle(fontSize: 32)),
            ),
            
            SizedBox(height: 16),
            
            // Radar Chart
            SkillRadarChart(
              grammar: profile.grammarScore,
              fluency: profile.fluencyScore,
              vocabulary: profile.vocabularyScore,
              speaking: profile.speakingScore,
              listening: profile.listeningScore,
            ),
            
            // Tendência
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(profile.trend > 0 ? Icons.trending_up : Icons.trending_down),
                Text('${profile.trend > 0 ? '+' : ''}${profile.trend.toStringAsFixed(1)} this week'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Bloco 2: Weekly Focus Card

```dart
class WeeklyFocusCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(currentWeeklyPlanProvider);
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This Week Focus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            
            // Primary Focus
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Primary: ${plan.primaryFocus}', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            
            SizedBox(height: 8),
            
            // Secondary Focus
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Secondary: ${plan.secondaryFocus}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### Bloco 3: Today's Task Card

```dart
class TodayTaskCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayTask = ref.watch(todayTaskProvider);
    
    if (todayTask == null) {
      return SizedBox.shrink();
    }
    
    return Card(
      child: InkWell(
        onTap: () => _navigateToTask(context, todayTask),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Today\'s Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Chip(label: Text(todayTask.taskType)),
                ],
              ),
              SizedBox(height: 12),
              
              Text(todayTask.content['title'], style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.timer, size: 16),
                  SizedBox(width: 4),
                  Text('${todayTask.estimatedMinutes} min'),
                  SizedBox(width: 16),
                  Icon(Icons.signal_cellular_alt, size: 16),
                  SizedBox(width: 4),
                  Text(todayTask.difficulty),
                ],
              ),
              
              SizedBox(height: 12),
              
              ElevatedButton(
                onPressed: () => _navigateToTask(context, todayTask),
                child: Text('Start Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 🧑‍🏫 FASE 4: PROFESSOR MODE (Semanas 7-8)

### 4.1 Endpoint: Forçar Regeneração

```typescript
// supabase/functions/force-weekly-regeneration/index.ts

serve(async (req: Request) => {
  const { user_id, teacher_id } = await req.json();
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
  
  // Verificar se teacher tem permissão
  const { data: student } = await supabase
    .from('users_profile')
    .select('teacher_id')
    .eq('id', user_id)
    .single();
  
  if (student.teacher_id !== teacher_id) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 403 });
  }
  
  // Forçar regeneração
  const today = new Date().toISOString().split('T')[0];
  await generateNewPlan(supabase, user_id, today, 'teacher_forced');
  
  return new Response(JSON.stringify({ success: true }), { status: 200 });
});
```

### 4.2 UI Professor (Engage & Assess)

```tsx
// engage_assess_english-class-profiler/components/teacher/StudentPlanManager.tsx

export const StudentPlanManager = ({ studentId }: { studentId: string }) => {
  const [plan, setPlan] = useState<WeeklyPlan | null>(null);
  const [tasks, setTasks] = useState<DailyTask[]>([]);
  
  const handleForceRegeneration = async () => {
    await supabase.functions.invoke('force-weekly-regeneration', {
      body: { user_id: studentId, teacher_id: currentTeacherId }
    });
    
    // Reload plan
    loadPlan();
  };
  
  const handleEditTask = async (taskId: string, updates: Partial<DailyTask>) => {
    await supabase
      .from('daily_tasks')
      .update(updates)
      .eq('id', taskId);
    
    // Mark plan as teacher-adjusted
    await supabase
      .from('weekly_plans')
      .update({ teacher_adjusted: true })
      .eq('id', plan.id);
    
    loadPlan();
  };
  
  return (
    <div>
      <h2>Weekly Plan for {studentName}</h2>
      
      <div className="flex gap-4 mb-4">
        <Button onClick={handleForceRegeneration}>
          Force Regeneration
        </Button>
        <Badge>{plan?.teacher_adjusted ? 'Teacher Adjusted' : 'AI Generated'}</Badge>
      </div>
      
      <div className="grid gap-4">
        {tasks.map(task => (
          <TaskCard 
            key={task.id} 
            task={task} 
            onEdit={(updates) => handleEditTask(task.id, updates)}
          />
        ))}
      </div>
    </div>
  );
};
```

---

## 🚀 CRONOGRAMA DE IMPLEMENTAÇÃO

| Fase | Duração | Entregas |
|------|---------|----------|
| **Fase 1** | 2 semanas | Tabelas, triggers, skill profile update |
| **Fase 2** | 2 semanas | Edge function regeneração, lógica condicional |
| **Fase 3** | 2 semanas | Nova home mobile, UI adaptativa |
| **Fase 4** | 2 semanas | Professor mode, edição de planos |

**Total: 8 semanas**

---

## 📋 CHECKLIST DE IMPLEMENTAÇÃO

### Fase 1: Base Estrutural
- [ ] Criar tabela `user_skill_profile`
- [ ] Criar tabela `weekly_skill_snapshot`
- [ ] Atualizar tabela `weekly_plans`
- [ ] Atualizar tabela `daily_tasks`
- [ ] Criar função `update_skill_profile_from_speaking()`
- [ ] Criar trigger para atualização automática
- [ ] Testar atualização de perfil após speaking

### Fase 2: Regeneração Condicional
- [ ] Criar edge function `check-weekly-regeneration`
- [ ] Implementar lógica de regras (FI delta, primary skill change)
- [ ] Adicionar action `generate_adaptive_weekly_plan` no ai-orchestrator
- [ ] Configurar Supabase Cron para segunda-feira 00:00
- [ ] Testar regeneração manual
- [ ] Testar regeneração automática

### Fase 3: UI Atualizada
- [ ] Criar provider `skillProfileProvider`
- [ ] Criar provider `currentWeeklyPlanProvider`
- [ ] Implementar `FluencyIndexCard`
- [ ] Implementar `WeeklyFocusCard`
- [ ] Implementar `TodayTaskCard`
- [ ] Implementar `UpcomingTasksList`
- [ ] Integrar com home existente
- [ ] Testar navegação e fluxo

### Fase 4: Professor Mode
- [ ] Criar endpoint `force-weekly-regeneration`
- [ ] Implementar `StudentPlanManager` component
- [ ] Adicionar edição de tasks
- [ ] Adicionar histórico de planos
- [ ] Implementar visualização de adaptações
- [ ] Testar permissões de professor

---

## 💰 CONTROLE DE CUSTOS

### Estimativa de Chamadas IA

**Antes (Modelo 1 - Regeneração Sempre):**
- 1 plano/semana/aluno = 52 chamadas/ano/aluno
- 100 alunos = 5.200 chamadas/ano

**Depois (Modelo 2 - Regeneração Condicional):**
- ~30% regeneração real = 15,6 chamadas/ano/aluno
- 100 alunos = 1.560 chamadas/ano

**Redução: 70% de custos com IA**

---

## 🛡️ CONTROLE DE ESTABILIDADE

### Garantias do Sistema

1. **Plano não muda durante a semana** - Mesmo com variação de FI
2. **Mudanças apenas em segunda-feira** - Ou forçadas por professor
3. **Histórico completo** - Todos os snapshots e planos arquivados
4. **Rollback possível** - Professor pode reverter mudanças

---

## 📊 MÉTRICAS DE SUCESSO

### KPIs a Monitorar

1. **Taxa de Regeneração** - % de planos regenerados vs mantidos
2. **Delta FI Médio** - Variação média de Fluency Index
3. **Engajamento** - Taxa de conclusão de tasks
4. **Satisfação** - Feedback de alunos e professores
5. **Custo IA** - Chamadas/mês e custo total

---

## 🔄 CICLO COMPLETO DO SISTEMA

```
┌─────────────────────────────────────────────────────────────┐
│                    ADAPTIVE WEEKLY PLAN                      │
└─────────────────────────────────────────────────────────────┘

1. Speaking Task Completed
   ↓
2. Trigger: update_skill_profile_from_speaking()
   ↓
3. Update user_skill_profile (FI, primary_skill, scores)
   ↓
4. [Segunda-feira 00:00] Edge Function: check-weekly-regeneration
   ↓
5. Create weekly_skill_snapshot
   ↓
6. Check Regeneration Rules:
   - FI delta >= ±3?
   - Primary skill changed?
   - Teacher forced?
   ↓
7a. YES → Generate New Plan (ai-orchestrator)
7b. NO → Keep Current Plan
   ↓
8. Student sees updated plan in home
   ↓
9. Execute tasks during week
   ↓
10. Re-evaluation Speaking (end of week)
    ↓
    [Loop back to step 1]
```

---

## 📝 NOTAS FINAIS

### Pontos de Atenção

1. **Timezone** - Garantir que cron rode no timezone correto
2. **Performance** - Otimizar queries para muitos usuários
3. **Fallback** - Se IA falhar, manter plano anterior
4. **Notificações** - Avisar aluno quando plano mudar
5. **Analytics** - Rastrear todas as regenerações

### Próximos Passos

Após implementação completa:
- [ ] A/B testing com grupo controle
- [ ] Ajuste fino de thresholds (FI delta)
- [ ] Adicionar mais regras de adaptação
- [ ] Integrar com outros módulos (flashcards, essays)
- [ ] Expandir para outros idiomas

---

**Documento criado em:** 2026-02-23  
**Versão:** 1.0  
**Status:** Pronto para implementação
