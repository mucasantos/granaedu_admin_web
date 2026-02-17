// Supabase Edge Function: text-to-speech
// Purpose: Proxy requests to ElevenLabs API to hide API Key

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { text, voice_id } = await req.json()

    if (!text) {
      throw new Error('Text is required')
    }

    // Default voice: "Rachel" (American, calm) - adjust as needed
    // You can also accept voice_id from client
    const voiceId = voice_id || '21m00Tcm4TlvDq8ikWAM'; 
    const apiKey = Deno.env.get('ELEVEN_LABS_API_KEY');

    if (!apiKey) {
      throw new Error('ELEVEN_LABS_API_KEY not configured');
    }

    // Call ElevenLabs API
    const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'xi-api-key': apiKey,
        },
        body: JSON.stringify({
          text: text,
          model_id: "eleven_monolingual_v1", // or eleven_multilingual_v2
          voice_settings: {
            stability: 0.5,
            similarity_boost: 0.75,
          }
        }),
      }
    );

    if (!response.ok) {
        const err = await response.text();
        console.error("ElevenLabs Error:", err);
        throw new Error(`ElevenLabs API Error: ${err}`);
    }

    // Return audio blob/stream
    // We need to return it as a blob or base64. 
    // Supabase Functions can return binary if we set headers correctly.
    const audioBuffer = await response.arrayBuffer();

    return new Response(audioBuffer, {
      headers: {
        ...corsHeaders,
        'Content-Type': 'audio/mpeg',
      },
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
