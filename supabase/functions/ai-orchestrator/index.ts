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
    const { firebase_uid, action, openai_key, system_prompt } = await req.json()

    if (!openai_key) throw new Error('OpenAI API Key is required')

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
      throw new Error(`User profile not found: ${userError?.message || ''}`)
    }

    if (action === 'generate_weekly_plan') {
      const userLevel = userProfile.level || 'A1';
      const userGoal = userProfile.goal || 'General English';

      console.log(`Generating plan for ${userProfile.name} (Level: ${userLevel}, Goal: ${userGoal})`);

      // 2. Call OpenAI
      const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${openai_key}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [
            {
              role: 'system',
              content: system_prompt || 'You are an English Learning Assistant. Generate a structured 7-day learning plan.'
            },
            {
              role: 'user',
              content: `Generate a 7-day English learning plan for a student at ${userLevel} level with the goal of "${userGoal}". 
              Respond ONLY with a valid JSON in the following format:
              {
                "week_start": "YYYY-MM-DD",
                "level": "${userLevel}",
                "focus": {"reading": true, "speaking": true, "writing": false, "listening": true},
                "tasks": [
                  {
                    "day": 1,
                    "skill": "grammar",
                    "title": "Topic Title",
                    "content": {
                      "explanation": "Brief explanation",
                      "examples": ["example 1", "example 2"],
                      "practice_prompt": "What the user should do",
                      "questions": [
                        {
                          "question": "Question text?",
                          "options": ["A", "B", "C", "D"],
                          "correct_ans_index": 0
                        }
                      ]
                    }
                  },
                  ... (up to 7 days)
                ]
              }`
            }
          ],
          response_format: { type: "json_object" }
        })
      })

      const aiResult = await openaiResponse.json();
      const planData = JSON.parse(aiResult.choices[0].message.content);

      // 3. Save to Database
      // Create Weekly Plan
      const { data: plan, error: planError } = await supabase
        .from('weekly_plans')
        .insert({
          user_id: userProfile.id,
          week_start: planData.week_start,
          level: planData.level,
          focus: planData.focus,
        })
        .select()
        .single()

      if (planError) throw planError;

      // Create Daily Tasks
      const tasksToInsert = planData.tasks.map((t: any) => ({
        plan_id: plan.id,
        user_id: userProfile.id,
        day_of_week: t.day,
        skill: t.skill,
        content: t.content,
      }));

      const { error: tasksError } = await supabase
        .from('daily_tasks')
        .insert(tasksToInsert);

      if (tasksError) throw tasksError;

      return new Response(
        JSON.stringify({ 
          success: true,
          message: `Weekly plan generated and saved for ${userProfile.name}`,
          plan_id: plan.id
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
