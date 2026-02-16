/**
 * Edge Function: transcribe-audio
 * 
 * Transcreve áudio usando Google Gemini e extrai transações financeiras
 * 
 * Endpoint: https://[project-ref].supabase.co/functions/v1/transcribe-audio
 * 
 * Uso:
 * POST /transcribe-audio
 * Headers: Authorization: Bearer [supabase-anon-key]
 * Body: multipart/form-data com campo 'audio'
 */

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'
// Não usar biblioteca desatualizada - usar REST API direta

// Tipos
interface Transaction {
  type: 'income' | 'expenses'
  amount: number
  currency: string
  categoryIdentifier: string
  note: string
  date: string
  noImpactOnBalance: boolean
}

interface TranscriptionResponse {
  transcript: string
  transactions: Transaction[]
  confidence: number
  keywords: string[]
  needsConfirmation: boolean
  suggestions: string[]
}

// Configurações
const GEMINI_MODEL = "gemini-2.5-flash" //'gemini-1.5-flash-latest' 
const MAX_AUDIO_SIZE = 10 * 1024 * 1024 // 10MB
const MAX_AUDIO_DURATION = 120 // 2 minutos

// Prompt para extração de transações
const EXTRACTION_PROMPT = `
Você é um assistente financeiro especializado em português brasileiro.

TAREFA: Transcreva este áudio e extraia todas as transações financeiras mencionadas.

REGRAS:
1. Transcreva o áudio com precisão
2. Identifique receitas (income) e despesas (expenses)
3. Extraia: valor, categoria, descrição, data (se mencionada)
4. Se a data não for mencionada, use a data atual COM O ANO ATUAL
5. Para datas relativas ("hoje", "ontem", "anteontem", "semana passada"), converta para ISO 8601
6. Se o usuário não disser o ANO explicitamente, SEMPRE utilize o ANO ATUAL
7. Use timezone -03:00 no campo "date". Exemplo: 2025-10-21T12:30:00-03:00

CATEGORIAS VÁLIDAS:
DESPESAS: groceries, restaurants, transport, shopping, health, education, entertainment, bills, other_expense
RECEITAS: salary, freelance, investment, gift, refund, other_income

FORMATO DE RESPOSTA (JSON válido):
{
  "transcript": "texto transcrito completo",
  "transactions": [
    {
      "type": "expenses",
      "amount": 85.50,
      "currency": "BRL",
      "categoryIdentifier": "restaurants",
      "note": "almoço no restaurante",
      "date": "2025-10-21T12:30:00-03:00",
      "noImpactOnBalance": false
    }
  ],
  "confidence": 0.95,
  "keywords": ["restaurante", "almoço", "85"],
  "needsConfirmation": false,
  "suggestions": []
}

IMPORTANTE: 
- Sempre retorne JSON válido
- Se não entender o áudio, retorne transactions vazio mas com transcript
- confidence: 0-1 (quão confiante está da extração)
- needsConfirmation: true se houver ambiguidade
- suggestions: array de strings com sugestões se algo não estiver claro

EXEMPLOS:
"paguei 85 reais no restaurante ontem" → 
  {type: "expenses", amount: 85, category: "restaurants", date: "ontem"}

"recebi 5 mil de salário hoje" → 
  {type: "income", amount: 5000, category: "salary", date: "hoje"}

Agora transcreva e extraia o áudio:
`.trim()

// Função principal
serve(async (req) => {
  try {
    // 1. Verificar método
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'method_not_allowed', message: 'Use POST method' }),
        { status: 405, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 2. Autenticar usuário via Supabase
    const authHeader = req.headers.get('Authorization')
    const apikeyHeader = req.headers.get('apikey')
    console.log(`[transcribe-audio] Auth header: ${authHeader ? authHeader.substring(0, 20) + '...' : 'MISSING'}`)
    console.log(`[transcribe-audio] ApiKey header: ${apikeyHeader ? apikeyHeader.substring(0, 20) + '...' : 'MISSING'}`)
    
    if (!authHeader) {
      console.error('[transcribe-audio] No Authorization header provided')
      return new Response(
        JSON.stringify({ error: 'unauthorized', message: 'Authorization header required' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!
    
    console.log(`[transcribe-audio] Creating Supabase client for auth validation...`)
    
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      // We'll pass the token explicitly to getUser below
      global: {},
      auth: { persistSession: false }
    })

    // Extract raw token from Bearer header and validate explicitly
    const accessToken = authHeader.replace(/^Bearer\s+/i, '').trim()
    console.log(`[transcribe-audio] Calling getUser(accessToken) ... token len=${accessToken.length}`)
    const { data: { user }, error: authError } = await supabase.auth.getUser(accessToken)
    
    if (authError || !user) {
      console.error(`[transcribe-audio] Auth validation failed`)
      console.error(`[transcribe-audio] Error: ${authError?.message}`)
      console.error(`[transcribe-audio] Error details: ${JSON.stringify(authError)}`)
      return new Response(
        JSON.stringify({ 
          error: 'unauthorized', 
          message: 'Invalid token',
          details: authError?.message 
        }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[transcribe-audio] ✅ Authenticated: ${user.id}, anonymous: ${user.is_anonymous}`)

    // 4. Extrair áudio do multipart
    const contentType = req.headers.get('content-type') || ''
    if (!contentType.includes('multipart/form-data')) {
      return new Response(
        JSON.stringify({ error: 'invalid_content_type', message: 'Use multipart/form-data' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const formData = await req.formData()
    const audioFile = formData.get('audio') as File
    
    if (!audioFile) {
      return new Response(
        JSON.stringify({ error: 'file_required', message: 'Audio file is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 5. Validar tamanho do áudio
    if (audioFile.size > MAX_AUDIO_SIZE) {
      return new Response(
        JSON.stringify({ 
          error: 'audio_too_large', 
          message: `Max size: ${MAX_AUDIO_SIZE / 1024 / 1024}MB` 
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[transcribe-audio] Processing audio: ${audioFile.name}, size: ${audioFile.size} bytes`)

    // 6. Converter áudio para base64 (em chunks para evitar stack overflow)
    const audioBuffer = await audioFile.arrayBuffer()
    const bytes = new Uint8Array(audioBuffer)
    let binary = ''
    const chunkSize = 0x8000 // ~32KB
    for (let i = 0; i < bytes.length; i += chunkSize) {
      const sub = bytes.subarray(i, Math.min(i + chunkSize, bytes.length))
      binary += String.fromCharCode(...sub)
    }
    const audioBase64 = btoa(binary)

    // 7. Determinar MIME type
    let mimeType = audioFile.type
    if (!mimeType || mimeType === 'application/octet-stream') {
      // Inferir do nome do arquivo
      const ext = audioFile.name.split('.').pop()?.toLowerCase()
      const mimeMap: Record<string, string> = {
        'mp3': 'audio/mp3',
        'm4a': 'audio/mp4',
        'wav': 'audio/wav',
        'ogg': 'audio/ogg',
        'aac': 'audio/aac',
      }
      mimeType = mimeMap[ext || ''] || 'audio/mp3'
    }

    console.log(`[transcribe-audio] MIME type: ${mimeType}`)

    // 8. Chamar Gemini API via REST (mais confiável que a biblioteca)
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) {
      console.error('[transcribe-audio] GEMINI_API_KEY not configured')
      return new Response(
        JSON.stringify({ error: 'service_unavailable', message: 'AI service not configured' }),
        { status: 503, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log('[transcribe-audio] Calling Gemini API (REST)...')
    const startTime = Date.now()

    // Primeiro, listar modelos disponíveis
    const listModelsUrl = `https://generativelanguage.googleapis.com/v1/models?key=${geminiApiKey}`
    const listResponse = await fetch(listModelsUrl)
    const listData = await listResponse.json()
    
    console.log('[transcribe-audio] Available models:', JSON.stringify(listData.models?.map((m: any) => m.name).slice(0, 10)))
    
    // Procurar um modelo que suporte generateContent e multimodal
    const availableModel = listData.models?.find((m: any) => 
      m.supportedGenerationMethods?.includes('generateContent') &&
      (m.name.includes('gemini') || m.name.includes('flash') || m.name.includes('pro'))
    )
    
    const modelToUse = availableModel?.name || `models/${GEMINI_MODEL}`
    console.log('[transcribe-audio] Using model:', modelToUse)

    // Usar modelo disponível
    const geminiUrl = `https://generativelanguage.googleapis.com/v1/${modelToUse}:generateContent?key=${geminiApiKey}`
    
    const geminiResponse = await fetch(geminiUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{
          parts: [
            { text: EXTRACTION_PROMPT },
            {
              inline_data: {
                mime_type: mimeType,
                data: audioBase64
              }
            }
          ]
        }]
      })
    })

    const latency = Date.now() - startTime
    console.log(`[transcribe-audio] Gemini response received (${latency}ms), status: ${geminiResponse.status}`)

    if (!geminiResponse.ok) {
      const errorText = await geminiResponse.text()
      console.error('[transcribe-audio] Gemini API error:', errorText)
      return new Response(
        JSON.stringify({ 
          error: 'internal_error', 
          message: `Gemini API error: ${errorText.substring(0, 200)}`
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const geminiData = await geminiResponse.json()
    const responseText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text || ''
    
    if (!responseText) {
      console.error('[transcribe-audio] Empty response from Gemini')
      return new Response(
        JSON.stringify({ error: 'empty_response', message: 'AI returned empty response' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log('[transcribe-audio] Raw response:', responseText.substring(0, 200))

    // 9. Parse JSON (remover markdown se necessário)
    let jsonText = responseText.trim()
    if (jsonText.startsWith('```json')) {
      jsonText = jsonText.replace(/```json\n?/g, '').replace(/```\n?/g, '')
    } else if (jsonText.startsWith('```')) {
      jsonText = jsonText.replace(/```\n?/g, '')
    }

    let parsed: TranscriptionResponse
    try {
      parsed = JSON.parse(jsonText)
    } catch (parseError) {
      console.error('[transcribe-audio] Failed to parse JSON:', parseError)
      console.error('[transcribe-audio] Response text:', jsonText)
      return new Response(
        JSON.stringify({ 
          error: 'invalid_response', 
          message: 'AI returned invalid format',
          details: { responseText: jsonText.substring(0, 500) }
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 10. Validar estrutura da resposta
    if (!parsed.transcript || !Array.isArray(parsed.transactions)) {
      console.error('[transcribe-audio] Invalid response structure')
      return new Response(
        JSON.stringify({ 
          error: 'invalid_response', 
          message: 'Missing required fields',
          details: {
            hasTranscript: !!parsed.transcript,
            transactionsIsArray: Array.isArray(parsed.transactions)
          }
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // 11. Normalizar datas das transações (ano atual e timezone -03:00)
    // Base de tempo ajustada para -03:00 para evitar troca de dia
    const timezoneOffsetMinutes = -3 * 60
    const offsetMs = timezoneOffsetMinutes * 60 * 1000
    const nowUTC = new Date()
    const now = nowUTC
    const nowLocal = new Date(now.getTime() + offsetMs)
    const nowYear = nowLocal.getUTCFullYear()
    const pad2 = (n: number) => String(n).padStart(2, '0')
    const toIsoWithTimezone = (d: Date) => {
      const local = new Date(d.getTime() + offsetMs)
      const y = local.getUTCFullYear()
      const m = pad2(local.getUTCMonth() + 1)
      const day = pad2(local.getUTCDate())
      const hours = pad2(local.getUTCHours())
      const minutes = pad2(local.getUTCMinutes())
      const seconds = pad2(local.getUTCSeconds())
      const sign = timezoneOffsetMinutes <= 0 ? '-' : '+'
      const absOffset = Math.abs(timezoneOffsetMinutes)
      const offsetHours = pad2(Math.floor(absOffset / 60))
      const offsetMinutes = pad2(absOffset % 60)
      return `${y}-${m}-${day}T${hours}:${minutes}:${seconds}${sign}${offsetHours}:${offsetMinutes}`
    }
    try {
      const transcript = String(parsed.transcript || '').toLowerCase()
      const transcriptYears = Array.from(transcript.match(/\b20\d{2}\b/g) ?? []).map(Number)
      const mentionsTwoYearsAgo =
        transcript.includes('ano retrasado') ||
        transcript.includes('há dois anos') ||
        transcript.includes('ha dois anos')
      const mentionsLastYear = transcript.includes('ano passado')
      const mentionsNextYear =
        transcript.includes('ano que vem') ||
        transcript.includes('ano seguinte') ||
        transcript.includes('próximo ano') ||
        transcript.includes('proximo ano')
      const hasHoje = transcript.includes('hoje')
      const hasOntem = transcript.includes('ontem')
      const hasAnteontem = transcript.includes('anteontem')
      const hasSemanaPassada = transcript.includes('semana passada')
      const hasAmanha = transcript.includes('amanhã') || transcript.includes('amanha')
      const hasProximaSemana =
        transcript.includes('próxima semana') || transcript.includes('proxima semana')
      const mentionsRelative =
        hasHoje ||
        hasOntem ||
        hasAnteontem ||
        hasSemanaPassada ||
        hasAmanha ||
        hasProximaSemana
      const monthAlternatives =
        '(jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez|janeiro|fevereiro|março|marco|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro|' +
        'january|february|march|april|may|june|july|august|september|october|november|december)'
      const explicitDatePatterns = [
        /\b\d{1,2}[\/\-]\d{1,2}(?:[\/\-]\d{2,4})?\b/,
        /\b\d{4}-\d{2}-\d{2}\b/,
        new RegExp(`\b\d{1,2}\s+de\s+${monthAlternatives}\b`, 'i'),
        new RegExp(`\b${monthAlternatives}\s+\d{1,2}\b`, 'i'),
        /\bdia\s+\d{1,2}\b/
      ]
      const mentionsExplicitDate = explicitDatePatterns.some(regex => regex.test(transcript))
      const pickClosestYear = (target: number, years: number[]) =>
        years.reduce((closest, year) =>
          Math.abs(year - target) < Math.abs(closest - target) ? year : closest,
        years[0])
      const resolveYear = (candidateYear: number) => {
        if (transcriptYears.includes(candidateYear)) {
          return candidateYear
        }
        if (transcriptYears.length > 0) {
          return pickClosestYear(candidateYear, transcriptYears)
        }
        if (mentionsTwoYearsAgo) {
          return nowYear - 2
        }
        if (mentionsLastYear) {
          return nowYear - 1
        }
        if (mentionsNextYear) {
          return nowYear + 1
        }
        return nowYear
      }
      parsed.transactions = (parsed.transactions || []).map((t: any) => {
        try {
          let d = new Date(t.date)
          if (isNaN(d.getTime())) d = now
          // Heurística baseada no transcript: relative dates em PT-BR
          if (hasHoje) {
            d = new Date(now)
          } else if (hasOntem) {
            d = new Date(now.getTime() - 1 * 24 * 60 * 60 * 1000)
          } else if (hasAnteontem) {
            d = new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000)
          } else if (hasSemanaPassada) {
            d = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000)
          } else if (hasAmanha) {
            d = new Date(now.getTime() + 1 * 24 * 60 * 60 * 1000)
          } else if (hasProximaSemana) {
            d = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000)
          }
          // Clamp futuro: se mais de +1 dia no futuro, usar hoje
          const msPerDay = 24 * 60 * 60 * 1000
          const dayDiff = (d.getTime() - now.getTime()) / msPerDay
          if (dayDiff > 1) {
            d = new Date(now)
          }
          const resolvedYear = resolveYear(d.getFullYear())
          if (resolvedYear !== d.getFullYear()) {
            d.setFullYear(resolvedYear)
          }
          const absDayDiff = Math.abs((d.getTime() - now.getTime()) / msPerDay)
          if (!mentionsExplicitDate && !mentionsRelative && absDayDiff > 1) {
            d = new Date(now)
          }
          return { ...t, date: toIsoWithTimezone(d) }
        } catch {
          return { ...t, date: toIsoWithTimezone(now) }
        }
      })
    } catch (e) {
      console.warn('[transcribe-audio] Date normalization failed, continuing raw:', e)
    }

    // 12. Retornar resposta
    console.log(`[transcribe-audio] Success: ${parsed.transactions.length} transactions extracted`)

    return new Response(
      JSON.stringify({
        ...parsed,
        metadata: {
          model: modelToUse,
          latency,
          audioSize: audioFile.size,
          userId: 'anonymous' // Temporário - auth desabilitada
        }
      }),
      { 
        status: 200, 
        headers: { 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('[transcribe-audio] Error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'internal_error', 
        message: error instanceof Error ? error.message : 'Unknown error' 
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
