# ⏰ Setup: Cron Job para Regeneração Semanal

## 🎯 Objetivo

Configurar um cron job que roda toda **segunda-feira às 00:00 UTC** para verificar se os planos semanais precisam ser regenerados.

---

## Método 1: Via Migração SQL (Recomendado)

### Passo 1: Aplicar Migração

```bash
cd learn_english_application/learn_english_admin
supabase db push
```

A migração `20260224000000_setup_weekly_cron.sql` irá:
- ✅ Habilitar extensão `pg_cron`
- ✅ Criar cron job `weekly-plan-regeneration`
- ✅ Configurar schedule para segunda-feira 00:00

### Passo 2: Configurar Variáveis

Execute no SQL Editor do Supabase Dashboard:

```sql
-- Inserir configurações (substitua pelos valores reais)
INSERT INTO public.app_settings (
  supabase_url,
  service_role_key
) VALUES (
  'https://YOUR_PROJECT_REF.supabase.co',
  'YOUR_SERVICE_ROLE_KEY'
)
ON CONFLICT (id) DO UPDATE SET
  supabase_url = EXCLUDED.supabase_url,
  service_role_key = EXCLUDED.service_role_key;

-- Atualizar cron job com as novas configurações
SELECT public.update_cron_job_url();
```

**Como obter os valores:**
- `YOUR_PROJECT_REF`: Encontre em Settings > API > Project URL
- `YOUR_SERVICE_ROLE_KEY`: Encontre em Settings > API > service_role key (⚠️ Mantenha secreto!)

### Passo 3: Verificar Cron Job

```sql
-- Ver cron job criado
SELECT * FROM public.cron_jobs_view;

-- Deve mostrar:
-- jobname: weekly-plan-regeneration
-- schedule: 0 0 * * 1
-- active: true
```

---

## Método 2: Via Supabase Dashboard (Manual)

Se a migração não funcionar, configure manualmente:

### Passo 1: Acessar Cron Jobs

1. Acesse Supabase Dashboard
2. Vá em **Database** > **Cron Jobs**
3. Clique em **"Create a new cron job"**

### Passo 2: Configurar Job

Preencha os campos:

**Name:**
```
weekly-plan-regeneration
```

**Schedule (Cron Expression):**
```
0 0 * * 1
```
Explicação: `minuto hora dia mês dia_da_semana`
- `0 0` = 00:00 (meia-noite)
- `* *` = todo dia de todo mês
- `1` = segunda-feira (0=domingo, 1=segunda, ..., 6=sábado)

**Command (SQL):**
```sql
SELECT net.http_post(
  url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-weekly-regeneration',
  headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
  ),
  body := '{}'::jsonb,
  timeout_milliseconds := 300000
) AS request_id;
```

⚠️ **IMPORTANTE:** Substitua:
- `YOUR_PROJECT_REF` pelo seu project reference
- `YOUR_SERVICE_ROLE_KEY` pela sua service role key

### Passo 3: Salvar e Ativar

1. Clique em **"Create cron job"**
2. Verifique se o status está **"Active"**

---

## Método 3: Via SQL Direto

Execute no SQL Editor:

```sql
-- Habilitar extensão
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Criar cron job
SELECT cron.schedule(
  'weekly-plan-regeneration',
  '0 0 * * 1',
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-weekly-regeneration',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
    body := '{}'::jsonb,
    timeout_milliseconds := 300000
  ) AS request_id;
  $$
);
```

---

## 🧪 Testar Cron Job

### Teste Manual (Sem Esperar Segunda-feira)

Execute no SQL Editor:

```sql
-- Chamar edge function manualmente
SELECT net.http_post(
  url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-weekly-regeneration',
  headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb,
  body := '{}'::jsonb
) AS request_id;
```

### Ver Histórico de Execuções

```sql
-- Ver últimas 10 execuções
SELECT 
  jobid,
  runid,
  job_pid,
  database,
  username,
  command,
  status,
  return_message,
  start_time,
  end_time
FROM cron.job_run_details 
WHERE jobid = (
  SELECT jobid 
  FROM cron.job 
  WHERE jobname = 'weekly-plan-regeneration'
)
ORDER BY start_time DESC
LIMIT 10;
```

### Ver Logs da Edge Function

1. Acesse Supabase Dashboard
2. Vá em **Edge Functions** > **check-weekly-regeneration**
3. Clique em **"Logs"**
4. Verifique se há execuções recentes

---

## 📊 Monitoramento

### Query para Ver Status do Cron

```sql
SELECT 
  jobname,
  schedule,
  active,
  CASE 
    WHEN active THEN '✅ Active'
    ELSE '❌ Inactive'
  END as status,
  command
FROM cron.job
WHERE jobname = 'weekly-plan-regeneration';
```

### Query para Ver Próxima Execução

```sql
-- Calcular próxima segunda-feira 00:00
SELECT 
  CASE 
    WHEN EXTRACT(DOW FROM CURRENT_TIMESTAMP) = 1 THEN 
      CURRENT_DATE + INTERVAL '7 days'
    ELSE 
      CURRENT_DATE + ((8 - EXTRACT(DOW FROM CURRENT_TIMESTAMP)::INTEGER) || ' days')::INTERVAL
  END + TIME '00:00:00' as next_run;
```

### Alertas Recomendados

Configure alertas para:
- ❌ Cron job falhou
- ⚠️ Cron job não executou na segunda-feira
- ✅ Cron job executou com sucesso

---

## 🔧 Troubleshooting

### Problema: Cron job não está executando

**Verificar se está ativo:**
```sql
SELECT active FROM cron.job WHERE jobname = 'weekly-plan-regeneration';
```

**Ativar se estiver inativo:**
```sql
UPDATE cron.job 
SET active = true 
WHERE jobname = 'weekly-plan-regeneration';
```

### Problema: Edge function retorna erro

**Verificar logs:**
```sql
SELECT return_message 
FROM cron.job_run_details 
WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'weekly-plan-regeneration')
ORDER BY start_time DESC 
LIMIT 1;
```

**Erros comuns:**
- `401 Unauthorized` → Service role key incorreta
- `404 Not Found` → URL da edge function incorreta
- `Timeout` → Edge function demorou mais de 5 minutos

### Problema: Timezone incorreto

O cron usa UTC por padrão. Para ajustar:

```sql
-- Ver timezone atual
SHOW timezone;

-- Ajustar schedule para seu timezone
-- Exemplo: Para executar às 00:00 BRT (UTC-3), use 03:00 UTC
SELECT cron.schedule(
  'weekly-plan-regeneration',
  '0 3 * * 1',  -- 03:00 UTC = 00:00 BRT
  $$ ... $$
);
```

### Problema: Cron job não aparece

**Verificar se pg_cron está habilitado:**
```sql
SELECT * FROM pg_extension WHERE extname = 'pg_cron';
```

**Se não estiver, habilitar:**
```sql
CREATE EXTENSION pg_cron;
```

---

## 🔄 Atualizar Cron Job

### Atualizar Schedule

```sql
-- Remover job existente
SELECT cron.unschedule('weekly-plan-regeneration');

-- Criar com novo schedule
SELECT cron.schedule(
  'weekly-plan-regeneration',
  '0 0 * * 1',  -- Novo schedule
  $$ ... $$
);
```

### Atualizar URL ou Headers

```sql
-- Atualizar app_settings
UPDATE public.app_settings
SET 
  supabase_url = 'https://NEW_URL.supabase.co',
  service_role_key = 'NEW_KEY'
WHERE id = (SELECT id FROM public.app_settings LIMIT 1);

-- Aplicar mudanças
SELECT public.update_cron_job_url();
```

---

## 📋 Checklist de Configuração

- [ ] Extensão `pg_cron` habilitada
- [ ] Cron job `weekly-plan-regeneration` criado
- [ ] Schedule configurado: `0 0 * * 1`
- [ ] URL da edge function correta
- [ ] Service role key configurada
- [ ] Cron job está ativo
- [ ] Teste manual executado com sucesso
- [ ] Logs da edge function verificados
- [ ] Próxima execução agendada para segunda-feira

---

## 🎉 Próximos Passos

Após configurar o cron job:

1. ✅ Testar manualmente
2. ✅ Verificar logs
3. ✅ Aguardar primeira execução automática (segunda-feira)
4. ✅ Monitorar resultados

Ver mais em `ADAPTIVE_PLAN_NEXT_STEPS.md`

---

**Última atualização:** 2026-02-24  
**Status:** Pronto para configuração ✅
