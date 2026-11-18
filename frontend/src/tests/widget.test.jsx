import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { describe, test, expect, vi, beforeEach } from 'vitest';
import WidgetContainer from '../components/WidgetContainer';
import { askUniApi } from '../services/api';

vi.mock('../services/api', () => ({
  askUniApi: {
    createAnonymousSession: vi.fn(),
    login: vi.fn(),
    fetchFaqs: vi.fn(),
    sendQuery: vi.fn()
  }
}));

const MOCK_FAQS = [
  {
    faqId: 'faq_exam_01',
    category: 'Examinations',
    question: 'When do Odd Semester End-Term Examinations begin?',
    answerText: 'Odd Semester End-Term Theory Examinations begin on December 4, 2026.'
  },
  {
    faqId: 'faq_fee_01',
    category: 'Fees & Finance',
    question: 'What is the annual tuition fee for B.Tech CSE?',
    answerText: 'Tuition fee is INR 1,86,000 per semester.'
  }
];

beforeEach(() => {
  vi.clearAllMocks();
  askUniApi.fetchFaqs.mockResolvedValue({ success: true, faqs: MOCK_FAQS });
  askUniApi.createAnonymousSession.mockResolvedValue({
    success: true,
    token: 'mock_anon_jwt',
    sessionId: 'sess_frontend_101',
    user: { userId: 'anon_user_1', widgetId: 'w_anon_user_1', role: 'anonymous' }
  });
});

describe('Module 1: Frontend AskUni Widget Interactions (TC-01 to TC-12)', () => {
  test('TC-01 opens chatbot dialog when floating launcher button is clicked', async () => {
    render(<WidgetContainer />);
    const launcher = screen.getByTestId('askuni-launcher');
    expect(launcher).toBeInTheDocument();

    fireEvent.click(launcher);
    await waitFor(() => {
      expect(screen.getByTestId('askuni-dialog')).toBeInTheDocument();
    });
  });

  test('TC-02 initializes widget state to awaiting input and loads Smart FAQs', async () => {
    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));

    await waitFor(() => {
      expect(screen.getByTestId('widget-state-badge')).toHaveTextContent('awaiting input');
      expect(askUniApi.fetchFaqs).toHaveBeenCalled();
    });
  });

  test('TC-03 submits valid English query and transitions to response displayed', async () => {
    askUniApi.sendQuery.mockResolvedValueOnce({
      success: true,
      data: {
        responseId: 'rs_01',
        sessionId: 'sess_frontend_101',
        generatedText: 'Tuition fee is INR 1,86,000 per semester.',
        translatedText: 'Tuition fee is INR 1,86,000 per semester.',
        targetLanguage: 'en',
        grounded: true,
        sources: [{ source: 'SmartFAQ', category: 'Fees & Finance' }],
        timestamp: new Date().toISOString()
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('chat-input')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), {
      target: { value: 'What is the B.Tech CSE tuition fee?' }
    });
    fireEvent.click(screen.getByTestId('chat-send-btn'));

    await waitFor(() => {
      expect(screen.getByText(/1,86,000 per semester/i)).toBeInTheDocument();
      expect(screen.getByTestId('widget-state-badge')).toHaveTextContent('response displayed');
    });
  });

  test('TC-04 blocks empty or whitespace-only queries with visible validation message', async () => {
    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('chat-input')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: '    ' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));

    expect(screen.getByTestId('validation-error')).toHaveTextContent(/empty or whitespace/i);
    expect(askUniApi.sendQuery).not.toHaveBeenCalled();
  });

  test('TC-05 submits Hindi query and displays localized Hindi assistant response', async () => {
    askUniApi.sendQuery.mockResolvedValueOnce({
      success: true,
      data: {
        responseId: 'rs_hi_01',
        sessionId: 'sess_frontend_101',
        generatedText: 'Theory exams start Dec 4, 2026.',
        translatedText: '[à¤¹à¤¿à¤¨à¥à¤¦à¥€ à¤…à¤¨à¥à¤µà¤¾à¤¦] à¤¸à¥‡à¤®à¥‡à¤¸à¥à¤Ÿà¤° à¤…à¤‚à¤¤ à¤¸à¤¿à¤¦à¥à¤§à¤¾à¤‚à¤¤ à¤ªà¤°à¥€à¤•à¥à¤·à¤¾à¤à¤‚ 4 à¤¦à¤¿à¤¸à¤‚à¤¬à¤° 2026 à¤¸à¥‡ à¤¶à¥à¤°à¥‚ à¤¹à¥‹à¤‚à¤—à¥€à¥¤',
        targetLanguage: 'hi',
        grounded: true,
        timestamp: new Date().toISOString()
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('chat-input')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: 'à¤ªà¤°à¥€à¤•à¥à¤·à¤¾ à¤•à¤¬ à¤¶à¥à¤°à¥‚ à¤¹à¥‹à¤—à¥€?' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));

    await waitFor(() => {
      expect(screen.getByText(/à¤¹à¤¿à¤¨à¥à¤¦à¥€ à¤…à¤¨à¥à¤µà¤¾à¤¦/i)).toBeInTheDocument();
    });
  });

  test('TC-06 selects a question from Smart FAQ dropdown and submits it immediately', async () => {
    askUniApi.sendQuery.mockResolvedValueOnce({
      success: true,
      data: {
        responseId: 'rs_faq_01',
        sessionId: 'sess_frontend_101',
        translatedText: 'Odd Semester End-Term Theory Examinations begin on December 4, 2026.',
        targetLanguage: 'en',
        grounded: true,
        timestamp: new Date().toISOString()
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('smart-faq-dropdown')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('smart-faq-dropdown'), {
      target: { value: 'When do Odd Semester End-Term Examinations begin?' }
    });

    await waitFor(() => {
      expect(askUniApi.sendQuery).toHaveBeenCalledTimes(1);
      expect(screen.getByText(/December 4, 2026/i)).toBeInTheDocument();
    });
  });

  test('TC-07 displays formatted ChatbotResponse with source attribution badges and timestamps', async () => {
    askUniApi.sendQuery.mockResolvedValueOnce({
      success: true,
      data: {
        responseId: 'rs_fmt_07',
        sessionId: 'sess_frontend_101',
        translatedText: 'BCS 522 Lab is held in Block-B Lab-204.',
        targetLanguage: 'en',
        grounded: true,
        sources: [{ source: 'PineconeVectorDB', category: 'Timetable & Labs' }],
        timestamp: new Date().toISOString()
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('chat-input')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: 'Where is BCS 522 lab?' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));

    await waitFor(() => {
      expect(screen.getByText(/PineconeVectorDB: Timetable & Labs/i)).toBeInTheDocument();
      expect(screen.getByText(/AskUni \(en\)/i)).toBeInTheDocument();
    });
  });

  test('TC-08 switches preferredLanguage selector and requests translation in target language', async () => {
    askUniApi.sendQuery.mockResolvedValueOnce({
      success: true,
      data: {
        responseId: 'rs_mr_08',
        sessionId: 'sess_frontend_101',
        translatedText: '[\u092e\u0930\u093e\u0920\u0940 \u092d\u093e\u0937\u093e\u0902\u0924\u0930] \u0935\u0938\u0924\u093f\u0917\u0943\u0939 \u0936\u0941\u0932\u094d\u0915 INR 1,10,000 \u092a\u094d\u0930\u0924\u093f \u0935\u0930\u094d\u0937 \u0906\u0939\u0947.',
        targetLanguage: 'mr',
        grounded: true,
        timestamp: new Date().toISOString()
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('language-selector')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('language-selector'), { target: { value: 'mr' } });
    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: 'Hostel fee?' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));

    await waitFor(() => {
      expect(askUniApi.sendQuery).toHaveBeenCalledWith(
        expect.objectContaining({ language: 'mr' }),
        expect.any(String)
      );
      expect(screen.getByText(/\u092e\u0930\u093e\u0920\u0940 \u092d\u093e\u0937\u093e\u0902\u0924\u0930/i)).toBeInTheDocument();
    });
  });

  test('TC-09 maintains same sessionId across multiple consecutive turns in a conversation', async () => {
    askUniApi.sendQuery
      .mockResolvedValueOnce({
        success: true,
        data: { responseId: 'rs_t1', sessionId: 'sess_frontend_101', translatedText: 'Turn 1 answer', targetLanguage: 'en' }
      })
      .mockResolvedValueOnce({
        success: true,
        data: { responseId: 'rs_t2', sessionId: 'sess_frontend_101', translatedText: 'Turn 2 answer', targetLanguage: 'en' }
      });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('chat-input')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: 'First question' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));
    await waitFor(() => expect(screen.getByText('Turn 1 answer')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: 'Second question' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));
    await waitFor(() => expect(screen.getByText('Turn 2 answer')).toBeInTheDocument());

    expect(askUniApi.sendQuery.mock.calls[0][0].sessionId).toBe('sess_frontend_101');
    expect(askUniApi.sendQuery.mock.calls[1][0].sessionId).toBe('sess_frontend_101');
  });

  test('TC-10 minimizes and closes the chatbot widget cleanly', async () => {
    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('askuni-dialog')).toBeInTheDocument());

    fireEvent.click(screen.getByTestId('askuni-minimize'));
    expect(screen.queryByTestId('askuni-dialog')).not.toBeInTheDocument();
    expect(screen.getByTestId('askuni-launcher')).toHaveTextContent('Resume AskUni');

    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('askuni-dialog')).toBeInTheDocument());

    fireEvent.click(screen.getByTestId('askuni-close'));
    expect(screen.queryByTestId('askuni-dialog')).not.toBeInTheDocument();
    expect(screen.getByTestId('askuni-launcher')).toHaveTextContent('AskUni Chat');
  });

  test('TC-11 records both user and assistant messages in the conversation log', async () => {
    askUniApi.sendQuery.mockResolvedValueOnce({
      success: true,
      data: {
        responseId: 'rs_hist_11',
        sessionId: 'sess_frontend_101',
        translatedText: 'Anti-ragging helpline is 1800-180-5522.',
        targetLanguage: 'en'
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByTestId('chat-input')).toBeInTheDocument());

    fireEvent.change(screen.getByTestId('chat-input'), { target: { value: 'Anti ragging helpline?' } });
    fireEvent.click(screen.getByTestId('chat-send-btn'));

    await waitFor(() => {
      expect(screen.getAllByTestId('chat-bubble-user')).toHaveLength(1);
      expect(screen.getAllByTestId('chat-bubble-assistant')).toHaveLength(1);
    });
  });

  test('TC-12 authenticates optional student login session while preserving anonymous fallback', async () => {
    askUniApi.login.mockResolvedValueOnce({
      success: true,
      token: 'stu_jwt_token',
      sessionId: 'sess_student_aarav',
      user: {
        userId: 'stu_a50105224001',
        widgetId: 'w_stu_a50105224001',
        name: 'Aarav Verma',
        enrollmentNo: 'A50105224001',
        program: 'B.Tech CSE'
      }
    });

    render(<WidgetContainer />);
    fireEvent.click(screen.getByTestId('askuni-launcher'));
    await waitFor(() => expect(screen.getByText('Student Login')).toBeInTheDocument());

    fireEvent.click(screen.getByText('Student Login'));
    fireEvent.click(screen.getByText('Authenticate Student Session'));

    await waitFor(() => {
      expect(screen.getByText(/Signed in: Aarav Verma/i)).toBeInTheDocument();
    });
  });
});