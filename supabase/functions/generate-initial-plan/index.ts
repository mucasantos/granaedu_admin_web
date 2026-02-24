// Supabase Edge Function: generate-initial-plan
// Purpose: Generate first weekly plan for new users immediately
// Trigger: Called by database trigger when user_skill_profile is created

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { user_id, week_start, snapshot_id, profile } = await req.json();

    console.log(`[generate-initial-plan] Generating initial plan for user ${user_id}`);

    if (!user_id || !week_start) {
      throw new Error('Missing required parameters: user_id, week_start');
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Check if plan already exists for this week
    const { data: existingPlan } = await supabase
      .from('weekly_plans')
      .select('id')
      .eq('user_id', user_id)
      .eq('week_start', week_start)
      .maybeSingle();

    if (existingPlan) {
      console.log(`[generate-initial-plan] Plan already exists for user ${user_id}, week ${week_start}`);
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'Plan already exists',
          plan_id: existingPlan.id 
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Fetch user profile details
    const { data: userProfile } = await supabase
      .from('users_profile')
      .select('level, goal, interests, name')
      .eq('id', user_id)
      .single();

    if (!userProfile) {
      throw new Error(`User profile not found for user ${user_id}`);
    }

    // Call ai-orchestrator to generate adaptive plan
    console.log(`[generate-initial-plan] Calling ai-orchestrator for user ${user_id}`);
    
    const { data: planResult, error: planError } = await supabase.functions.invoke('ai-orchestrator', {
      body: {
        action: 'generate_adaptive_weekly_plan',
        user_id: user_id,
        week_start: week_start,
        snapshot_id: snapshot_id,
        profile: profile,
        user_level: userProfile.level || 'A1',
        user_goal: userProfile.goal || 'General English',
        user_interests: userProfile.interests || [],
        regeneration_reason: 'first_plan'
      }
    });

    if (planError) {
      console.error(`[generate-initial-plan] Error calling ai-orchestrator:`, planError);
      throw planError;
    }

    console.log(`[generate-initial-plan] Initial plan generated successfully for user ${user_id}`);

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'Initial plan generated successfully',
        user_id: user_id,
        user_name: userProfile.name,
        week_start: week_start,
        plan_result: planResult
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('[generate-initial-plan] Error:', error);
    return new Response(
      JSON.stringify({ 
        success: false,
        error: error.message 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    );
  }
});

