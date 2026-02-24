// Supabase Edge Function: check-weekly-regeneration
// Purpose: Check if weekly plans need regeneration based on skill changes
// Schedule: Run every Monday at 00:00 via Supabase Cron

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Thresholds for regeneration
const FI_THRESHOLD = 3; // ±3 points change in Fluency Index

interface RegenerationCheck {
  regenerate: boolean;
  reason: string;
  fiDelta?: number;
  primaryChanged?: boolean;
}

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    console.log('[check-weekly-regeneration] Starting weekly regeneration check');

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );

    // Get current week start (Monday)
    const today = new Date();
    const dayOfWeek = today.getDay();
    const diff = dayOfWeek === 0 ? -6 : 1 - dayOfWeek; // Adjust to Monday
    const monday = new Date(today);
    monday.setDate(today.getDate() + diff);
    const weekStart = monday.toISOString().split('T')[0];

    console.log(`[check-weekly-regeneration] Week start: ${weekStart}`);

    // Fetch all active students
    const { data: users, error: usersError } = await supabase
      .from('users_profile')
      .select('id, name')
      .eq('role', 'student');

    if (usersError) {
      console.error('[check-weekly-regeneration] Error fetching users:', usersError);
      throw usersError;
    }

    if (!users || users.length === 0) {
      console.log('[check-weekly-regeneration] No users found');
      return new Response(
        JSON.stringify({ message: 'No users found', results: [] }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`[check-weekly-regeneration] Processing ${users.length} users`);

    const results = [];

    for (const user of users) {
      try {
        const checkResult = await checkRegenerationRules(supabase, user.id, weekStart);
        
        if (checkResult.regenerate) {
          console.log(`[check-weekly-regeneration] Regenerating plan for user ${user.id} - Reason: ${checkResult.reason}`);
          await generateNewPlan(supabase, user.id, weekStart, checkResult.reason);
          results.push({ 
            user_id: user.id, 
            user_name: user.name,
            action: 'regenerated', 
            reason: checkResult.reason,
            fi_delta: checkResult.fiDelta
          });
        } else {
          console.log(`[check-weekly-regeneration] Keeping plan for user ${user.id} - Reason: ${checkResult.reason}`);
          results.push({ 
            user_id: user.id, 
            user_name: user.name,
            action: 'kept', 
            reason: checkResult.reason 
          });
        }
      } catch (error) {
        console.error(`[check-weekly-regeneration] Error processing user ${user.id}:`, error);
        results.push({ 
          user_id: user.id, 
          user_name: user.name,
          action: 'error', 
          reason: error.message 
        });
      }
    }

    console.log('[check-weekly-regeneration] Completed successfully');

    return new Response(
      JSON.stringify({ 
        success: true, 
        week_start: weekStart,
        total_users: users.length,
        regenerated: results.filter(r => r.action === 'regenerated').length,
        kept: results.filter(r => r.action === 'kept').length,
        errors: results.filter(r => r.action === 'error').length,
        results 
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('[check-weekly-regeneration] Fatal error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

async function checkRegenerationRules(
  supabase: any, 
  userId: string, 
  weekStart: string
): Promise<RegenerationCheck> {
  
  // 1. Fetch last snapshot
  const { data: lastSnapshot } = await supabase
    .from('weekly_skill_snapshot')
    .select('*')
    .eq('user_id', userId)
    .order('week_start', { ascending: false })
    .limit(1)
    .maybeSingle();

  // 2. Fetch current profile
  const { data: currentProfile } = await supabase
    .from('user_skill_profile')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();

  if (!currentProfile) {
    console.log(`[checkRegenerationRules] No profile found for user ${userId}`);
    return { regenerate: false, reason: 'no_profile' };
  }

  // 3. Create snapshot for current week
  const { error: snapshotError } = await supabase
    .from('weekly_skill_snapshot')
    .insert({
      user_id: userId,
      week_start: weekStart,
      fluency_index: currentProfile.fluency_index,
      primary_skill: currentProfile.primary_skill,
      secondary_skill: currentProfile.secondary_skill,
      speaking_score: currentProfile.speaking_score,
      grammar_score: currentProfile.grammar_score,
      vocabulary_score: currentProfile.vocabulary_score,
      fluency_score: currentProfile.fluency_score,
      listening_score: currentProfile.listening_score
    })
    .select()
    .single();

  if (snapshotError && snapshotError.code !== '23505') { // Ignore duplicate key error
    console.error(`[checkRegenerationRules] Error creating snapshot:`, snapshotError);
  }

  // 4. Check regeneration rules
  if (!lastSnapshot) {
    console.log(`[checkRegenerationRules] First plan for user ${userId}`);
    return { regenerate: true, reason: 'first_plan' };
  }

  // Rule 1: FI Delta >= ±3
  const fiDelta = currentProfile.fluency_index - lastSnapshot.fluency_index;
  if (Math.abs(fiDelta) >= FI_THRESHOLD) {
    console.log(`[checkRegenerationRules] FI delta ${fiDelta.toFixed(2)} exceeds threshold`);
    return { 
      regenerate: true, 
      reason: fiDelta > 0 ? 'fi_improvement' : 'fi_decline',
      fiDelta: fiDelta
    };
  }

  // Rule 2: Primary skill changed
  const primaryChanged = currentProfile.primary_skill !== lastSnapshot.primary_skill;
  if (primaryChanged) {
    console.log(`[checkRegenerationRules] Primary skill changed: ${lastSnapshot.primary_skill} → ${currentProfile.primary_skill}`);
    return { 
      regenerate: true, 
      reason: 'primary_skill_changed',
      primaryChanged: true
    };
  }

  // No regeneration needed
  return { 
    regenerate: false, 
    reason: 'stable',
    fiDelta: fiDelta
  };
}

async function generateNewPlan(
  supabase: any, 
  userId: string, 
  weekStart: string, 
  reason: string
): Promise<void> {
  
  console.log(`[generateNewPlan] Generating plan for user ${userId}, reason: ${reason}`);

  // 1. Archive previous active plan
  const { error: archiveError } = await supabase
    .from('weekly_plans')
    .update({ status: 'archived' })
    .eq('user_id', userId)
    .eq('status', 'active');

  if (archiveError) {
    console.error(`[generateNewPlan] Error archiving old plan:`, archiveError);
  }

  // 2. Fetch user profile and snapshot
  const { data: profile } = await supabase
    .from('user_skill_profile')
    .select('*')
    .eq('user_id', userId)
    .single();

  const { data: snapshot } = await supabase
    .from('weekly_skill_snapshot')
    .select('id')
    .eq('user_id', userId)
    .eq('week_start', weekStart)
    .single();

  if (!profile || !snapshot) {
    throw new Error('Profile or snapshot not found');
  }

  // 3. Fetch user level from users_profile
  const { data: userProfile } = await supabase
    .from('users_profile')
    .select('level, goal, interests')
    .eq('id', userId)
    .single();

  // 4. Call ai-orchestrator to generate adaptive plan
  const { data: planResult, error: planError } = await supabase.functions.invoke('ai-orchestrator', {
    body: {
      action: 'generate_adaptive_weekly_plan',
      user_id: userId,
      week_start: weekStart,
      snapshot_id: snapshot.id,
      profile: profile,
      user_level: userProfile?.level || 'A1',
      user_goal: userProfile?.goal || 'General English',
      user_interests: userProfile?.interests || [],
      regeneration_reason: reason
    }
  });

  if (planError) {
    console.error(`[generateNewPlan] Error calling ai-orchestrator:`, planError);
    throw planError;
  }

  console.log(`[generateNewPlan] Plan generated successfully for user ${userId}`);
}
