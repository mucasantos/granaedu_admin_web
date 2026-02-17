
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import { crypto } from "https://deno.land/std@0.177.0/crypto/mod.ts";

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

    if (!text && (!dialogue || dialogue.length === 0)) {
      return new Response(JSON.stringify({ error: 'Text or Dialogue is required' }), {
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
      // 1. Initialize Supabase Admin Client for Storage
      const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
      const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
      const supabase = createClient(supabaseUrl, supabaseServiceKey);

      // 2. Determine Content for Hashing
      let contentToHash = '';
      if (dialogue && Array.isArray(dialogue) && dialogue.length > 0) {
        contentToHash = JSON.stringify(dialogue);
      } else {
        contentToHash = text + (voiceId || 'default');
      }

      // 3. Generate Hash (MD5)
      const encoder = new TextEncoder();
      const data = encoder.encode(contentToHash);
      const hashBuffer = await crypto.subtle.digest("SHA-256", data); // Use SHA-256 as it's standard in Web Crypto
      const hashArray = Array.from(new Uint8Array(hashBuffer));
      const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
      const fileName = `${hashHex}.mp3`;

      // 4. Check if file exists in Storage by listing
      const { data: listData, error: listError } = await supabase
        .storage
        .from('listening-audio')
        .list('', { search: fileName });

      if (!listError && listData && listData.length > 0) {
        console.log(`Audio found in cache: ${fileName}`);
        const { data: signedUrlData } = await supabase
          .storage
          .from('listening-audio')
          .createSignedUrl(fileName, 60 * 60 * 24 * 365); // 1 year

        return new Response(JSON.stringify({ audioUrl: signedUrlData?.signedUrl }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      console.log(`Audio NOT found in cache. Generating new...`);

      // 5. Generate Audio via ElevenLabs
      let audioBuffer: ArrayBuffer;

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
          // 1. Identify Unique Speakers
          const speakers = [...new Set(dialogue.map((item: any) => item.speaker))];
          const voiceMap: Record<string, string> = {};

          // Map first speaker to Rachel (Female), second to Domi (Male/Deep), others fallback
          // Ideally rely on gender detection or just alternate using a few predefined voices.
          // For now, let's keep it simple: Spk1 -> Rachel, Spk2 -> Domi
          if (speakers.length > 0) voiceMap[speakers[0]] = '21m00Tcm4TlvDq8ikWAM'; // Rachel
          if (speakers.length > 1) voiceMap[speakers[1]] = 'AZnzlk1XvdvUeBnXmlld'; // Domi

          const inputs = dialogue.map((item: any) => ({
            text: item.text,
            voice_id: voiceMap[item.speaker] || '21m00Tcm4TlvDq8ikWAM', // Fallback to Rachel
          }));

          const response = await fetch('https://api.elevenlabs.io/v1/text-to-dialogue/with-timestamps?output_format=mp3_44100_128', {
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
          audioBuffer = new Uint8Array(len).buffer;
          const bytes = new Uint8Array(audioBuffer);
          for (let i = 0; i < len; i++) {
            bytes[i] = binaryString.charCodeAt(i);
          }

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

          audioBuffer = await response.arrayBuffer();
        }

        // 6. Upload to Storage
        const { error: uploadError } = await supabase
          .storage
          .from('listening-audio')
          .upload(fileName, audioBuffer, {
            contentType: 'audio/mpeg',
            upsert: true
          });

        if (uploadError) {
          console.error('Upload Error:', uploadError);
          // Fallback: return binary directly if upload fails?
          // Or just throw. Let's return binary as fallback if upload fails, 
          // BUT wait, we want to unify the response format.
          // If upload fails, we can't give a URL. 
          // Let's THROW for now to ensure we fix storage permissions if needed.
          throw new Error(`Failed to upload audio to storage: ${uploadError.message}`);
        }

        const { data: signedUrlData, error: signError } = await supabase
          .storage
          .from('listening-audio')
          .createSignedUrl(fileName, 60 * 60 * 24 * 365);

        if (signError || !signedUrlData) {
          throw new Error(`Failed to create signed URL: ${signError?.message}`);
        }

        return new Response(JSON.stringify({ audioUrl: signedUrlData.signedUrl }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });

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

        audioBuffer = await response.arrayBuffer();

        // Upload OpenAI Audio too
        const { error: uploadError } = await supabase
          .storage
          .from('listening-audio')
          .upload(fileName, audioBuffer, {
            contentType: 'audio/mpeg',
            upsert: true
          });

        if (uploadError) throw new Error(`Storage Upload Error: ${uploadError.message}`);

        const { data: signedUrlData, error: signError } = await supabase
          .storage
          .from('listening-audio')
          .createSignedUrl(fileName, 60 * 60 * 24 * 365);

        if (signError || !signedUrlData) {
          throw new Error(`Failed to create signed URL: ${signError?.message}`);
        }

        return new Response(JSON.stringify({ audioUrl: signedUrlData.signedUrl }), {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
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
