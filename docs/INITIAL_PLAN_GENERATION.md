# 🚀 Initial Plan Generation - Mid-Week Signup Solution

## 🎯 Problema Identificado

**Cenário**: Usuário instala o app na terça-feira (ou qualquer dia que não seja segunda)

**Problema Original**:
- Cron job só roda nas segundas-feiras às 00:00
- Usuário fica sem plano semanal até a próxima segunda
- Experiência ruim: tela vazia por vários dias

## ✅ Solução Implementada

### Abordagem: Geração On-Demand no Primeiro Acesso

Quando o usuário acessa a tela "Plan" pela primeira vez:

```
1. Provider verifica se há plano ativo
2. Se NÃO há plano:
   a. Chama função SQL: ensure_weekly_plan_exists()
   b. Função cria snapshot e retorna status
   c. Se status = 'needs_generation':
      - Chama edge function: generate-initial-plan
      - Aguarda 2 segundos
      - Busca plano novamente
3. Exibe plano ou loading state
```

---

## 📊 Componentes da Solução

### 1. Função SQL: `ensure_weekly_plan_exists()`

**Arquivo**: `20260224000003_initial_plan_trigger.sql`

**O que faz**:
- Verifica se existe plano ativo para a semana atual
- Se não existe:
  * Cria snapshot do perfil atual
  * Retorna status `needs_generation`
- Se existe:
  * Retorna plan_id e status `active`

**Retorno**:
```sql
{
  plan_id: UUID | NULL,
  week_start: DATE,
  status: 'active' | 'needs_generation' | 'no_profile',
  message: TEXT
}
```

**Exemplo de uso**:
```sql
SELECT * FROM ensure_weekly_plan_exists('user-uuid-here');
```

### 2. Edge Function: `generate-initial-plan`

**Arquivo**: `supabase/functions/generate-initial-plan/index.ts`

**O que faz**:
- Recebe user_id e week_start
- Busca perfil do usuário (level, goal, interests)
- Chama `ai-orchestrator` com action `generate_adaptive_weekly_plan`
- IA gera plano completo com 7 tasks

**Payload**:
```json
{
  "user_id": "uuid",
  "week_start": "2026-02-24"
}
```

**Resposta**:
```json
{
  "success": true,
  "message": "Initial plan generated successfully",
  "user_id": "uuid",
  "week_start": "2026-02-24",
  "plan_result": { ... }
}
```

### 3. Provider Modificado: `currentWeeklyPlanProvider`

**Arquivo**: `adaptive_plan_providers.dart`

**Fluxo**:
```dart
1. Busca plano ativo no banco
2. Se encontrou → retorna WeeklyPlanModel
3. Se NÃO encontrou:
   a. Chama ensure_weekly_plan_exists()
   b. Se status = 'needs_generation':
      - Invoca generate-initial-plan
      - Aguarda 2 segundos
      - Busca plano novamente
   c. Retorna plano ou null
```

---

## 🔄 Fluxos Completos

### Fluxo 1: Usuário Novo (Terça-feira)

```
Usuário instala app na terça
    ↓
Faz primeiro speaking task
    ↓
Trigger: update_skill_profile_from_speaking()
    ↓
Cria/atualiza user_skill_profile
    ↓
Usuário acessa Tab 2 (Plan)
    ↓
currentWeeklyPlanProvider carrega
    ↓
Não encontra plano ativo
    ↓
Chama ensure_weekly_plan_exists()
    ↓
Função cria snapshot e retorna 'needs_generation'
    ↓
Provider chama generate-initial-plan
    ↓
Edge function chama ai-orchestrator
    ↓
IA gera plano completo
    ↓
Plano salvo no banco (status='active')
    ↓
Provider busca novamente
    ↓
Plano exibido na tela ✅
```

### Fluxo 2: Usuário Existente (Segunda-feira)

```
Segunda-feira 00:00
    ↓
Cron job: check-weekly-regeneration
    ↓
Para cada usuário:
  - Cria snapshot da semana
  - Verifica regras de regeneração
  - Se necessário, gera novo plano
    ↓
Usuário abre app
    ↓
currentWeeklyPlanProvider carrega
    ↓
Encontra plano ativo
    ↓
Plano exibido na tela ✅
```

### Fluxo 3: Usuário Sem Perfil

```
Usuário novo que ainda não fez speaking task
    ↓
Acessa Tab 2 (Plan)
    ↓
currentWeeklyPlanProvider carrega
    ↓
Não encontra plano ativo
    ↓
Chama ensure_weekly_plan_exists()
    ↓
Função retorna 'no_profile'
    ↓
Provider retorna null
    ↓
UI mostra: "Your weekly plan will be generated soon"
    ↓
Usuário faz primeiro speaking task
    ↓
Perfil criado
    ↓
Próxima vez que acessar Plan → plano será gerado
```

---

## 🧪 Como Testar

### Teste 1: Simular Novo Usuário (Mid-Week)

```sql
-- 1. Criar usuário de teste
INSERT INTO auth.users (id, email) 
VALUES ('test-user-uuid', 'test@example.com');

-- 2. Criar perfil básico
INSERT INTO users_profile (id, name, level, role)
VALUES ('test-user-uuid', 'Test User', 'A1', 'student');

-- 3. Criar skill profile (simula primeiro speaking task)
INSERT INTO user_skill_profile (
  user_id, 
  fluency_index, 
  primary_skill, 
  secondary_skill,
  speaking_score,
  grammar_score,
  vocabulary_score
) VALUES (
  'test-user-uuid',
  45.0,
  'grammar',
  'vocabulary',
  50, 40, 45
);

-- 4. Verificar se plano existe
SELECT * FROM weekly_plans 
WHERE user_id = 'test-user-uuid' 
  AND status = 'active';
-- Deve retornar vazio

-- 5. Chamar função de verificação
SELECT * FROM ensure_weekly_plan_exists('test-user-uuid');
-- Deve retornar status = 'needs_generation'

-- 6. Chamar edge function manualmente (ou esperar app fazer)
-- Via Supabase Dashboard ou curl

-- 7. Verificar plano criado
SELECT * FROM weekly_plans 
WHERE user_id = 'test-user-uuid' 
  AND status = 'active';
-- Deve retornar plano com primary_focus e secondary_focus
```

### Teste 2: Testar no App

```
1. Criar novo usuário no app
2. Fazer primeiro speaking task
3. Ir para Tab 2 (Plan)
4. ✅ Deve mostrar loading
5. ✅ Após 2-3 segundos, deve mostrar plano
6. ✅ Primary e Secondary Focus devem estar preenchidos
7. ✅ Today's Task deve aparecer
```

### Teste 3: Verificar Logs

```bash
# No Supabase Dashboard > Edge Functions > Logs
# Procurar por:
[generate-initial-plan] Generating initial plan for user ...
[generate-initial-plan] Calling ai-orchestrator for user ...
[generate-initial-plan] Initial plan generated successfully for user ...
```

---

## 🔧 Aplicar Migração

```bash
cd learn_english_application/learn_english_admin
supabase db push
```

Isso aplicará:
- `20260224000003_initial_plan_trigger.sql` - Função SQL

Depois, fazer deploy do edge function:
```bash
supabase functions deploy generate-initial-plan
```

---

## 📊 Comparação: Antes vs Depois

### Antes

| Dia | Ação | Resultado |
|-----|------|-----------|
| Terça | Usuário instala app | ❌ Sem plano |
| Quarta | Usuário acessa Plan | ❌ Tela vazia |
| Quinta | Usuário acessa Plan | ❌ Tela vazia |
| Sexta | Usuário acessa Plan | ❌ Tela vazia |
| Sábado | Usuário acessa Plan | ❌ Tela vazia |
| Domingo | Usuário acessa Plan | ❌ Tela vazia |
| Segunda 00:00 | Cron job roda | ✅ Plano gerado |
| Segunda 08:00 | Usuário acessa Plan | ✅ Plano aparece |

**Problema**: Usuário fica 6 dias sem plano!

### Depois

| Dia | Ação | Resultado |
|-----|------|-----------|
| Terça | Usuário instala app | - |
| Terça | Faz primeiro speaking | Perfil criado |
| Terça | Acessa Plan | ✅ Plano gerado imediatamente |
| Quarta | Acessa Plan | ✅ Plano ativo |
| ... | ... | ✅ Plano ativo |
| Segunda 00:00 | Cron job roda | ✅ Plano regenerado (se necessário) |

**Solução**: Usuário tem plano desde o primeiro dia!

---

## 🚨 Considerações Importantes

### 1. Performance

- Geração do plano leva ~2-5 segundos (chamada à OpenAI)
- Provider aguarda 2 segundos antes de buscar novamente
- Se plano não estiver pronto, usuário verá loading state
- Na próxima vez que acessar, plano estará lá

### 2. Fallback

Se a geração falhar:
- Usuário vê mensagem: "Your weekly plan will be generated soon"
- Pode fazer pull-to-refresh para tentar novamente
- Cron job da segunda-feira irá gerar de qualquer forma

### 3. Idempotência

- Função `ensure_weekly_plan_exists()` é idempotente
- Pode ser chamada múltiplas vezes sem problemas
- Usa `ON CONFLICT DO UPDATE` para snapshots
- Edge function verifica se plano já existe antes de gerar

### 4. Custos

- Cada geração de plano = 1 chamada à OpenAI
- Usuário novo = 1 chamada imediata
- Cron job semanal = 1 chamada por usuário (se necessário)
- Estimativa: ~2-4 chamadas por usuário/mês

---

## 🐛 Troubleshooting

### Plano não é gerado no primeiro acesso

**Causa**: Edge function não foi deployada
**Solução**:
```bash
supabase functions deploy generate-initial-plan
```

### Erro: "User skill profile not found"

**Causa**: Usuário ainda não fez speaking task
**Solução**: Normal. Plano será gerado após primeiro speaking task

### Plano demora muito para aparecer

**Causa**: OpenAI está lento ou timeout
**Solução**: 
- Aumentar timeout no provider
- Implementar retry logic
- Mostrar mensagem mais clara ao usuário

### Múltiplos planos criados

**Causa**: Race condition (usuário clica várias vezes)
**Solução**: Edge function já verifica se plano existe antes de criar

---

## ✅ Checklist de Validação

- [x] Função SQL criada e testada
- [x] Edge function criada
- [x] Provider modificado
- [x] Migração aplicada
- [ ] Edge function deployada
- [ ] Testado com usuário novo
- [ ] Testado mid-week signup
- [ ] Logs verificados
- [ ] Performance aceitável (<5s)
- [ ] Fallback funciona

---

**Status**: ✅ Implementado (aguardando deploy)
**Próximo passo**: Deploy do edge function
**Data**: 2026-02-24
