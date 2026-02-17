
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
      // 5. Generate Audio
      let audioBuffer: ArrayBuffer | null = null;
      let usedProvider = provider;

      // ATTEMPT ELEVENLABS FIRST (if requested)
      if (provider === 'elevenlabs') {
        try {
          console.log("Attempting ElevenLabs generation...");
          const ELEVENLABS_API_KEY = Deno.env.get('ELEVENLABS_API_KEY');
          if (!ELEVENLABS_API_KEY) throw new Error('Missing ElevenLabs API Key');

          if (dialogue && Array.isArray(dialogue) && dialogue.length > 0) {
            // ... (Existing ElevenLabs Text-to-Dialogue logic) ...
            // Identify Unique Speakers
            const speakers = [...new Set(dialogue.map((item: any) => item.speaker))];
            const voiceMap: Record<string, string> = {};
            if (speakers.length > 0) voiceMap[speakers[0]] = '21m00Tcm4TlvDq8ikWAM'; // Rachel
            if (speakers.length > 1) voiceMap[speakers[1]] = 'AZnzlk1XvdvUeBnXmlld'; // Domi

            const inputs = dialogue.map((item: any) => ({
              text: item.text,
              voice_id: voiceMap[item.speaker] || '21m00Tcm4TlvDq8ikWAM',
            }));

            const response = await fetch('https://api.elevenlabs.io/v1/text-to-dialogue/with-timestamps?output_format=mp3_44100_128', {
              method: 'POST',
              headers: {
                'xi-api-key': ELEVENLABS_API_KEY,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({ inputs: inputs }),
            });

            if (!response.ok) {
              const err = await response.text();
              throw new Error(`ElevenLabs Dialogue Error: ${err}`);
            }

            const data = await response.json();
            if (!data.audio_base64) throw new Error('ElevenLabs did not return audio_base64');
            const binaryString = atob(data.audio_base64);
            const len = binaryString.length;
            audioBuffer = new Uint8Array(len).buffer;

          } else {
            // ... (Existing ElevenLabs Single Voice logic) ...
            const VOICE_ID = voiceId || '21m00Tcm4TlvDq8ikWAM';
            const response = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}`, {
              method: 'POST',
              headers: {
                'xi-api-key': ELEVENLABS_API_KEY,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                text: text,
                voice_settings: { stability: 0.5, similarity_boost: 0.5 }
              }),
            });

            if (!response.ok) {
              const err = await response.text();
              throw new Error(`ElevenLabs API Error: ${err}`);
            }
            audioBuffer = await response.arrayBuffer();
          }

        } catch (err) {
          console.error(`ElevenLabs failed: ${err.message}. Falling back to OpenAI...`);
          usedProvider = 'openai'; // Trigger fallback
          audioBuffer = null;
        }
      }

      // OPENAI GENERATION (Default or Fallback)
      if (!audioBuffer && (usedProvider === 'openai')) {
        console.log("Generating with OpenAI...");
        const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY');
        if (!OPENAI_API_KEY) throw new Error('Missing OpenAI API Key');

        if (dialogue && Array.isArray(dialogue) && dialogue.length > 0) {
          // MULTI-SPEAKER OPENAI IMPLEMENTATION
          console.log("Processing OpenAI Multi-Speaker Dialogue...");

          // 1. Identify Speakers and Map to Voices
          const speakers = [...new Set(dialogue.map((item: any) => item.speaker))];
          // Use female voices only: nova, shimmer, alloy
          const openAiVoices = ['nova', 'shimmer', 'alloy'];
          const speakerVoiceMap: Record<string, string> = {};

          speakers.forEach((spk, index) => {
            speakerVoiceMap[spk] = openAiVoices[index % openAiVoices.length];
          });

          // 2. Generate Audio Chunks
          const audioChunks: Uint8Array[] = [];

          for (const line of dialogue) {
            const voice = speakerVoiceMap[line.speaker] || 'alloy';
            const response = await fetch('https://api.openai.com/v1/audio/speech', {
              method: 'POST',
              headers: {
                'Authorization': `Bearer ${OPENAI_API_KEY}`,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                model: 'tts-1', // Use tts-1 for speed, tts-1-hd for quality
                input: line.text,
                voice: voice,
              }),
            });

            if (!response.ok) {
              console.error(`OpenAI TTS Error for line: "${line.text}"`);
              continue; // Skip failed line or throw? Let's skip to keep going.
            }
            const chunkBuffer = await response.arrayBuffer();
            audioChunks.push(new Uint8Array(chunkBuffer));
          }

          // 3. Concatenate Chunks
          if (audioChunks.length === 0) throw new Error("Failed to generate any audio chunks with OpenAI");

          const totalLength = audioChunks.reduce((acc, chunk) => acc + chunk.length, 0);
          const combinedAudio = new Uint8Array(totalLength);
          let offset = 0;
          for (const chunk of audioChunks) {
            combinedAudio.set(chunk, offset);
            offset += chunk.length;
          }
          audioBuffer = combinedAudio.buffer;

        } else {
          // SINGLE VOICE OPENAI
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
        }
      }

      if (!audioBuffer) {
        throw new Error("Failed to generate audio with both providers.");
      }

      // 6. Upload to Storage
      // ... (Rest of upload logic) ...
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

      const audioUrl = signedUrlData.signedUrl;

      // 7. Save Generation Metadata to Database (listening_generations)
      try {
        await supabase
          .from('listening_generations')
          .insert({
            text_content: text, // Might be empty if pure dialogue
            dialogue_json: dialogue, // Can be null
            audio_url: audioUrl,
            audio_hash: fileName.replace('.mp3', ''), // Filename is the hash
            provider: usedProvider
          });
        console.log(`Saved generation metadata for hash: ${fileName}`);
      } catch (dbErr) {
        console.error('Failed to save generation metadata:', dbErr);
        // Non-blocking error, return audio anyway
      }

      return new Response(JSON.stringify({ audioUrl: audioUrl }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
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
