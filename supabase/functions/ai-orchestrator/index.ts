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
    const { firebase_uid, action, openai_key, task_id } = await req.json()

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
      const userInterests = userProfile.interests || [];

      console.log(`Generating skeletal plan for ${userProfile.name} (Level: ${userLevel}, Goal: ${userGoal})`);

      const WEEKLY_PLAN_PROMPT = `You are an expert curriculum planner. 
      Create a high-level 7-day English learning plan outline. 
      DO NOT generate lesson content, reading texts, or quizzes yet.
      Only generate titles, topics, and metadata.`;

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
              content: WEEKLY_PLAN_PROMPT
            },
            {
              role: 'user',
              content: `Generate a 7-day English learning plan for a student at ${userLevel} level with the goal of "${userGoal}". 
              The student is interested in: ${userInterests.join(', ') || 'general topics'}.

              CRITICAL: Ensure a balanced mix of skills.
              - Day 1: Grammar/Reading
              - Day 2: Listening
              - Day 3: Speaking
              - Day 4: Writing (MUST BE INCLUDED)
              - Day 5: Reading
              - Day 6/7: Review/Mixed

              Respond ONLY with a valid JSON in the following format:
              {
                "week_start": "YYYY-MM-DD",
                "level": "${userLevel}",
                "focus": {"reading": true, "speaking": true, "writing": true, "listening": true},
                "logic": "Detailed pedagogical explanation",
                "tasks": [
                  {
                    "day": 1,
                    "skill": "grammar/reading/listening/writing",
                    "title": "Topic Title",
                    "estimated_minutes": 15,
                    "difficulty": "easy/medium/hard"
                  }
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
          logic: planData.logic,
          version: 2
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
        content: { title: t.title }, // Start with just the title
        estimated_minutes: t.estimated_minutes || 15,
        difficulty: t.difficulty || 'medium',
      }));

      const { error: tasksError } = await supabase
        .from('daily_tasks')
        .insert(tasksToInsert);

      if (tasksError) throw tasksError;

      return new Response(
        JSON.stringify({ 
          success: true,
          message: `Weekly plan generated (Skeletal) for ${userProfile.name}`,
          plan_id: plan.id
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'generate_task_content') {
      if (!task_id) throw new Error('Task ID is required');

      // 1. Fetch Task and Profile context
      const { data: task, error: taskError } = await supabase
        .from('daily_tasks')
        .select('*, weekly_plans(level, focus, logic)')
        .eq('id', task_id)
        .single();

      if (taskError || !task) throw new Error('Task not found');

      const userLevel = userProfile.level || 'A1';
      const userGoal = userProfile.goal || 'General English';
      const userInterests = userProfile.interests || [];

      const CONTENT_PROMPT = `You are a World-Class ESL Pedagogical Mentor.
      Your goal is to generate deep, engaging, and personalized educational content for a specific English task.
      Adapt tone and complexity strictly to the student's level (${userLevel}).`;

      // 2. Call OpenAI for deep content
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
              content: CONTENT_PROMPT
            },
            {
              role: 'user',
              content: `Generate full content for an English learning task:
              - Skill: ${task.skill}
              - Title: ${task.content?.title || 'General Lesson'}
              - Student Level: ${userLevel}
              - Student Goal: ${userGoal}
              - Student Interests: ${userInterests.join(', ')}

              CRITICAL INSTRUCTIONS:
              - If the skill is "writing":
                - You MUST provide a specific "Topic" or "Scenario" for the student to write about.
                - "practice_prompt" MUST be the actual writing instruction (e.g. "Write an email to...").
                - "questions" MUST be an empty array [].
                - "explanation" should focus on tips for this specific writing type (e.g. formal email structure).
              - If the skill is "reading":
                - You MUST provide the FULL text to read (150-600 words depending on level).
                - The text topic MUST be related to one of the student's interests (${userInterests.length > 0 ? 'pick one interest dynamically' : 'general interesting topic'}).
                - For READING: Alternate between "Real World News/Articles" usage and "Short Stories/Fiction".
                - QUESTIONS: You MUST generate EXACTLY 10 multiple-choice questions for reading comprehension.
              - If the skill is NOT "reading" AND NOT "writing":
                - Provide 3-5 questions.
              - Provide an "explanation", "examples" (array), a "practice_prompt".
              
              Respond ONLY with a valid JSON in the following format:
              {
                "title": "${task.content?.title}", // You may slightly improve the title to be more catchy if needed
                "explanation": "Deep theoretical explanation OR The Full Reading Text",
                "examples": ["example 1", "example 2"],
                "practice_prompt": "Specific instruction for the student to practice this skill",
                "questions": [
                  {
                    "question": "Question text?",
                    "options": ["A", "B", "C", "D"],
                    "correct_ans_index": 0
                  }
                ]
              }`
            }
          ],
          response_format: { type: "json_object" }
        })
      });

      const aiResult = await openaiResponse.json();
      const newContent = JSON.parse(aiResult.choices[0].message.content);

      // 3. Update Task in DB
      const { error: updateError } = await supabase
        .from('daily_tasks')
        .update({ content: newContent })
        .eq('id', task_id);

      if (updateError) throw updateError;

      return new Response(
        JSON.stringify({ success: true, content: newContent }),
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
