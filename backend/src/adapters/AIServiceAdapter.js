const config = require('../config/env');

class AIServiceAdapter {
  constructor() {
    this.simulateFailure = false;
  }

  async generateGroundedAnswer({ queryText, mergedContext, userContext }) {
    if (this.simulateFailure) {
      throw new Error('AI LLM service failed to generate a response.');
    }

    const hasContext = Array.isArray(mergedContext) && mergedContext.length > 0;

    if (!config.mockMode && config.openaiApiKey) {
      const systemPrompt = [
        'You are AskUni, the official AI assistant for Amity University Rajasthan (Jaipur).',
        'Answer strictly using ONLY the provided institutional context.',
        'If the provided context does not contain the answer, clearly state that the information is unavailable in official records and suggest contacting the Amity University Rajasthan Academic / Admissions Office (+91-1426-405555 or admissions@jpr.amity.edu).',
        'Never fabricate dates, fees, or policies.'
      ].join(' ');

      const contextBlock = hasContext
        ? mergedContext.map((c, i) => `[${i + 1}] (${c.source} - ${c.title}): ${c.text}`).join('\n')
        : 'NO MATCHING CONTEXT FOUND.';

      const resp = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${config.openaiApiKey}`
        },
        body: JSON.stringify({
          model: config.openaiModel,
          temperature: 0.1,
          messages: [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: `Context:\n${contextBlock}\n\nStudent Question: ${queryText}` }
          ]
        })
      });

      if (!resp.ok) {
        throw new Error(`OpenAI Chat API returned HTTP ${resp.status}`);
      }
      const data = await resp.json();
      return {
        text: data.choices[0].message.content.trim(),
        grounded: hasContext,
        sourceCount: mergedContext.length
      };
    }

    // Deterministic grounded mock synthesis
    if (!hasContext) {
      return {
        text: 'I could not find verified information about that in Amity University Rajasthan\'s current circulars, FAQs, or handbooks. Please contact the Amity University Rajasthan Administrative / Academic Office at +91-1426-405555 or visit Block-A Student Facilitation Desk for official assistance.',
        grounded: false,
        sourceCount: 0
      };
    }

    const topItems = mergedContext.slice(0, 2);
    const primary = topItems[0];
    const greeting = userContext && userContext.isAuthenticated && userContext.name
      ? `Hello ${userContext.name}, based on official Amity University Rajasthan records: `
      : 'Based on official Amity University Rajasthan records: ';

    let synthesized = `${greeting}${primary.text}`;
    if (topItems.length > 1 && topItems[1].text !== primary.text) {
      synthesized += ` Additionally (${topItems[1].title}): ${topItems[1].text}`;
    }

    return {
      text: synthesized,
      grounded: true,
      sourceCount: topItems.length
    };
  }

  isHealthy() {
    return !this.simulateFailure;
  }
}

module.exports = { AIServiceAdapter };