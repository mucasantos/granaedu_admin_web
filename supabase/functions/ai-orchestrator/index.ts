// Supabase Edge Function: ai-orchestrator
// Purpose: Generate weekly plans and tasks based on user level and goal

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { firebase_uid, action } = await req.json()

    // Initialize Supabase Client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // 1. Fetch User Profile
    const { data: userProfile, error: userError } = await supabase
      .from('users_profile')
      .select('*')
      .eq('firebase_uid', firebase_uid)
      .single()

    if (userError || !userProfile) {
      throw new Error('User profile not found')
    }

    if (action === 'generate_weekly_plan') {
      // TODO: Call OpenAI API using system prompts from settings
      // For now, returning a mock response to verify plumbing
      
      return new Response(
        JSON.stringify({ 
          message: `Weekly plan generation requested for ${userProfile.name}`,
          level: userProfile.level,
          goal: userProfile.goal
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({ error: 'Invalid action' }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
