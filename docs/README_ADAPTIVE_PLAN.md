# 📘 Adaptive Weekly Plan System - Documentação Completa

## 🎯 Visão Geral

Sistema de planos semanais adaptativos baseado em **Speaking + Fluency Index**, com regeneração **condicional** para evitar mudanças caóticas e custos excessivos com IA.

### Conceito Central
```
Speaking → FI → Skill Profile → Weekly Plan → Execução → Nova Speaking
```

**Plano só muda quando necessário:**
- ✅ FI mudou ±3 pontos
- ✅ Primary skill mudou
- ✅ Professor forçou regeneração
- ❌ Mudanças automáticas a cada semana

---

## 📚 Documentos Disponíveis

### 1. [ADAPTIVE_WEEKLY_PLAN_IMPLEMENTATION.md](./ADAPTIVE_WEEKLY_PLAN_IMPLEMENTATION.md)
**Documento técnico completo** com todas as fases de implementação.

**Conteúdo:**
- ✅ Objetivos e conceitos
- ✅ Regras de regeneração
- ✅ Estrutura de banco (SQL completo)
- ✅ Edge Functions (TypeScript)
- ✅ UI Mobile (Flutter)
- ✅ Professor Mode (React)
- ✅ Roadmap de 8 semanas
- ✅ Checklist de implementação

**Quando usar:** Referência principal para implementação completa.

---

### 2. [ADAPTIVE_PLAN_ARCHITECTURE.md](./ADAPTIVE_PLAN_ARCHITECTURE.md)
**Arquitetura visual** do sistema com diagramas e fluxos.

**Conteúdo:**
- 🎨 Diagrama completo do sistema
- 🔄 Fluxos de dados detalhados
- 🗄️ Estrutura de banco com relacionamentos
- 🎯 Regras de negócio
- 🔐 Segurança e permissões
- 📊 Métricas e KPIs
- 🚀 Considerações de escalabilidade

**Quando usar:** Para entender a arquitetura antes de implementar.

---

### 3. [ADAPTIVE_PLAN_NEXT_STEPS.md](./ADAPTIVE_PLAN_NEXT_STEPS.md)
**Guia prático** de implementação passo a passo.

**Conteúdo:**
- ✅ O que já foi criado
- 📋 Checklist por fase
- 🧪 Testes recomendados
- 📊 Queries de monitoramento
- 🔧 Troubleshooting
- 💡 Comandos práticos

**Quando usar:** Durante a implementação, como guia de execução.

---

### 4. [ADAPTIVE_PLAN_EXAMPLES.md](./ADAPTIVE_PLAN_EXAMPLES.md)
**Exemplos práticos** de cenários reais.

**Conteúdo:**
- 📖 6 cenários completos:
  1. Primeiro plano do aluno
  2. Melhoria significativa (FI +5)
  3. Estabilidade (sem mudança)
  4. Declínio (FI -4)
  5. Professor força regeneração
  6. Mudança de primary skill
- 🧪 Testes de integração
- 📊 Queries de análise

**Quando usar:** Para entender comportamentos esperados e testar.

---

## 🚀 Quick Start

### Passo 1: Aplicar Migração SQL
```bash
cd learn_english_application/learn_english_admin

# Via Supabase CLI
supabase db push

# OU via Dashboard
# Database > SQL Editor > Executar migration file
```

**Arquivo:** `supabase/migrations/20260223_adaptive_weekly_plan_phase1.sql`

### Passo 2: Deploy Edge Functions
```bash
# Deploy check-weekly-regeneration
supabase functions deploy check-weekly-regeneration

# Deploy ai-orchestrator (atualizado)
supabase functions deploy ai-orchestrator
```

**Arquivos:**
- `supabase/functions/check-weekly-regeneration/index.ts`
- `supabase/functions/ai-orchestrator/index.ts` (atualizado)

### Passo 3: Configurar Cron Job
```sql
-- Via Supabase Dashboard > Database > Cron Jobs
SELECT cron.schedule(
  'weekly-plan-regeneration',
  '0 0 * * 1', -- Segunda-feira 00:00
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT.supabase.co/functions/v1/check-weekly-regeneration',
    headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
  );
  $$
);
```

### Passo 4: Testar
```bash
# 1. Criar speaking submission de teste
# 2. Verificar skill profile atualizado
# 3. Rodar regeneração manual
# 4. Verificar plano criado
```

Ver detalhes em [ADAPTIVE_PLAN_NEXT_STEPS.md](./ADAPTIVE_PLAN_NEXT_STEPS.md)

---

## 📊 Estrutura de Arquivos Criados

```
learn_english_application/
├── learn_english_admin/
│   ├── docs/
│   │   ├── README_ADAPTIVE_PLAN.md (este arquivo)
│   │   ├── ADAPTIVE_WEEKLY_PLAN_IMPLEMENTATION.md
│   │   ├── ADAPTIVE_PLAN_ARCHITECTURE.md
│   │   ├── ADAPTIVE_PLAN_NEXT_STEPS.md
│   │   └── ADAPTIVE_PLAN_EXAMPLES.md
│   └── supabase/
│       ├── migrations/
│       │   └── 20260223_adaptive_weekly_plan_phase1.sql
│       └── functions/
│           ├── check-weekly-regeneration/
│           │   └── index.ts
│           └── ai-orchestrator/
│               └── index.ts (atualizado)
└── learn_english_app/
    └── lib/
        └── models/
            └── skill_profile_model.dart
```

---

## 🎯 Fases de Implementação

| Fase | Duração | Status | Documentação |
|------|---------|--------|--------------|
| **Fase 1: Base Estrutural** | 2 semanas | ✅ Pronto | SQL migration criada |
| **Fase 2: Regeneração Condicional** | 2 semanas | ✅ Pronto | Edge functions criadas |
| **Fase 3: UI Mobile** | 2 semanas | 📝 Pendente | Modelos criados |
| **Fase 4: Professor Mode** | 2 semanas | 📝 Pendente | Especificado |

**Total:** 8 semanas

---

## 🔑 Conceitos-Chave

### Fluency Index (FI)
Métrica calculada que representa o nível geral de fluência do aluno.

```
FI = (Grammar × 0.25) + (Fluency × 0.30) + (Vocabulary × 0.25) 
     + (Pronunciation × 0.10) + (Clarity × 0.10)
```

### Primary Skill
Habilidade com **menor score** (área mais fraca que precisa de foco).

### Secondary Skill
Segunda habilidade mais fraca.

### Regeneração Condicional
Plano só é regenerado quando:
- FI mudou ≥ ±3 pontos
- Primary skill mudou
- Professor forçou

### Snapshot Semanal
Captura do estado do aluno no início da semana (segunda-feira) para comparação.

---

## 📊 Tabelas Principais

| Tabela | Propósito | Atualização |
|--------|-----------|-------------|
| `user_skill_profile` | Perfil atual de habilidades | Após cada speaking |
| `weekly_skill_snapshot` | Estado no início da semana | Segunda-feira 00:00 |
| `weekly_plans` | Planos semanais | Quando regenerado |
| `daily_tasks` | Tarefas do plano | Com o plano |

---

## 🔄 Fluxo Simplificado

```
1. Aluno completa Speaking Task
   ↓
2. Trigger atualiza user_skill_profile
   ↓
3. Segunda-feira 00:00: Cron Job
   ↓
4. check-weekly-regeneration
   ├─ Cria snapshot
   ├─ Compara com anterior
   └─ Decide: Regenerar ou Manter
   ↓
5. Se regenerar:
   ├─ Arquiva plano anterior
   ├─ Chama ai-orchestrator
   └─ Cria novo plano + tasks
   ↓
6. Aluno vê plano atualizado no app
```

---

## 🧪 Testes Essenciais

### 1. Teste de Trigger
```sql
-- Inserir speaking submission
-- Verificar user_skill_profile atualizado
```

### 2. Teste de Regeneração
```bash
# Simular mudança de FI > 3
# Rodar check-weekly-regeneration
# Verificar novo plano criado
```

### 3. Teste de Estabilidade
```bash
# Simular mudança de FI < 3
# Rodar check-weekly-regeneration
# Verificar plano mantido
```

Ver detalhes em [ADAPTIVE_PLAN_EXAMPLES.md](./ADAPTIVE_PLAN_EXAMPLES.md)

---

## 📈 Métricas de Sucesso

### KPIs a Monitorar

1. **Taxa de Regeneração**
   - Meta: 30-40% dos planos regenerados
   - Indica adaptação sem excesso

2. **Evolução de FI**
   - Meta: Crescimento médio de +2 pontos/mês
   - Indica efetividade do sistema

3. **Engajamento**
   - Meta: 80% de conclusão de tasks
   - Indica relevância do plano

4. **Custo de IA**
   - Meta: Redução de 70% vs modelo anterior
   - Indica eficiência

---

## 🔧 Troubleshooting Rápido

### Problema: Trigger não funciona
```sql
-- Verificar trigger
SELECT * FROM pg_trigger WHERE tgname = 'on_speaking_submission_update_profile';

-- Recriar se necessário
-- Ver SQL completo em ADAPTIVE_WEEKLY_PLAN_IMPLEMENTATION.md
```

### Problema: Edge function erro 401
- Verificar `SUPABASE_SERVICE_ROLE_KEY`
- Verificar RLS policies
- Usar service role key, não anon key

### Problema: Plano não regenera
```sql
-- Verificar snapshot criado
SELECT * FROM weekly_skill_snapshot 
WHERE user_id = 'uuid' 
ORDER BY week_start DESC LIMIT 1;

-- Verificar FI delta
SELECT calculate_fi_delta('uuid');
```

Ver mais em [ADAPTIVE_PLAN_NEXT_STEPS.md](./ADAPTIVE_PLAN_NEXT_STEPS.md)

---

## 💡 Dicas de Implementação

### 1. Comece pela Fase 1
Aplique a migração SQL e teste o trigger antes de avançar.

### 2. Teste com Dados Reais
Use speaking submissions reais para validar cálculos.

### 3. Monitore Logs
Acompanhe logs do Supabase durante testes.

### 4. Ajuste Thresholds
Comece com ±3 pontos, ajuste conforme necessário.

### 5. Comunique Mudanças
Notifique alunos quando plano for regenerado.

---

## 📞 Suporte e Recursos

### Documentação Supabase
- [Edge Functions](https://supabase.com/docs/guides/functions)
- [Database Triggers](https://supabase.com/docs/guides/database/postgres/triggers)
- [Cron Jobs](https://supabase.com/docs/guides/database/extensions/pg_cron)

### Documentação Gemini AI
- [Gemini API](https://ai.google.dev/docs)
- [JSON Mode](https://ai.google.dev/docs/json_mode)

### Documentação Flutter
- [Supabase Flutter](https://supabase.com/docs/reference/dart/introduction)
- [Riverpod](https://riverpod.dev/)

---

## 🎉 Próximos Passos

1. ✅ Ler [ADAPTIVE_PLAN_ARCHITECTURE.md](./ADAPTIVE_PLAN_ARCHITECTURE.md) para entender o sistema
2. ✅ Seguir [ADAPTIVE_PLAN_NEXT_STEPS.md](./ADAPTIVE_PLAN_NEXT_STEPS.md) para implementar Fase 1
3. ✅ Testar com exemplos de [ADAPTIVE_PLAN_EXAMPLES.md](./ADAPTIVE_PLAN_EXAMPLES.md)
4. ✅ Implementar Fases 2, 3 e 4 conforme [ADAPTIVE_WEEKLY_PLAN_IMPLEMENTATION.md](./ADAPTIVE_WEEKLY_PLAN_IMPLEMENTATION.md)

---

## 📝 Changelog

### 2026-02-23 - v1.0
- ✅ Documentação completa criada
- ✅ Migração SQL Fase 1
- ✅ Edge Functions Fase 2
- ✅ Modelos Flutter
- ✅ Exemplos práticos
- ✅ Guias de implementação

---

**Criado em:** 2026-02-23  
**Versão:** 1.0  
**Status:** Pronto para implementação  
**Autor:** Kiro AI Assistant
