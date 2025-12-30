# Momentum AI Integration - Quick Start Guide

## 🚀 What's New

Your Momentum app now has **real AI integration** using Groq! Here's what changed:

### 1. Real AI-Generated Plans (No More Mock Data!)
- Users get personalized 12-month plans based on their actual vision
- AI creates specific, actionable daily tasks
- Plans adapt to user's experience level and available time

### 2. AI Task Assistant
- Interactive chat to help with any task
- Click "Ask AI Assistant for Help" in any task detail
- Get specific guidance, tips, and motivation

### 3. AI Microstep Generator
- Breaks down tasks into smaller steps on demand
- Click "Generate" next to Microsteps in task detail
- Perfect for when users feel stuck

### 4. Personalized Celebration Messages
- AI generates encouraging messages when tasks are completed
- Adapts to user's chosen AI personality
- More meaningful than static messages

## 🔧 How to Use

### For Onboarding:
```swift
// The AI integration is automatic!
// When a user completes onboarding:
1. They enter their vision (e.g., "Launch a consulting agency")
2. Answer questionnaire
3. AI generates complete plan (3-5 seconds)
4. User sees first 3 tasks immediately
```

### For Task Assistance:
```swift
// In TodayView -> Tap Task -> "Ask AI Assistant for Help"
// Opens AIAssistantView with conversational interface
// User can ask questions and get contextual help
```

### For Microsteps:
```swift
// In TodayView -> Tap Task -> See "Generate" button
// AI creates 3-5 specific action steps
// Displayed as bullet points
```

## ⚙️ Configuration

### Your Groq API Key
Located in: `Momentum/Config.swift`
```swift
static let groqAPIKey = "YOUR_GROQ_API_KEY_HERE"
```

### Model Settings
```swift
static let groqModel = "llama-3.3-70b-versatile"  // Fast and capable
static let groqAPIBaseURL = "https://api.groq.com/openai/v1"
```

## 📁 New Files

### Core AI Service
- **`Momentum/Services/GroqService.swift`**
  - Main AI integration service
  - All AI functions live here
  - Handles API calls, error handling, JSON parsing

### UI Components
- **`Momentum/Views/Components/AIAssistantView.swift`**
  - Chat interface for task help
  - Message bubbles, suggested questions
  - Conversation history

### Configuration
- **`Momentum/Config.swift`**
  - API keys and settings
  - **⚠️ Already in .gitignore - DO NOT COMMIT!**

## 🧪 Testing Your Changes

### 1. Test Onboarding with AI
```
1. Run the app
2. If already onboarded, reset in ProfileView (or delete app)
3. Go through onboarding
4. Enter a unique vision (e.g., "Build a SaaS product")
5. Complete questionnaire
6. Watch the AI generate your plan!
7. Check that tasks are relevant to your vision
```

### 2. Test AI Assistant
```
1. Open Today view
2. Tap any task
3. Click "Ask AI Assistant for Help"
4. Try asking:
   - "How do I get started?"
   - "What should I focus on first?"
   - "Any tips for this task?"
5. Verify responses are relevant and helpful
```

### 3. Test Microstep Generation
```
1. Find a task without microsteps
2. Open task detail
3. Click "Generate" next to Microsteps
4. Wait 2-3 seconds
5. Verify 3-5 specific steps appear
```

### 4. Test Personalized Messages
```
1. Complete any task
2. Watch for celebration toast
3. Message should update within 1-2 seconds with AI-generated text
4. Should match AI personality (currently always "energetic")
```

## ⚠️ Important Notes

### Security
- **Config.swift is gitignored** - Your API key won't be committed
- For production, use environment variables or Supabase Edge Functions
- Never expose API keys in client-side code for production apps

### Error Handling
All AI features have fallbacks:
- Onboarding → Falls back to mock data
- Task help → Shows error message in chat
- Microsteps → Fails silently, can retry
- Messages → Uses default personality messages

### Performance
- AI calls are async and non-blocking
- Loading states shown during generation
- Most responses return in 1-5 seconds
- Groq is very fast compared to other AI APIs

## 🐛 Troubleshooting

### If AI features aren't working:

1. **Check API Key**
   - Verify `Config.swift` exists
   - Check key is correct: `YOUR_GROQ_API_KEY_HERE`

2. **Check Console Logs**
   - Look for "Error generating plan:"
   - Look for "Error getting AI help:"
   - Check for network errors

3. **Test API Key Manually**
   ```bash
   curl https://api.groq.com/openai/v1/models \
     -H "Authorization: Bearer YOUR_GROQ_API_KEY_HERE"
   ```

4. **Verify Internet Connection**
   - AI features require network access
   - Check simulator/device has connectivity

### Common Issues:

**"Config.swift not found"**
- File might be gitignored
- Create it manually with the API key

**"Invalid API response"**
- Check Groq API status
- Verify model name is correct
- Check request format in GroqService.swift

**"Tasks generated but not relevant"**
- Adjust prompts in GroqService.swift
- Add more context to questionnaire answers
- Increase temperature for more creativity (or decrease for consistency)

## 🎯 Next Steps

### Recommended Improvements:

1. **Add Error UI**
   - Show user-friendly error messages
   - Retry buttons for failed AI calls
   - Better loading states

2. **Implement Dynamic Questionnaire**
   - Use `generateOnboardingQuestions()` function
   - Make questions adapt based on vision type
   - Currently questionnaire is static

3. **Add Caching**
   - Cache common question responses
   - Store generated plans locally
   - Reduce API calls = lower costs

4. **Production Security**
   - Move API key to Supabase Edge Function
   - Proxy all AI requests through backend
   - Rate limit API calls per user

5. **Enhanced Features**
   - Re-planning based on progress
   - AI-powered insights in Stats view
   - Smart task scheduling
   - Voice input for visions

## 📊 Monitoring

### Track these metrics:
- API call success rate
- Average response time
- User engagement with AI features
- Most common questions in assistant
- Task completion rate with vs without AI help

### Cost Management:
- Monitor token usage via Groq dashboard
- Set up usage alerts
- Cache responses when possible
- Consider rate limiting

## 🎉 You're All Set!

Your Momentum app now has powerful AI features that make goal achievement more personalized and effective. Users will get:

✅ Custom plans in seconds
✅ Intelligent task assistance
✅ Breakdown of overwhelming tasks
✅ Encouraging, personalized messages

**Build and test the app to see the AI in action!**

---

**Questions or Issues?**
Check the main documentation: `AI_INTEGRATION_SUMMARY.md`
