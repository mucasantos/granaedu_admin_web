
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { GoogleGenerativeAI } from "https://esm.sh/@google/generative-ai"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { studentId } = await req.json()
    const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!GEMINI_API_KEY) {
      throw new Error('Missing GEMINI_API_KEY')
    }

    // Create Supabase client
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!)

    // Fetch student profile
    const { data: profile, error: fetchError } = await supabase
      .from('users_profile')
      .select('*')
      .eq('id', studentId)
      .single()

    if (fetchError || !profile) {
      throw new Error('Student profile not found')
    }

    // Generate content using Gemini
    const genAI = new GoogleGenerativeAI(GEMINI_API_KEY)
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" })

    const prompt = `You are a supportive English teacher evaluating a high school student's writing. 
      Analyze the following text from their profile survey.
      
      Student Text: "${profile.open_ended_response || 'No text provided'}"
      
      Other Checkbox Data:
      - Self Assessed Level: ${profile.self_assessed_level}
      - Listening Comprehension: ${profile.listening_comprehension}
      - Uses Internet in English: ${profile.uses_internet_in_english}
      
      Based on this:
      1. Estimate their CEFR level (A1, A2, B1, B2, C1, C2). If text is too short, rely partly on self-assessment but be conservative.
      2. Provide a very brief (1-2 sentences), encouraging feedback directly to the student. Highlight what they did well and one small thing to improve.
      
      CRITICAL: Return ONLY a JSON object with this structure:
      {
        "level": "A1/A2/B1/...",
        "feedback": "Your feedback here..."
      }`

    const result = await model.generateContent(prompt)
    const response = await result.response;
    const text = response.text();
    
    // Extract JSON from response (remove markdown code blocks if present)
    const jsonStr = text.replace(/```json/g, '').replace(/```/g, '').trim();
    const aiData = JSON.parse(jsonStr);

    let mappedLevel = 'A1';
    const levelStr = (aiData.level || '').toUpperCase();
    if (levelStr.includes('A2')) mappedLevel = 'A2';
    else if (levelStr.includes('B1')) mappedLevel = 'B1';
    else if (levelStr.includes('B2')) mappedLevel = 'B2';
    else if (levelStr.includes('C1')) mappedLevel = 'C1';
    else if (levelStr.includes('C2')) mappedLevel = 'C2';
    
    // Update student profile
    const { error: updateError } = await supabase
      .from('users_profile')
      .update({
        ai_estimated_level: mappedLevel,
        ai_feedback: aiData.feedback,
        // using raw SQL for current timestamp if needed, but easy to just pass string
        // submitted_at update is not strictly needed, but let's keep it as is
      })
      .eq('id', studentId)

    if (updateError) {
      throw updateError
    }

    return new Response(
      JSON.stringify({ success: true, level: mappedLevel, feedback: aiData.feedback }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
