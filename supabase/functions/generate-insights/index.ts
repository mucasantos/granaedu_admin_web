import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!

interface Transaction {
  amount: number
  type: string
  category: string
  date: string
}

interface RequestBody {
  user_id: string
  transactions: Transaction[]
}

serve(async (req) => {
  // CORS headers
  if (req.method === 'OPTIONS') {
    return new Response('ok', { 
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      }
    })
  }

  try {
    // 1. Autenticar usuário
    const authHeader = req.headers.get('Authorization')
    console.log(`[Insights] Auth header present: ${!!authHeader}`)
    
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'unauthorized', message: 'Authorization header required' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {},
      auth: { persistSession: false }
    })

    const accessToken = authHeader.replace(/^Bearer\s+/i, '').trim()
    console.log(`[Insights] Calling getUser(accessToken) ... token len=${accessToken.length}`)
    const { data: { user }, error: authError } = await supabase.auth.getUser(accessToken)
    if (authError || !user) {
      console.error(`[Insights] Auth error: ${authError?.message}`)
      return new Response(
        JSON.stringify({ error: 'unauthorized', message: 'Invalid token' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[Insights] Authenticated user: ${user.id}, is_anonymous: ${user.is_anonymous}`)

    // 2. Processar requisição
    const { user_id, transactions }: RequestBody = await req.json()
    
    console.log(`[Insights] Generating for user ${user_id}, ${transactions?.length || 0} transactions`)
    
    if (!transactions || transactions.length === 0) {
      return new Response(
        JSON.stringify({ 
          error: 'Nenhuma transação encontrada. Adicione transações para gerar insights.' 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    // 1. Calcular totais
    const totalIncome = transactions
      .filter(t => t.type.toLowerCase().includes('income'))
      .reduce((sum, t) => sum + t.amount, 0)
      
    const totalExpenses = transactions
      .filter(t => t.type.toLowerCase().includes('expense'))
      .reduce((sum, t) => sum + t.amount, 0)
    
    const balance = totalIncome - totalExpenses
    
    // 2. Agrupar por categoria
    const byCategory: Record<string, number> = {}
    transactions.forEach(t => {
      const cat = t.category || 'Sem categoria'
      if (!byCategory[cat]) {
        byCategory[cat] = 0
      }
      if (t.type.toLowerCase().includes('expense')) {
        byCategory[cat] += t.amount
      }
    })
    
    // Ordenar categorias por valor
    const topCategories = Object.entries(byCategory)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)
    
    // 3. Calcular médias
    const avgDaily = totalExpenses / 30
    const daysWithTransactions = new Set(transactions.map(t => t.date.split('T')[0])).size
    
    // 4. Criar prompt OTIMIZADO (mais curto = mais rápido)
    const prompt = `Assistente financeiro. Analise e retorne JSON.

DADOS (30 dias):
Receitas: R$ ${totalIncome.toFixed(2)}
Gastos: R$ ${totalExpenses.toFixed(2)}
Saldo: R$ ${balance.toFixed(2)}
Transacoes: ${transactions.length}
Media diaria: R$ ${avgDaily.toFixed(2)}

Top Categorias:
${topCategories.slice(0, 3).map(([cat, value]) => `${cat}: R$ ${value.toFixed(2)}`).join(', ')}

FORMATO:
{"summary":"texto breve","prediction":"previsao mes","recommendations":["dica 1","dica 2"],"alerts":[],"trend":"stable"}

REGRAS:
- trend: increasing/decreasing/stable
- Se gastos > receitas: adicione alerta
- JSON puro, sem markdown
- Maximo 500 caracteres no summary

RETORNE O JSON:`

    console.log('[Insights] Calling Gemini API...')
    const startTime = Date.now()

    // 5. Descobrir modelo disponível (EXATAMENTE como transcribe-audio)
    const listModelsUrl = `https://generativelanguage.googleapis.com/v1/models?key=${GEMINI_API_KEY}`
    const listResponse = await fetch(listModelsUrl)
    const listData = await listResponse.json()
    
    console.log('[Insights] Available models:', JSON.stringify(listData.models?.map((m: any) => m.name).slice(0, 10)))
    
    // Procurar um modelo que suporte generateContent
    const availableModel = listData.models?.find((m: any) => 
      m.supportedGenerationMethods?.includes('generateContent') &&
      (m.name.includes('gemini') || m.name.includes('flash') || m.name.includes('pro'))
    )
    
    const modelToUse = availableModel?.name || 'models/gemini-2.5-flash'
    console.log('[Insights] Using model:', modelToUse)

    // 6. Chamar Gemini com modelo correto
    const geminiUrl = `https://generativelanguage.googleapis.com/v1/${modelToUse}:generateContent?key=${GEMINI_API_KEY}`
    
    console.log('[Insights] Request prompt length:', prompt.length, 'chars')
    
    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [{ text: prompt }]
        }],
        generationConfig: {
          temperature: 0.5,
          topK: 20,
          topP: 0.9,
          maxOutputTokens: 4096,  // Mais espaço para evitar MAX_TOKENS
          responseMimeType: 'application/json'  // Força resposta em JSON
        }
      })
    })

    const latency = Date.now() - startTime
    console.log(`[Insights] Gemini response received (${latency}ms), status: ${geminiResponse.status}`)

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text()
      console.error('[Insights] Gemini API error:', errorText)
      throw new Error(`Gemini API error: ${errorText.substring(0, 200)}`)
    }

    const geminiData = await geminiResponse.json()
    
    // Log seguro (evitar stack overflow em objetos grandes)
    try {
      const safeLog = JSON.stringify(geminiData).substring(0, 1000)
      console.log('[Insights] Gemini response (first 1000 chars):', safeLog)
    } catch (e) {
      console.log('[Insights] Could not stringify response (too large)')
    }
    
    // Verificar por que resposta está vazia
    if (!geminiData.candidates || geminiData.candidates.length === 0) {
      console.error('[Insights] No candidates in response')
      console.error('[Insights] Prompt feedback:', JSON.stringify(geminiData.promptFeedback || {}))
      throw new Error('Gemini returned no candidates. Check promptFeedback in logs.')
    }
    
    const candidate = geminiData.candidates[0]
    console.log('[Insights] Candidate finishReason:', candidate.finishReason)
    console.log('[Insights] Candidate safetyRatings:', JSON.stringify(candidate.safetyRatings || []))

    // Retry uma vez se estourar tokens: usar prompt mínimo
    if (candidate.finishReason === 'MAX_TOKENS') {
      console.warn('[Insights] MAX_TOKENS detected. Retrying with minimal prompt and tighter config...')
      const minimalPrompt = 'Retorne apenas JSON com {"summary":"...","prediction":"...","recommendations":["..."],"alerts":[],"trend":"stable"}. Sem markdown.'
      const retryResponse = await fetch(geminiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: minimalPrompt }] }],
          generationConfig: {
            temperature: 0.3,
            topK: 10,
            topP: 0.9,
            maxOutputTokens: 1024,
            responseMimeType: 'application/json'
          }
        })
      })

      console.log('[Insights] Retry status:', retryResponse.status)
      if (retryResponse.ok) {
        const retryData = await retryResponse.json()
        console.log('[Insights] Retry candidates:', JSON.stringify(retryData.candidates?.length || 0))
        const retryText = retryData.candidates?.[0]?.content?.parts?.[0]?.text || ''
        if (retryText) {
          // Continuar fluxo com retryText
          let jsonText = retryText.trim()
          if (jsonText.startsWith('```json')) {
            jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?/g, '')
          } else if (jsonText.startsWith('```')) {
            jsonText = jsonText.replace(/```\n?/g, '')
          }
          try {
            const insights = JSON.parse(jsonText)
            // seguir com pós-processamento existente abaixo, reutilizando variável insights
            // 7. Garantir campos obrigatórios
            insights.summary = insights.summary || 'Resumo indisponível no momento.'
            insights.prediction = insights.prediction || 'Sem previsão no momento.'
            insights.trend = insights.trend || 'stable'
            const validTrends = ['increasing', 'decreasing', 'stable']
            if (!validTrends.includes(insights.trend)) insights.trend = 'stable'
            insights.recommendations = insights.recommendations || []
            insights.alerts = insights.alerts || []
            const dates = transactions.map(t => new Date(t.date))
            const periodStart = new Date(Math.min(...dates.map(d => d.getTime())))
            const periodEnd = new Date(Math.max(...dates.map(d => d.getTime())))
            const response = {
              ...insights,
              total_income: totalIncome,
              total_expenses: totalExpenses,
              period_start: periodStart.toISOString().split('T')[0],
              period_end: periodEnd.toISOString().split('T')[0],
              transactions_count: transactions.length,
            }
            console.log('[Insights] ✅ Success after retry!')
            return new Response(JSON.stringify(response), { headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' } })
          } catch (e) {
            console.error('[Insights] Retry JSON parse failed:', e)
          }
        }
      }
    }
    
    const aiText = candidate?.content?.parts?.[0]?.text || ''
    console.log('[Insights] Extracted text length:', aiText.length)
    
    if (!aiText) {
      console.error('[Insights] Empty text from Gemini')
      console.error('[Insights] Finish reason:', candidate.finishReason)
      
      if (candidate.finishReason === 'SAFETY') {
        throw new Error('Gemini blocked response due to SAFETY. Try simplifying prompt.')
      } else if (candidate.finishReason === 'RECITATION') {
        throw new Error('Gemini blocked response due to RECITATION.')
      } else {
        throw new Error(`AI returned empty response. Finish reason: ${candidate.finishReason}`)
      }
    }
    
    console.log('[Insights] Raw response (first 300 chars):', aiText.substring(0, 300))
    
    // 6. Parse JSON (mesma lógica robusta do transcribe-audio)
    let jsonText = aiText.trim()
    
    // Remover markdown code blocks (múltiplas variações)
    if (jsonText.startsWith('```json')) {
      jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?/g, '')
    } else if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```\n?/g, '')
    }
    
    jsonText = jsonText.trim()
    
    // Tentar encontrar JSON mesmo se houver texto antes/depois
    const jsonMatch = jsonText.match(/\{[\s\S]*\}/)
    if (!jsonMatch) {
      console.error('[Insights] No JSON found in response:', jsonText.substring(0, 500))
      throw new Error('No valid JSON found in Gemini response')
    }
    
    let insights
    try {
      insights = JSON.parse(jsonMatch[0])
    } catch (parseError) {
      console.error('[Insights] JSON parse error:', parseError)
      console.error('[Insights] Attempted to parse:', jsonMatch[0].substring(0, 500))
      throw new Error(`Failed to parse JSON: ${parseError}`)
    }
    
    // 7. Validar campos obrigatórios
    if (!insights.summary || !insights.trend) {
      throw new Error('Missing required fields in insights')
    }
    
    // 8. Garantir que trend seja válido
    const validTrends = ['increasing', 'decreasing', 'stable']
    if (!validTrends.includes(insights.trend)) {
      insights.trend = 'stable'
    }
    
    // 9. Garantir arrays
    insights.recommendations = insights.recommendations || []
    insights.alerts = insights.alerts || []
    
    // 10. Calcular datas do período
    const dates = transactions.map(t => new Date(t.date))
    const periodStart = new Date(Math.min(...dates.map(d => d.getTime())))
    const periodEnd = new Date(Math.max(...dates.map(d => d.getTime())))
    
    // 11. Adicionar metadata
    const response = {
      ...insights,
      total_income: totalIncome,
      total_expenses: totalExpenses,
      period_start: periodStart.toISOString().split('T')[0],
      period_end: periodEnd.toISOString().split('T')[0],
      transactions_count: transactions.length,
    }
    
    console.log('[Insights] ✅ Success! Generated insights')
    
    return new Response(
      JSON.stringify(response),
      { 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        } 
      }
    )
    
  } catch (error) {
    console.error('[Insights] Error:', error)
    return new Response(
      JSON.stringify({ 
        error: error.message || 'Erro ao gerar insights',
        details: error.toString()
      }),
      { 
        status: 500, 
        headers: { 
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        } 
      }
    )
  }
})
