# 🔧 Fix: Leaderboard Ranking Global

## 🐛 Problema Identificado

### Sintomas
- Ranking global mostra valores incorretos (ex: 395/0 e 0)
- Usuário com 15 pontos não aparece corretamente
- Logs não aparecem no console

### Causa Raiz

A view `public.leaderboard` estava retornando apenas 4 colunas:
```sql
SELECT u.id, u.name, u.image_url, COALESCE(w.xp_balance, 0) as xp
```

Mas o código Flutter estava tentando acessar a coluna `streak`:
```dart
streak: player['streak'] ?? 0,  // ❌ Esta coluna não existe na view!
```

Quando uma coluna não existe no Map, o Dart retorna `null`, e o operador `??` usa o valor padrão `0`. Porém, isso pode causar comportamentos inesperados na UI.

---

## ✅ Solução

### 1. Aplicar Migração SQL

```bash
cd learn_english_application/learn_english_admin
supabase db push
```

A migração `20260224000001_fix_leaderboard_view.sql` irá:
- ✅ Adicionar coluna `streak` à view
- ✅ Adicionar colunas `coins` e `hearts` (para uso futuro)
- ✅ Usar `COALESCE` para valores padrão quando usuário não tem wallet

### 2. Verificar View Atualizada

Execute no SQL Editor:

```sql
-- Ver estrutura da view
SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'leaderboard'
ORDER BY ordinal_position;

-- Deve retornar:
-- id          | uuid
-- name        | text
-- image_url   | text
-- xp          | bigint
-- streak      | integer  ✅ NOVA
-- coins       | integer  ✅ NOVA
-- hearts      | integer  ✅ NOVA
-- last_heart_refill | timestamp
```

### 3. Testar Dados

```sql
-- Ver top 10 do ranking
SELECT 
  name,
  xp,
  streak,
  coins,
  hearts
FROM public.leaderboard
LIMIT 10;
```

**Resultado esperado:**
```
name          | xp  | streak | coins | hearts
--------------|-----|--------|-------|-------
João Silva    | 395 | 5      | 100   | 5
Maria Santos  | 250 | 3      | 50    | 4
Pedro Costa   | 15  | 1      | 10    | 5
```

---

## 🧪 Testar no App

### 1. Limpar Cache do Provider

```dart
// No Flutter, force refresh do provider
ref.invalidate(leaderboardProvider);
```

Ou simplesmente:
- Feche e reabra o app
- Ou navegue para outra tab e volte

### 2. Verificar Logs

Agora os logs devem aparecer:

```
flutter: GetLeaderBoard
flutter: LiderBoard
flutter: [{id: uuid-123, name: João Silva, xp: 395, streak: 5, ...}, ...]
flutter: ==================
```

### 3. Verificar UI

- ✅ XP deve aparecer corretamente
- ✅ Streak deve aparecer (ex: "5 day streak")
- ✅ Ranking deve estar ordenado por XP

---

## 🔍 Debug Adicional

### Se os logs ainda não aparecem

1. **Verificar se o provider está sendo chamado:**

```dart
// Adicione log no provider
final leaderboardProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  print("🔍 [Provider] GetLeaderBoard called");
  final result = await SupabaseService().fetchLeaderboard();
  print("🔍 [Provider] Result count: ${result.length}");
  return result;
});
```

2. **Verificar se o serviço está sendo chamado:**

```dart
Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
  try {
    print("🔍 [Service] Fetching leaderboard...");
    
    final response = await client
        .from('leaderboard')
        .select()
        .order('xp', ascending: false);

    print("🔍 [Service] Response type: ${response.runtimeType}");
    print("🔍 [Service] Response length: ${response.length}");
    print("🔍 [Service] First item: ${response.isNotEmpty ? response[0] : 'empty'}");
    
    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print("❌ [Service] Error: $e");
    debugPrint('Supabase: Error fetching leaderboard: $e');
    return [];
  }
}
```

3. **Verificar conexão com Supabase:**

```dart
// Adicione no initState ou no provider
print("🔍 Supabase URL: ${SupabaseService().client.supabaseUrl}");
print("🔍 Supabase connected: ${SupabaseService().client != null}");
```

### Se os valores ainda estão incorretos

1. **Verificar se xp_wallet tem dados:**

```sql
SELECT 
  user_id,
  xp_balance,
  streak,
  coins,
  hearts
FROM public.xp_wallet
LIMIT 10;
```

2. **Verificar se users_profile tem dados:**

```sql
SELECT 
  id,
  name,
  email
FROM public.users_profile
LIMIT 10;
```

3. **Verificar JOIN:**

```sql
-- Ver usuários SEM wallet
SELECT 
  u.id,
  u.name,
  w.xp_balance
FROM public.users_profile u
LEFT JOIN public.xp_wallet w ON u.id = w.user_id
WHERE w.user_id IS NULL;

-- Se houver usuários sem wallet, criar wallet para eles:
INSERT INTO public.xp_wallet (user_id, xp_balance, streak, coins, hearts)
SELECT 
  id,
  0,  -- xp_balance
  0,  -- streak
  0,  -- coins
  5   -- hearts
FROM public.users_profile
WHERE id NOT IN (SELECT user_id FROM public.xp_wallet);
```

---

## 🎯 Melhorias Adicionais (Opcional)

### 1. Adicionar Filtro de Usuários Ativos

```sql
-- Mostrar apenas usuários com XP > 0
DROP VIEW IF EXISTS public.leaderboard;
CREATE VIEW public.leaderboard WITH (security_invoker = true) AS
  SELECT 
    u.id,
    u.name,
    u.image_url,
    COALESCE(w.xp_balance, 0) as xp,
    COALESCE(w.streak, 0) as streak,
    COALESCE(w.coins, 0) as coins,
    COALESCE(w.hearts, 5) as hearts,
    w.last_heart_refill
  FROM public.users_profile u
  LEFT JOIN public.xp_wallet w ON u.id = w.user_id
  WHERE COALESCE(w.xp_balance, 0) > 0  -- ✅ Apenas usuários com XP
  ORDER BY xp DESC;
```

### 2. Adicionar Limite de Top 100

```sql
-- Mostrar apenas top 100
DROP VIEW IF EXISTS public.leaderboard;
CREATE VIEW public.leaderboard WITH (security_invoker = true) AS
  SELECT 
    u.id,
    u.name,
    u.image_url,
    COALESCE(w.xp_balance, 0) as xp,
    COALESCE(w.streak, 0) as streak,
    COALESCE(w.coins, 0) as coins,
    COALESCE(w.hearts, 5) as hearts,
    w.last_heart_refill
  FROM public.users_profile u
  LEFT JOIN public.xp_wallet w ON u.id = w.user_id
  ORDER BY xp DESC
  LIMIT 100;  -- ✅ Top 100 apenas
```

### 3. Adicionar Rank Numérico

```sql
-- Adicionar coluna de rank
DROP VIEW IF EXISTS public.leaderboard;
CREATE VIEW public.leaderboard WITH (security_invoker = true) AS
  SELECT 
    ROW_NUMBER() OVER (ORDER BY COALESCE(w.xp_balance, 0) DESC) as rank,  -- ✅ Rank
    u.id,
    u.name,
    u.image_url,
    COALESCE(w.xp_balance, 0) as xp,
    COALESCE(w.streak, 0) as streak,
    COALESCE(w.coins, 0) as coins,
    COALESCE(w.hearts, 5) as hearts,
    w.last_heart_refill
  FROM public.users_profile u
  LEFT JOIN public.xp_wallet w ON u.id = w.user_id
  ORDER BY xp DESC;
```

---

## ✅ Checklist de Verificação

- [ ] Migração aplicada (`supabase db push`)
- [ ] View `leaderboard` tem coluna `streak`
- [ ] Query SQL retorna dados corretos
- [ ] App Flutter mostra dados corretos
- [ ] Logs aparecem no console
- [ ] Ranking está ordenado por XP
- [ ] Streak aparece para usuários com streak > 0

---

## 📊 Queries Úteis

### Ver Ranking Completo

```sql
SELECT 
  ROW_NUMBER() OVER (ORDER BY xp DESC) as rank,
  name,
  xp,
  streak
FROM public.leaderboard
LIMIT 20;
```

### Ver Usuário Específico no Ranking

```sql
WITH ranked AS (
  SELECT 
    ROW_NUMBER() OVER (ORDER BY xp DESC) as rank,
    *
  FROM public.leaderboard
)
SELECT * FROM ranked
WHERE name ILIKE '%João%';  -- Substituir pelo nome
```

### Ver Estatísticas do Ranking

```sql
SELECT 
  COUNT(*) as total_users,
  MAX(xp) as max_xp,
  AVG(xp) as avg_xp,
  MIN(xp) as min_xp,
  MAX(streak) as max_streak
FROM public.leaderboard;
```

---

**Última atualização:** 2026-02-24  
**Status:** Correção pronta para aplicar ✅
