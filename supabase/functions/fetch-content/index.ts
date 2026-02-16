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
    const { url } = await req.json()

    if (!url) {
      throw new Error('URL is required')
    }

    console.log(`Fetching content from: ${url}`)

    const contentResponse = await fetch(url)
    if (!contentResponse.ok) {
        throw new Error(`Failed to fetch content: ${contentResponse.statusText}`)
    }
    
    // Check content type to ensure it's text
    const contentType = contentResponse.headers.get("content-type");
    if (contentType && !contentType.includes("text")) {
        // Optional: handle non-text but Gutenberg usually gives text/plain
        console.warn(`Warning: Content-Type is ${contentType}`)
    }

    const text = await contentResponse.text()

    return new Response(
      JSON.stringify({ content: text }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
