
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { text, mode, targetLang, provider = 'openai', voiceId, dialogue } = await req.json();

    if (!text) {
      return new Response(JSON.stringify({ error: 'Text is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // MODE: EXPLAIN (or Translate)
    if (mode === 'explain' || mode === 'translate') {
      const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY');
      if (!OPENAI_API_KEY) {
        throw new Error('Missing OpenAI API Key');
      }

      const prompt = mode === 'translate'
        ? `Translate the following English text to ${targetLang || 'Portuguese'}: "${text}"`
        : `Explain the following English text in simple ${targetLang === 'pt' ? 'Portuguese' : 'English'}: "${text}"`;

      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${OPENAI_API_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-3.5-turbo',
          messages: [{ role: 'user', content: prompt }],
        }),
      });

      const data = await response.json();
      const result = data.choices[0].message.content;

      return new Response(JSON.stringify({ result }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // MODE: TTS (Text-to-Speech)
    if (mode === 'tts') {
      // Provider selection: 'openai' or 'elevenlabs'
      
      if (provider === 'elevenlabs') {
        const ELEVENLABS_API_KEY = Deno.env.get('ELEVENLABS_API_KEY');
        if (!ELEVENLABS_API_KEY) {
          console.warn("ElevenLabs API Key missing. Falling back...");
          throw new Error('Missing ElevenLabs API Key');
        }

        // Check if we have a DIALOGUE payload (LISTENING TASK)
        // dialogue is already destructured from the initial req.json() call
        // Note: we already parsed req.json into { text, mode... } above at line 16. 
        // We need to re-access 'dialogue' if it wasn't extracted.
        // Actually, let's fix line 16 extraction first or accessing it from the already parsed body if possible.
        // Wait, 'req.json()' can only be consumed once. I need to update the initial destructuring.

        // Let's assume I will update line 16 in a separate chunk or just handle it carefully.
        // For this chunk, I'll assume 'dialogue' is available in the scope or I'll re-implement the extraction.
        // Ah, I can't re-read req.json(). 
        // I MUST Update Line 16 First or merge the edits. 
        // I will use multi_replace for this to be safe, but let's look at the plan.
        // I'll update line 16 to extract dialogue, then implement the logic here.

        // ... (Self-correction: I will do this in the next tool call. For now, I'll write the logic assuming 'dialogue' is passed down).

        if (dialogue && Array.isArray(dialogue) && dialogue.length > 0) {
          // TEXT-TO-DIALOGUE
          const inputs = dialogue.map((item: any) => ({
            text: item.text,
            voice_id: item.speaker === 'A' ? '21m00Tcm4TlvDq8ikWAM' : 'AZnzlk1XvdvUeBnXmlld', // Rachel (A) vs Domi (B)
          }));

          const response = await fetch('https://api.elevenlabs.io/v1/text-to-dialogue/with-timestamps?output_format=mp3_44100_128', { // Requesting MP3 effectively by format? User used alaw_8000. Let's try mp3 or default. 
            // Documentation says output_format query param is supported. 
            // User example: output_format=alaw_8000. 
            // I prefer mp3_44100_128 for quality.
            method: 'POST',
            headers: {
              'xi-api-key': ELEVENLABS_API_KEY,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              inputs: inputs,
            }),
          });

          if (!response.ok) {
            const err = await response.text();
            throw new Error(`ElevenLabs Dialogue Error: ${err}`);
          }

          const data = await response.json();
          if (!data.audio_base64) {
            throw new Error('ElevenLabs did not return audio_base64');
          }

          // Decode Base64 to Binary
          const binaryString = atob(data.audio_base64);
          const len = binaryString.length;
          const bytes = new Uint8Array(len);
          for (let i = 0; i < len; i++) {
            bytes[i] = binaryString.charCodeAt(i);
          }

          return new Response(bytes, {
            headers: { ...corsHeaders, 'Content-Type': 'audio/mpeg' },
          });

        } else {
          // STANDARD TTS (Single Voice)
          const VOICE_ID = voiceId || '21m00Tcm4TlvDq8ikWAM';
          const response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}`, {
            method: 'POST',
            headers: {
              'xi-api-key': ELEVENLABS_API_KEY,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              text: text,
              voice_settings: {
                stability: 0.5,
                similarity_boost: 0.5
              }
            }),
          });

          if (!response.ok) {
            const err = await response.text();
            throw new Error(`ElevenLabs API Error: ${err}`);
          }

          const audioBuffer = await response.arrayBuffer();
          return new Response(audioBuffer, {
            headers: { ...corsHeaders, 'Content-Type': 'audio/mpeg' },
          });
        }
      } else {
        // DEFAULT: OpenAI TTS
        const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY');
        if (!OPENAI_API_KEY) {
          throw new Error('Missing OpenAI API Key');
        }

        const response = await fetch('https://api.openai.com/v1/audio/speech', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${OPENAI_API_KEY}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: 'tts-1',
            input: text,
            voice: voiceId || 'alloy',
          }),
        });

        if (!response.ok) {
            const err = await response.text();
            throw new Error(`OpenAI TTS Error: ${err}`);
        }

        const audioBuffer = await response.arrayBuffer();
        return new Response(audioBuffer, {
          headers: { ...corsHeaders, 'Content-Type': 'audio/mpeg' },
        });
      }
    }

    return new Response(JSON.stringify({ error: 'Invalid mode' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
