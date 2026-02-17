// Supabase Edge Function: speaking-analyzer
// Purpose: Analyze user speech for grammar, fluency, vocabulary, pronunciation, and clarity using Gemini Multimodal.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const MAX_AUDIO_SIZE = 10 * 1024 * 1024; // 10MB

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('[speaking-analyzer] Request received');

    // 1. Validate Method & Content Type
    if (req.method !== 'POST') {
      return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405, headers: corsHeaders });
    }

    const contentType = req.headers.get('content-type') || '';
    if (!contentType.includes('multipart/form-data')) {
      return new Response(JSON.stringify({ error: 'Content-Type must be multipart/form-data' }), { status: 400, headers: corsHeaders });
    }

    // 2. Authenticate User
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Missing Authorization header' }), { status: 401, headers: corsHeaders });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY');
    
    if (!supabaseUrl || !supabaseAnonKey) {
        throw new Error("Missing Supabase configuration");
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, { auth: { persistSession: false } });

    // Try to get user if authenticated, but don't require it
    let userId = 'anonymous';
    try {
      const accessToken = authHeader.replace(/^Bearer\s+/i, '').trim();
      const { data: { user } } = await supabase.auth.getUser(accessToken);
      if (user) {
        userId = user.id;
        console.log(`[speaking-analyzer] User authenticated: ${userId}`);
      } else {
        console.log('[speaking-analyzer] No user authenticated, using anonymous mode');
      }
    } catch (authError) {
      console.log('[speaking-analyzer] Auth check failed, using anonymous mode:', authError);
    }

    // 3. Extract Data
    const formData = await req.formData();
    const audioFile = formData.get('audio') as File;
    const userLevel = formData.get('level') as string || 'A1';
    const topic = formData.get('topic') as string || 'General';
    const durationStr = formData.get('duration') as string || '0'; // Duration in seconds if available

    if (!audioFile) {
        return new Response(JSON.stringify({ error: 'Audio file is required' }), { status: 400, headers: corsHeaders });
    }

    console.log(`[speaking-analyzer] Processing audio: ${audioFile.name}, Size: ${audioFile.size}, Level: ${userLevel}, Topic: ${topic}`);

    if (audioFile.size > MAX_AUDIO_SIZE) {
        return new Response(JSON.stringify({ error: 'Audio file too large (Max 10MB)' }), { status: 400, headers: corsHeaders });
    }

    // 4. Prepare Gemini Call
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiApiKey) {
        throw new Error("GEMINI_API_KEY is not configured");
    }

    // Convert audio to Base64
    const audioBuffer = await audioFile.arrayBuffer();
    const audioBytes = new Uint8Array(audioBuffer);
    const audioBase64 = btoa(String.fromCharCode(...audioBytes));
    
    // Determine MIME type
    let mimeType = audioFile.type || 'audio/mp3'; // Default fallback
    // Simple mime check if missing
    if (!mimeType || mimeType === 'application/octet-stream') {
         if (audioFile.name.endsWith('.wav')) mimeType = 'audio/wav';
         else if (audioFile.name.endsWith('.m4a')) mimeType = 'audio/m4a';
         else if (audioFile.name.endsWith('.mp3')) mimeType = 'audio/mp3';
         else if (audioFile.name.endsWith('.ogg')) mimeType = 'audio/ogg';
         else if (audioFile.name.endsWith('.aac')) mimeType = 'audio/aac';
    }

    const MODEL_NAME = 'gemini-2.0-flash'; // Or gemini-1.5-flash
    const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent?key=${geminiApiKey}`;

    // Prompt optimized for speaking analysis
    const PROMPT = `
    You are an expert English Language Examiner. 
    Analyze the attached student audio. The student is at level ${userLevel} and speaking about "${topic}".

    Task:
    1. Transcribe the audio accurately.
    2. Analyze the speech for:
       - Grammar (accuracy and complexity)
       - Fluency (speed, pauses, hesitation)
       - Vocabulary (range and appropriateness)
       - Pronunciation (clarity and accent)
       - Clarity (overall coherence)
    3. Provide constructive feedback and a corrected version of the spoken text.
    4. Estimate WPM (Words Per Minute) based on the audio length (approx ${durationStr}s).

    Return JSON ONLY:
    {
      "transcript": "...",
      "wpm": number,
      "scores": {
        "grammar": 0-100,
        "fluency": 0-100,
        "vocabulary": 0-100,
        "pronunciation": 0-100,
        "clarity": 0-100,
        "overall": 0-100
      },
      "feedback": {
        "strengths": ["point 1", "point 2"],
        "weaknesses": ["point 1", "point 2"],
        "main_error": "Primary issue to focus on",
        "tip": "Actionable tip for improvement"
      },
      "corrected_sentence": "Better version of what they said",
      "next_exercise": "Suggestion for what to practice next"
    }
    `;

    console.log('[speaking-analyzer] Calling Gemini...');

    const geminiResponse = await fetch(GEMINI_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            contents: [{
                parts: [
                    { text: PROMPT },
                    {
                        inline_data: {
                            mime_type: mimeType,
                            data: audioBase64
                        }
                    }
                ]
            }],
            generation_config: {
                response_mime_type: "application/json"
            }
        })
    });

    if (!geminiResponse.ok) {
        const errText = await geminiResponse.text();
        console.error('[speaking-analyzer] Gemini Error:', errText);
        throw new Error(`Gemini API Error: ${errText}`);
    }

    const geminiResult = await geminiResponse.json();
    const aiText = geminiResult.candidates?.[0]?.content?.parts?.[0]?.text;

    if (!aiText) {
        throw new Error("Empty response from Gemini");
    }

    // 5. Parse and Return
    let resultJson;
    try {
        resultJson = JSON.parse(aiText);
    } catch (e) {
        console.error('[speaking-analyzer] JSON Parse Error:', e);
        // Fallback or cleanup
        resultJson = { error: "Failed to parse AI response", raw: aiText };
    }

    // 5. Upload Audio to Storage
    const timestamp = new Date().getTime();
    const fileName = `${user.id}/${timestamp}.mp3`; // Organize by user

    const { error: uploadError } = await supabase.storage
      .from('speaking-audio')
      .upload(fileName, audioFile, {
        contentType: mimeType,
        upsert: false
      });

    if (uploadError) {
      console.error('[speaking-analyzer] Storage Upload Error:', uploadError);
      // Continue but warn? Or fail? Let's log and continue, maybe save without audio URL if critical?
      // Better to fail or save what we have. Let's try to proceed.
    }

    // Get Public URL (or Signed URL if private)
    // Assuming 'speaking-audio' is public for now based on migration
    const { data: { publicUrl } } = supabase.storage
      .from('speaking-audio')
      .getPublicUrl(fileName);

    // 6. Save Submission to Database
    let submissionId = null;
    const { data: submissionData, error: dbError } = await supabase
      .from('speaking_submissions')
      .insert({
        user_id: user.id,
        audio_url: publicUrl,
        transcript: resultJson.transcript || '',
        analysis_json: resultJson,
        // task_id: ??? We don't have task_id in the request yet. 
        // We should probably add it to the form data in the future.
        // For now, it's nullable.
      })
      .select('id')
      .single();

    if (dbError) {
      console.error('[speaking-analyzer] DB Insert Error:', dbError);
    } else {
      submissionId = submissionData?.id;
    }

    console.log('[speaking-analyzer] Analysis complete. Submission ID:', submissionId);

    return new Response(JSON.stringify({ ...resultJson, submission_id: submissionId }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error) {
    console.error('[speaking-analyzer] Internal Error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal Server Error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
