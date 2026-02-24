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

    // Fetch user skill profile (grammar, fluency, primary_skill, etc)
    let userSkillProfile = profile;
    if (!userSkillProfile) {
      const { data: fetchedProfile, error: profileErr } = await supabase
        .from('user_skill_profile')
        .select('*')
        .eq('user_id', user_id)
        .single();

      if (profileErr || !fetchedProfile) {
        console.error(`[generate-initial-plan] Error fetching skill profile for ${user_id}:`, profileErr);
        throw new Error(`User skill profile not found for user ${user_id}`);
      }
      userSkillProfile = fetchedProfile;
    }

    // Fetch the snapshot ID for this week created by ensure_weekly_plan_exists
    let currentSnapshotId = snapshot_id;
    if (!currentSnapshotId) {
      const { data: latestSnapshot } = await supabase
        .from('weekly_skill_snapshot')
        .select('id')
        .eq('user_id', user_id)
        .eq('week_start', week_start)
        .maybeSingle();

      if (latestSnapshot) {
        currentSnapshotId = latestSnapshot.id;
      }
    }

    // Call ai-orchestrator to generate adaptive plan
    console.log(`[generate-initial-plan] Calling ai-orchestrator for user ${user_id}`);
    
    // We cannot pass the User JWT because API Gateway occasionally strips/rejects it 
    // when coming from another Edge function. 
    // We will use the Service Role Key to guarantee the request succeeds.
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!serviceRoleKey) {
      throw new Error("Missing SUPABASE_SERVICE_ROLE_KEY");
    }

    const orchestratorUrl = `${Deno.env.get('SUPABASE_URL')}/functions/v1/ai-orchestrator`;
    console.log(`[generate-initial-plan] Targeting ${orchestratorUrl} with Service Role Key...`);
    const aiResponse = await fetch(orchestratorUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${serviceRoleKey}`
      },
      body: JSON.stringify({
        action: 'generate_adaptive_weekly_plan',
        user_id: user_id,
        week_start: week_start,
        snapshot_id: currentSnapshotId,
        profile: userSkillProfile,
        user_level: userProfile.level || 'A1',
        user_goal: userProfile.goal || 'General English',
        user_interests: userProfile.interests || [],
        regeneration_reason: 'first_plan'
      })
    });

    console.log(`[generate-initial-plan] Received status ${aiResponse.status} from ai-orchestrator`);

    // We must read the text first so we can log it if JSON parsing fails or if it's an error.
    const responseText = await aiResponse.text();
    console.log(`[generate-initial-plan] ai-orchestrator raw response: ${responseText.substring(0, 500)}...`);

    if (!aiResponse.ok) {
      console.error(`[generate-initial-plan] Error calling ai-orchestrator: ${aiResponse.status} - ${responseText}`);
      throw new Error(`ai-orchestrator failed with status ${aiResponse.status}: ${responseText}`);
    }

    let aiResult;
    try {
      aiResult = JSON.parse(responseText);
    } catch (parseErr) {
      console.error(`[generate-initial-plan] Failed to parse ai-orchestrator response: ${parseErr.message}`);
      throw new Error(`ai-orchestrator returned invalid JSON. Raw response: ${responseText.substring(0, 100)}`);
    }

    if (!aiResult.success) {
      console.error(`[generate-initial-plan] ai-orchestrator returned success: false. Result:`, aiResult);
      throw new Error(`ai-orchestrator logic failed: ${aiResult.error || JSON.stringify(aiResult)}`);
    }

    const planResult = aiResult;

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

