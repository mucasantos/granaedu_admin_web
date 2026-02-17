// Supabase Edge Function: ai-orchestrator
// Purpose: Generate weekly plans and tasks based on user level and goal

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.38.4"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req: Request) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Log request for debugging
    console.log('[ai-orchestrator] Request received');

    const body = await req.json()
    const { user_id, action, openai_key: bodyKey, task_id, plan_id, topic, config } = body

    console.log(`[ai-orchestrator] Action: ${action}, User ID: ${user_id}`);

    const targetUserId = user_id;

    if (!targetUserId) {
      console.error('[ai-orchestrator] No user ID provided');
      throw new Error('User ID is required');
    }

    // Initialize Supabase Client with SERVICE_ROLE_KEY for admin access
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('[ai-orchestrator] Missing Supabase credentials');
      throw new Error('Supabase configuration is missing');
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    let openai_key = bodyKey || Deno.env.get('OPENAI_API_KEY')
    let gemini_key = Deno.env.get('GEMINI_API_KEY')

    // Helper to fetch keys from DB if missing
    const getGeminiKey = async () => {
      if (gemini_key) return gemini_key;
      const { data } = await supabase.from('app_settings').select('gemini_key').maybeSingle();
      return data?.gemini_key;
    };

    const getModel = async (apiKey: string) => {
      try {
        const listResponse = await fetch(`https://generativelanguage.googleapis.com/v1/models?key=${apiKey}`);
        if (!listResponse.ok) {
          const errText = await listResponse.text();
          console.error(`[ai-orchestrator] List Models API Error: ${listResponse.status} - ${errText}`);
          return 'models/gemini-1.5-flash';
        }
        const listData = await listResponse.json();
        const availableModel = listData.models?.find((m: any) =>
          m.supportedGenerationMethods?.includes('generateContent') &&
          (m.name.includes('gemini-2.0-flash') || m.name.includes('gemini-1.5-flash') || m.name.includes('flash'))
        );
        return availableModel?.name || 'models/gemini-1.5-flash';
      } catch (e) {
        console.error("[ai-orchestrator] Model discovery unexpected error:", e);
        return 'models/gemini-1.5-flash';
      }
    };

    const extractJSON = (text: string) => {
      try {
        // Try direct parse first
        return JSON.parse(text);
      } catch {
        // Try regex match for JSON block
        const match = text.match(/\{[\s\S]*\}/);
        if (match) {
          try {
            return JSON.parse(match[0]);
          } catch (e) {
            console.error("[ai-orchestrator] Regex JSON parse error:", e);
            throw new Error("Failed to parse JSON from AI response block");
          }
        }
        throw new Error("No JSON object found in AI response");
      }
    };

    const getOpenAIKey = async () => {
      if (openai_key) return openai_key;
      const { data } = await supabase.from('app_settings').select('openai_key').maybeSingle();
      return data?.openai_key;
    };

    const getProfile = async () => {
      const { data } = await supabase
        .from('users_profile')
        .select('*')
        .eq('id', targetUserId)
        .maybeSingle();
      return data;
    };

    const activeGeminiKey = await getGeminiKey();
    console.log(`[ai-orchestrator] Action: ${action}, Key present: ${!!activeGeminiKey}`);

    // Check if action requires Gemini key
    const geminiActions = ['evaluate_student', 'generate_class_insights', 'grade_submission', 'suggest_activity', 'generate_quiz', 'generate_lesson_plan', 'generate_activity'];
    if (!activeGeminiKey && geminiActions.includes(action)) {
      console.error(`[ai-orchestrator] Missing Gemini key for action: ${action}`);
      throw new Error('Gemini API Key is missing in both ENV and app_settings');
    }

    const modelName = await getModel(activeGeminiKey);
    console.log(`[ai-orchestrator] Using Gemini model: ${modelName}`);

    const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/${modelName}:generateContent?key=${activeGeminiKey}`;

    if (action === 'evaluate_student') {
      const { text, lang } = body;
      if (!text || text.trim() === '') throw new Error('No text provided to evaluate.');

      const response = await fetch(geminiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: `You are a supportive English teacher evaluating a high school student's writing. 
                Analyze the student's text.
                1. Estimate their CEFR level (A1, A2, B1, B2, C1, C2).
                2. Provide a very brief (1-2 sentences), encouraging feedback directly to the student. Highlight what they did well and one small thing to improve.
                CRITICAL: Write the feedback exactly in ${lang === 'pt' ? 'Portuguese' : 'English'}.
                Return ONLY a JSON object: { "level": "A1-C2", "feedback": "..." }
                
                Student Text: "${text}"`
            }]
          }],
          generation_config: {
            response_mime_type: "application/json"
          }
        })
      });

      const result = await response.json();
      if (!response.ok || !result.candidates?.[0]) {
        console.error("Gemini Error:", JSON.stringify(result));
        throw new Error(result.error?.message || "Gemini returned no results or error");
      }
      const aiText = result.candidates[0].content.parts[0].text;
      const content = extractJSON(aiText);

      return new Response(JSON.stringify({ success: true, ...content }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    if (action === 'generate_class_insights') {
      const { students: studentsData, lang } = body;
      if (!studentsData || studentsData.length === 0) throw new Error('No students provided');

      // 1. Calculate Multiple Intelligences Totals and Averages
      const miKeys = ['Linguistic', 'LogicalMathematical', 'Musical', 'BodilyKinesthetic', 'VisualSpatial', 'Interpersonal', 'Intrapersonal', 'Naturalistic'];
      const miTotals: Record<string, number> = {};
      studentsData.forEach((s: any) => {
        if (s.multipleIntelligences) {
          Object.entries(s.multipleIntelligences).forEach(([key, val]: [string, any]) => {
            miTotals[key] = (miTotals[key] || 0) + (typeof val === 'number' ? val : 0);
          });
        }
      });
      const miAveragesMap = Object.fromEntries(
        Object.entries(miTotals).map(([key, val]) => [key, (val / studentsData.length).toFixed(1)])
      );

      // 2. Map student data for pedagogical analysis - align with frontend mapping
      // If data is already aggregated by the frontend (as in geminiService.ts), reuse it.
      const aggregatedData = studentsData.map((s: any) => ({
        level: s.level || s.aiEstimatedLevel,
        mediaPrefs: s.mediaPrefs || [...(s.music_genres || []), ...(s.movie_genres || []), ...(s.reading_habits || [])],
        difficulties: s.difficulties || [],
        preferredMethods: s.preferredLearningMethods || s.preferred_learning_methods || [],
      }));

      const response = await fetch(geminiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: `You are an expert ESL curriculum designer for high schoolers. 
              Analyze these aggregated class data and provide a pedagogical report.
              Focus on media preferences, difficulties, preferred learning methods, CEFR levels, and Multiple Intelligences averages.
              CRITICAL: Write exactly in ${lang === 'pt' ? 'Portuguese' : 'English'}.
              Return ONLY a JSON object with fields: overallSummary, recommendedTopics (array), teachingStrategies (array), struggleAreas (array).
              
              Class Multiple Intelligences Averages (out of 8 max):
              ${JSON.stringify(miAveragesMap)}

              Class Aggregated Profile Data:
              ${JSON.stringify(aggregatedData)}`
            }]
          }],
          generation_config: {
            response_mime_type: "application/json"
          }
        })
      });

      const result = await response.json();
      if (!response.ok || !result.candidates?.[0]) {
        console.error("Gemini Error (Insights):", JSON.stringify(result));
        throw new Error(result.error?.message || "Gemini returned an error for Class Insights");
      }
      const aiText = result.candidates[0].content.parts[0].text;
      const content = extractJSON(aiText);

      return new Response(JSON.stringify({ success: true, ...content }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    if (action === 'grade_submission') {
      const { studentLevel, instructions, content: studentContent, lang } = body;

      const response = await fetch(geminiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: `You are an English teacher grading an assignment. The student's current English level is ${studentLevel}. 
              Be fair, encouraging, and adjust your expectations based on their level.
              
              Assignment Instructions: "${instructions}"
              Student's Answer: "${studentContent}"
              
              Provide a suggested score (0 to 100) and brief, encouraging feedback explaining the grade and pointing out 1 area for improvement.
              CRITICAL: Write the feedback exactly in ${lang === 'pt' ? 'Portuguese' : 'English'}.
              Return ONLY a JSON object: { "score": number, "feedback": "string" }`
            }]
          }],
          generation_config: {
            response_mime_type: "application/json"
          }
        })
      });

      const result = await response.json();
      if (!response.ok || !result.candidates?.[0]) {
        console.error("Gemini Error (Grading):", JSON.stringify(result));
        throw new Error(result.error?.message || "Gemini returned an error for Grading");
      }
      const aiText = result.candidates[0].content.parts[0].text;
      const content = extractJSON(aiText);

      return new Response(JSON.stringify({ success: true, ...content }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    if (action === 'generate_activity') {
      const { topic, type, level, lang } = body; // type: 'MATCHING' | 'ORDERING' | 'GAP_FILL'

      let prompt = '';
      if (type === 'MATCHING') {
        prompt = `Generate a "Matching Pairs" activity for English students at ${level} level.
        Topic: "${topic}"
        
        Generate exactly 8 pairs of items that are related (e.g., Word <-> Definition, Word <-> Synonym, or Word <-> Translation).
        
        CRITICAL RULES:
        1. Pairs must be ONE-TO-ONE. Do not use items that could plausibly match with multiple options.
        2. Descriptions/Definitions must be distinct enough to avoid confusion.
        
        CRITICAL OUTPUT FORMAT (JSON ONLY):
        {
          "pairs": [
            { "item1": "Word/Phrase", "item2": "Matching Definition/Translation" }
          ]
        }
        Write any definitions/translations in ${lang === 'pt' ? 'Portuguese' : 'English'}.`;
      } else if (type === 'ORDERING') {
        prompt = `Generate a "Sentence Ordering" activity for English students at ${level} level.
        Topic: "${topic}"
        
        Generate exactly 5 sentences related to the topic.
        
        CRITICAL RULES:
        1. Sentences MUST be unambiguous. Hand-pick sentences where the subject and object CANNOT be swapped logically. 
           (e.g., Avoid "He met him". Use "The doctor met the patient" or "I ate the apple").
        2. Do not use sentences where multiple word orders are grammatically correct but have different meanings (like "She called me" vs "I called her") unless the words make it impossible to swap (e.g. using case-specific pronouns if useful, but better to use distinct nouns).
        
        CRITICAL OUTPUT FORMAT (JSON ONLY):
        {
          "sentences": [
            { 
              "correct": "The full correct sentence.", 
              "scrambled": ["list", "of", "shuffled", "words"] 
            }
          ]
        }`;
      } else if (type === 'GAP_FILL') {
        prompt = `Generate a "Fill in the Blanks" activity for English students at ${level} level.
        Topic: "${topic}"
        
        Generate exactly 5 sentences with a missing keyword.
        
        CRITICAL OUTPUT FORMAT (JSON ONLY):
        {
          "sentences": [
            { 
              "sentence": "The cat sat on the _____.", 
              "missingWord": "mat",
              "options": ["mat", "bat", "hat", "fat"] 
            }
          ]
        }`;
      } else {
        throw new Error('Invalid activity type');
      }

      const response = await fetch(geminiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generation_config: { response_mime_type: "application/json" }
        })
      });

      const result = await response.json();
      if (!response.ok || !result.candidates?.[0]) {
        throw new Error(result.error?.message || "Gemini Error");
      }
      const content = extractJSON(result.candidates[0].content.parts[0].text);
      return new Response(JSON.stringify({ success: true, ...content }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    if (action === 'generate_quiz') {
      const { source_text, question_count = 5, lang, student_level } = body;

      const response = await fetch(geminiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: `You are an expert ESL teacher. Generate a high-quality quiz based on the following source material or topic.
              
              Source/Topic: "${source_text}"
              Target Level: ${student_level || 'High School English'}
              Number of Questions: ${question_count}
              
              CRITICAL INSTRUCTIONS:
              1. Generate EXACTLY ${question_count} multiple-choice questions.
              2. Each question must have 4 options (A, B, C, D).
              3. Provide the correct answer index (0-3).
              4. Ensure questions are pedagogical and relevant to the source material.
              5. Write everything in ${lang === 'pt' ? 'Portuguese' : 'English'}.
              
              Return ONLY a JSON object:
              {
                "questions": [
                  {
                    "question": "Question text?",
                    "options": ["Option 0", "Option 1", "Option 2", "Option 3"],
                    "answer": 0
                  }
                ]
              }`
            }]
          }],
          generation_config: { response_mime_type: "application/json" }
        })
      });

      const result = await response.json();
      if (!response.ok || !result.candidates?.[0]) {
        console.error("Gemini Error (Quiz):", JSON.stringify(result));
        throw new Error(result.error?.message || "Gemini returned an error for Quiz Generation");
      }
      const aiText = result.candidates[0].content.parts[0].text;
      const content = extractJSON(aiText);

      return new Response(JSON.stringify({ success: true, ...content }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    if (action === 'suggest_activity') {
      const { report, lang } = body;

      const response = await fetch(geminiUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: `Based on this class report, suggest an English activity in ${lang === 'pt' ? 'Portuguese' : 'English'}.
              Return JSON:
              { "title": "...", "instructions": "...", "type": "TEXT"|"QUIZ"|"VIDEO" }
              Report: ${JSON.stringify(report)}`
            }]
          }],
          generation_config: { response_mime_type: "application/json" }
        })
      });

      const result = await response.json();
      if (!response.ok || !result.candidates?.[0]) {
        console.error("Gemini Error (Suggest):", JSON.stringify(result));
        throw new Error(result.error?.message || "Gemini returned an error for Suggestions");
      }
      const aiText = result.candidates[0].content.parts[0].text;
      const content = extractJSON(aiText);

      return new Response(JSON.stringify({ success: true, ...content }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    // Existing actions below...
    if (action === 'generate_weekly_plan') {
      const activeOpenAIKey = await getOpenAIKey();
      if (!activeOpenAIKey) throw new Error('OpenAI API Key is required');

      const userProfile = await getProfile();
      if (!userProfile) throw new Error('User profile required for this action');

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
          'Authorization': `Bearer ${activeOpenAIKey}`,
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
              The student is interested in: ${Array.isArray(userInterests) ? userInterests.join(', ') : 'general topics'}.

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
      if (aiResult.error) {
        throw new Error(`OpenAI Error: ${aiResult.error.message}`);
      }
      const planData = JSON.parse(aiResult.choices[0].message.content);

      // 3. Save to Database
      // Create Weekly Plan
      const { data: plan, error: planError } = await supabase
        .from('weekly_plans')
        .insert({
          user_id: userProfile.id, // Use the resolved profile ID
          week_start: planData.week_start,
          level: planData.level,
          focus: planData.focus,
          logic: planData.logic
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

    if (action === 'generate_flashcards') {
      const activeOpenAIKey = await getOpenAIKey();
      if (!activeOpenAIKey) throw new Error('OpenAI API Key is required');

      const userProfile = await getProfile();
      const level = userProfile?.level || 'B1';

      if (!topic) throw new Error('Topic is required for flashcard generation');
      const cardCount = config?.card_count || 10;

      console.log(`Generating ${cardCount} flashcards for ${userProfile.name} on topic: ${topic}`);

      const FLASHCARD_PROMPT = `You are an expert ESL (English as a Second Language) teacher. 
      Generate ${cardCount} high-quality, pedagogical flashcards for a student at ${level} level.
      Topic: ${topic}
      
      CRITICAL INSTRUCTIONS for Content:
      1. FRONT: The word, idiom, or phrase in English.
      2. BACK: DO NOT just put a translation. You MUST provide:
         - A clear, simple definition or Portuguese translation in parentheses.
         - 1 or 2 REAL-WORLD EXAMPLE SENTENCES using the term in context.
         - Highlight the usage of the term.
      3. EXPLANATION: A brief tip about pronunciation, common mistakes, or cultural context.

      Respond ONLY with a valid JSON in this format:
      {
        "flashcards": [
          {
            "front": "Term in English",
            "back": "(Translation) \n\nExample 1: ... \nExample 2: ...",
            "explanation": "Brief pedagogical tip"
          }
        ]
      }`;

      const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${activeOpenAIKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [
            { role: 'system', content: FLASHCARD_PROMPT }
          ],
          response_format: { type: "json_object" }
        })
      });

      const aiResult = await openaiResponse.json();
      if (aiResult.error) {
        throw new Error(`OpenAI Error: ${aiResult.error.message}`);
      }
      const flashcardsData = JSON.parse(aiResult.choices[0].message.content).flashcards;

      return new Response(
        JSON.stringify({ success: true, flashcards: flashcardsData }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'generate_task_content') {
      const activeOpenAIKey = await getOpenAIKey();
      if (!activeOpenAIKey) throw new Error('OpenAI API Key is required');

      const userProfile = await getProfile();
      if (!userProfile) throw new Error('User profile required for this action');

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
          'Authorization': `Bearer ${activeOpenAIKey}`,
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
              - Student Interests: ${Array.isArray(userInterests) ? userInterests.join(', ') : ''}

              CRITICAL INSTRUCTIONS:
              - If the skill is "writing":
                - You MUST provide a specific "Topic" or "Scenario" for the student to write about.
                - "practice_prompt" MUST be the actual writing instruction (e.g. "Write an email to...").
                - "questions" MUST be an empty array [].
                - "explanation" should focus on tips for this specific writing type (e.g. formal email structure).
              - If the skill is "reading":
                - You MUST provide the FULL text to read (150-600 words depending on level).
                - The text topic MUST be related to one of the student's interests.
                - For READING: Alternate between "Real World News/Articles" usage and "Short Stories/Fiction".
                - QUESTIONS: You MUST generate EXACTLY 10 multiple-choice questions for reading comprehension.
                - VOCABULARY: Extract 5-8 important words/phrases from the text with definitions and context.
              - If the skill is NOT "reading" AND NOT "writing":
                - Provide 3-5 questions.
              - Provide an "explanation", "examples" (array), a "practice_prompt".
              
              Respond ONLY with a valid JSON in the following format:

              FOR READING TASKS:
              {
                "title": "${task.content?.title}",
                "reading_text": "The complete reading passage (150-600 words)",
                "vocabulary": [
                  {
                    "word": "important word or phrase",
                    "definition": "clear definition",
                    "context": "sentence from the text where it appears"
                  }
                ],
                "explanation": "Brief summary or learning objectives for this reading",
                "practice_prompt": "Post-reading task instruction",
                "questions": [
                  {
                    "question": "Comprehension question?",
                    "options": ["A", "B", "C", "D"],
                    "correct_ans_index": 0
                  }
                ]
              }

              FOR OTHER TASKS:
              {
                "title": "${task.content?.title}",
                "explanation": "Deep theoretical explanation",
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
      if (aiResult.error) {
        throw new Error(`OpenAI Error: ${aiResult.error.message}`);
      }
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

    if (action === 'evaluate_week') {
      const activeOpenAIKey = await getOpenAIKey();
      if (!activeOpenAIKey) throw new Error('OpenAI API Key is required');

      const userProfile = await getProfile();
      if (!userProfile) throw new Error('User profile required for this action');

      if (!plan_id) throw new Error('Week Plan ID is required');

      // 1. Fetch Plan & Tasks
      const { data: plan, error: planError } = await supabase
        .from('weekly_plans')
        .select(`
          *,
          daily_tasks (*)
        `)
        .eq('id', plan_id)
        .single();

      if (planError || !plan) throw new Error(`Plan not found: ${planError?.message || ''}`);

      const tasks = plan.daily_tasks;
      const completedTasks = tasks.filter((t: any) => t.completed).length;
      const totalTasks = tasks.length;

      const userLevel = userProfile.level || 'A1';
      const userGoal = userProfile.goal || 'General English';

      // 2. Prepare Prompt
      const FEEDBACK_PROMPT = `You are a strict but encouraging English Tutor.
      Analyze the student's weekly performance and provide feedback.
      
      Student Level: ${userLevel}
      Goal: ${userGoal}
      Performance: Completed ${completedTasks}/${totalTasks} tasks.
      Tasks Log:
      ${tasks.map((t: any) => `- Day ${t.day_of_week} (${t.skill}): ${t.completed ? 'COMPLETED' : 'MISSED'}`).join('\n')}

      Generate a structured JSON response:
      {
        "score": 85, // 0-100 based on completion and consistency
        "feedback": "2-3 sentences of qualitative feedback. Be specific.",
        "recommendations": ["Action item 1", "Action item 2", "Action item 3"]
      }`;

      // 3. Call OpenAI
      const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${activeOpenAIKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [
            { role: 'system', content: 'You are an English Learning Assessment AI.' },
            { role: 'user', content: FEEDBACK_PROMPT }
          ],
          response_format: { type: "json_object" }
        })
      });

      const aiResult = await openaiResponse.json();
      if (aiResult.error) {
        throw new Error(`OpenAI Error: ${aiResult.error.message}`);
      }
      const evaluation = JSON.parse(aiResult.choices[0].message.content);

      // 4. Save Evaluation
      const { error: updateError } = await supabase
        .from('weekly_plans')
        .update({ evaluation: evaluation })
        .eq('id', plan_id);

      if (updateError) throw updateError;

      return new Response(
        JSON.stringify({ success: true, evaluation: evaluation }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'conversation_handler') {
      const activeOpenAIKey = await getOpenAIKey();
      if (!activeOpenAIKey) throw new Error('OpenAI API Key is required');

      const { message, history } = body;
      if (!message) throw new Error('Message is required');

      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${activeOpenAIKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [
            { role: 'system', content: 'You are an encouraging English learning assistant.' },
            ...history,
            { role: 'user', content: message }
          ],
        })
      });

      const aiResult = await response.json();
      if (aiResult.error) {
        throw new Error(`OpenAI Error: ${aiResult.error.message}`);
      }
      const content = aiResult.choices[0].message.content;

      return new Response(
        JSON.stringify({ success: true, reply: content }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (action === 'detect_recovery_mode') {
      const userProfile = await getProfile();
      if (!userProfile) throw new Error('User profile required for this action');

      // Analyze quiz performance for recovery mode
      const { data: quizzes, error: quizError } = await supabase
        .from('quizzes')
        .select('*')
        .eq('user_id', userProfile.id)
        .order('created_at', { ascending: false })
        .limit(5);

      let recoveryMode = false;
      if (quizzes && quizzes.length >= 3) {
        const avgScore = quizzes.reduce((sum: number, q: any) => sum + q.score, 0) / quizzes.length;
        if (avgScore < 60) recoveryMode = true;
      }

      return new Response(
        JSON.stringify({ success: true, recovery_mode: recoveryMode }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    if (action === 'recommend_youtube_content') {
      const userProfile = await getProfile();
      if (!userProfile) throw new Error('User profile required for this action');

      const userLevel = userProfile.level || 'A1';
      const userInterests = userProfile.interests || ['General English'];

      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${openai_key}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [
            { role: 'system', content: 'You are an educational content curator.' },
            {
              role: 'user', content: `Recommend 3 YouTube videos for an English student at level ${userLevel} interested in ${userInterests.join(', ')}. 
            
            Return ONLY a JSON object with this key:
            {
              "recommendations": [
                { "title": "video title", "url": "youtube link", "description": "why it is good", "thumbnail": "image url" }
              ]
            }` }
          ],
          response_format: { type: "json_object" }
        })
      });

      const aiResult = await response.json();
      const recommendations = JSON.parse(aiResult.choices[0].message.content).recommendations || [];

      return new Response(
        JSON.stringify({ success: true, recommendations }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // --- CRUD using Service Role (Bypassing RLS) ---
    // Added for Mobile App compatibility, using targetUserId

    if (action === 'generate_essay_outline') {
      const activeOpenAIKey = await getOpenAIKey();
      if (!activeOpenAIKey) throw new Error('OpenAI API Key is required');

      const { topic } = body;
      if (!topic) throw new Error('Topic is required for outline generation');

      const OUTLINE_PROMPT = `You are an expert writing coach.
      Generate a comprehensive essay outline for the topic: "${topic}".
      
      Structure:
      1. Introduction (Hook, Background, Thesis Statement)
      2. Body Paragraph 1 (Main Point, Evidence/Example)
      3. Body Paragraph 2 (Main Point, Evidence/Example)
      4. Body Paragraph 3 (Main Point, Evidence/Example)
      5. Conclusion (Restate Thesis, Summary, Final Thought)

      Output ONLY the outline text in a clear, readable Markdown format. Do not write the full essay, just the structure and key points to help the student start writing.`;

      const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${activeOpenAIKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4o-mini',
          messages: [
            { role: 'system', content: OUTLINE_PROMPT }
          ],
        })
      });

      const aiResult = await openaiResponse.json();
      if (aiResult.error) throw new Error(`OpenAI Error: ${aiResult.error.message}`);
      const outline = aiResult.choices[0].message.content;

      return new Response(
        JSON.stringify({ success: true, outline: outline }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'analyze_essay') {
      const activeOpenAIKey = await getOpenAIKey();
      if (!activeOpenAIKey) throw new Error('OpenAI API Key is required');

      const { essay_content, essay_type, essay_topic } = body

      const ESSAY_PROMPT = `You are an expert English writing tutor. Analyze the following essay and provide comprehensive feedback.
      
      Essay Type: ${essay_type || 'General Essay'}
      Topic: ${essay_topic || 'Not specified'}
      Content: "${essay_content}"

      Perform the following tasks:
      1. Identify grammar, spelling, and punctuation errors.
      2. Provide stylistic suggestions for better flow, clarity, and vocabulary.
      3. Give a detailed score (0-100) breakdown (Overall, Grammar, Style, Vocabulary, Structure).
      4. Suggest citations if claims need backing (optional).

      Respond ONLY with valid JSON in this structure:
      {
        "grammar_errors": [
          {
            "text": "incorrect text snippet",
            "correction": "corrected text",
            "type": "grammar|spelling|punctuation|other",
            "explanation": "why it is wrong",
            "startIndex": 0, 
            "endIndex": 0
          }
        ],
        "suggestions": [
          {
            "text": "original text",
            "suggestion": "better alternative",
            "type": "style|clarity|vocabulary|flow",
            "explanation": "why this is better",
            "startIndex": 0,
            "endIndex": 0
          }
        ],
        "score": {
          "overall": 85,
          "grammar": 80,
          "style": 90,
          "vocabulary": 85,
          "structure": 80,
          "feedback": "General feedback paragraph..."
        }
      }
      
      IMPORTANT: 'startIndex' and 'endIndex' must strictly match the character positions in the provided content string.
      `;

      console.log(`Analyzing essay...`)

      const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${activeOpenAIKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: 'gpt-4o',
          messages: [{ role: "system", content: ESSAY_PROMPT }],
          response_format: { type: "json_object" }
        })
      })

      const aiResult = await openaiResponse.json();
      if (aiResult.error) throw new Error(`OpenAI Error: ${aiResult.error.message}`);
      const aiResponse = aiResult.choices[0].message.content;

      const parsedResponse = JSON.parse(aiResponse)

      return new Response(
        JSON.stringify(parsedResponse),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      )
    }

    if (action === 'create_essay') {
      const { title, content, type, topic, prompt } = body;
      if (!title || !content) throw new Error('Title and Content are required');

      const { data: essay, error } = await supabase
        .from('user_essays')
        .insert({
          user_id: targetUserId, // UPDATED: Using targetUserId
          title,
          content,
          type: type || 'essay',
          topic,
          prompt,
          suggestions: [],
          grammar_errors: [],
          score: null
        })
        .select()
        .single();

      if (error) throw error;

      return new Response(
        JSON.stringify({ success: true, essay }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'get_essays') {
      const { data: essays, error } = await supabase
        .from('user_essays')
        .select('*')
        .eq('user_id', targetUserId) // UPDATED: Using targetUserId
        .order('updated_at', { ascending: false });

      if (error) throw error;

      return new Response(
        JSON.stringify({ success: true, essays }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'update_essay') {
      const { essay } = body;
      if (!essay || !essay.id) throw new Error('Valid essay object required');

      const { error } = await supabase
        .from('user_essays')
        .update({
          title: essay.title,
          content: essay.content,
          type: essay.type,
          topic: essay.topic,
          prompt: essay.prompt,
          suggestions: essay.suggestions,
          grammar_errors: essay.grammar_errors,
          score: essay.score,
          updated_at: new Date().toISOString()
        })
        .eq('id', essay.id)
        .eq('user_id', targetUserId); // UPDATED: Using targetUserId

      if (error) throw error;

      return new Response(
        JSON.stringify({ success: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (action === 'delete_essay') {
      const { essay_id } = body;
      if (!essay_id) throw new Error('Essay ID required');

      const { error } = await supabase
        .from('user_essays')
        .delete()
        .eq('id', essay_id)
        .eq('user_id', targetUserId); // UPDATED: Using targetUserId

      if (error) throw error;

      return new Response(
        JSON.stringify({ success: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

  } catch (error: any) {
    console.error("[ai-orchestrator] Global Error caught:", error.message, error.stack);
    return new Response(
      JSON.stringify({ success: false, error: error.message || 'Internal server error', details: error.stack }),
      {
        status: 200, // Return 200 to ensure client receives the JSON body
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    )
  }

  // Fallback for unhandled actions
  return new Response(
    JSON.stringify({ error: 'Unknown action' }),
    {
      status: 400,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json'
      }
    }
  )
})
