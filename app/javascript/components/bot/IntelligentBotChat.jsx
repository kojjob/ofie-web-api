// Intelligent Bot Chat Interface - Main Component
import React, { useState, useEffect, useRef, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import BotMessage from './BotMessage';
import UserMessage from './UserMessage';
import TypingIndicator from './TypingIndicator';
import SmartActions from './SmartActions';
import ConversationSuggestions from './ConversationSuggestions';
import BotHeader from './BotHeader';
import MessageInput from './MessageInput';

const IntelligentBotChat = ({ 
  conversationId, 
  user, 
  onConversationUpdate,
  isMinimized = false,
  onToggleMinimize 
}) => {
  const [messages, setMessages] = useState([]);
  const [isTyping, setIsTyping] = useState(false);
  const [suggestions, setSuggestions] = useState([]);
  const [smartActions, setSmartActions] = useState([]);
  const [isConnected, setIsConnected] = useState(false);
  const [conversationMetadata, setConversationMetadata] = useState(null);
  const [showFeedback, setShowFeedback] = useState(null);
  
  const messagesEndRef = useRef(null);
  const chatContainerRef = useRef(null);
  const wsRef = useRef(null);
  
  // WebSocket connection
  useEffect(() => {
    if (conversationId) {
      connectWebSocket();
    }
    
    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, [conversationId]);
  
  const connectWebSocket = useCallback(() => {
    const token = localStorage.getItem('authToken');
    const wsUrl = `ws://localhost:3000/cable?token=${token}`;
    
    wsRef.current = new WebSocket(wsUrl);
    
    wsRef.current.onopen = () => {
      setIsConnected(true);
      
      // Subscribe to conversation channel
      wsRef.current.send(JSON.stringify({
        command: 'subscribe',
        identifier: JSON.stringify({
          channel: 'ConversationChannel',
          conversation_id: conversationId
        })
      }));
    };
    
    wsRef.current.onmessage = (event) => {
      const data = JSON.parse(event.data);
      
      if (data.type) {
        handleWebSocketMessage(data);
      }
    };
    
    wsRef.current.onclose = () => {
      setIsConnected(false);
      // Attempt to reconnect after 3 seconds
      setTimeout(connectWebSocket, 3000);
    };
    
    wsRef.current.onerror = (error) => {
      console.error('WebSocket error:', error);
      setIsConnected(false);
    };
  }, [conversationId]);
  
  const handleWebSocketMessage = useCallback((data) => {
    switch (data.type) {
      case 'new_message':
      case 'bot_response':
        handleNewMessage(data.data);
        break;
      case 'typing_indicator':
        handleTypingIndicator(data.data);
        break;
      case 'conversation_metadata':
        setConversationMetadata(data.data);
        break;
      case 'conversation_suggestions':
        setSuggestions(data.data.suggestions);
        break;
      case 'property_recommendations':
        handlePropertyRecommendations(data.data);
        break;
      case 'followup_message':
        handleFollowupMessage(data.data);
        break;
      case 'bot_error':
        handleBotError(data.data);
        break;
    }
  }, []);
  
  const handleNewMessage = useCallback((messageData) => {
    const newMessage = messageData.message || messageData;
    
    setMessages(prev => {
      // Avoid duplicates
      if (prev.find(msg => msg.id === newMessage.id)) {
        return prev;
      }
      return [...prev, newMessage];
    });
    
    // Handle bot-specific data
    if (messageData.smart_actions) {
      setSmartActions(messageData.smart_actions);
    }
    
    if (messageData.conversation_suggestions) {
      setSuggestions(messageData.conversation_suggestions);
    }
    
    setIsTyping(false);
    scrollToBottom();
  }, []);
  
  const handleTypingIndicator = useCallback((data) => {
    if (data.user_id !== user.id) {
      setIsTyping(data.action === 'start');
    }
  }, [user.id]);
  
  const scrollToBottom = useCallback(() => {
    setTimeout(() => {
      messagesEndRef.current?.scrollIntoView({ 
        behavior: 'smooth',
        block: 'end'
      });
    }, 100);
  }, []);
  
  const sendMessage = useCallback(async (content, messageType = 'text') => {
    if (!content.trim() || !isConnected) return;
    
    // Send typing indicator
    wsRef.current?.send(JSON.stringify({
      command: 'message',
      identifier: JSON.stringify({
        channel: 'ConversationChannel',
        conversation_id: conversationId
      }),
      data: {
        action: 'send_message',
        message: content,
        message_type: messageType
      }
    }));
    
    // Clear suggestions when user sends a message
    setSuggestions([]);
  }, [conversationId, isConnected]);
  
  const handleSuggestionClick = useCallback((suggestion) => {
    sendMessage(suggestion);
  }, [sendMessage]);
  
  const handleSmartAction = useCallback(async (action) => {
    try {
      switch (action.type) {
        case 'quick_search':
          // Trigger property search
          sendMessage('Show me more properties like this');
          break;
        case 'save_search':
          // Save current search
          await saveCurrentSearch();
          break;
        case 'schedule_viewing':
          // Open viewing scheduler
          openViewingScheduler();
          break;
        default:
          sendMessage(action.label);
      }
    } catch (error) {
      console.error('Smart action failed:', error);
    }
  }, [sendMessage]);
  
  const handleFeedback = useCallback(async (messageId, feedbackType, details = '') => {
    try {
      await fetch('/api/v1/bot/feedback', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`
        },
        body: JSON.stringify({
          message_id: messageId,
          feedback_type: feedbackType,
          details: details
        })
      });
      
      setShowFeedback(null);
    } catch (error) {
      console.error('Failed to submit feedback:', error);
    }
  }, []);
  
  if (isMinimized) {
    return (
      <motion.div
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="fixed bottom-4 right-4 z-50"
      >
        <button
          onClick={onToggleMinimize}
          className="bg-gradient-to-r from-blue-500 to-purple-600 text-white p-4 rounded-full shadow-lg hover:shadow-xl transform hover:scale-105 transition-all duration-300"
        >
          <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-3.582 8-8 8a8.013 8.013 0 01-7-4L0 20l4-4" />
          </svg>
        </button>
      </motion.div>
    );
  }
  
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: 20 }}
      className="flex flex-col h-full bg-white rounded-lg shadow-2xl overflow-hidden"
    >
      {/* Header */}
      <BotHeader 
        isConnected={isConnected}
        conversationMetadata={conversationMetadata}
        onMinimize={onToggleMinimize}
        onRequestHuman={() => requestHumanSupport()}
      />
      
      {/* Messages Container */}
      <div 
        ref={chatContainerRef}
        className="flex-1 overflow-y-auto px-4 py-6 space-y-4 bg-gradient-to-b from-gray-50 to-white"
        style={{ maxHeight: '70vh' }}
      >
        <AnimatePresence mode="popLayout">
          {messages.map((message, index) => (
            <motion.div
              key={message.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              transition={{ delay: index * 0.1 }}
            >
              {message.sender_role === 'bot' ? (
                <BotMessage 
                  message={message}
                  onFeedback={(feedbackType, details) => 
                    handleFeedback(message.id, feedbackType, details)
                  }
                  showFeedback={showFeedback === message.id}
                  onToggleFeedback={() => 
                    setShowFeedback(showFeedback === message.id ? null : message.id)
                  }
                />
              ) : (
                <UserMessage message={message} />
              )}
            </motion.div>
          ))}
        </AnimatePresence>
        
        {/* Typing Indicator */}
        <AnimatePresence>
          {isTyping && (
            <motion.div
              initial={{ opacity: 0, scale: 0.8 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.8 }}
            >
              <TypingIndicator />
            </motion.div>
          )}
        </AnimatePresence>
        
        <div ref={messagesEndRef} />
      </div>
      
      {/* Smart Actions */}
      <AnimatePresence>
        {smartActions.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="px-4 py-2"
          >
            <SmartActions 
              actions={smartActions}
              onActionClick={handleSmartAction}
            />
          </motion.div>
        )}
      </AnimatePresence>
      
      {/* Conversation Suggestions */}
      <AnimatePresence>
        {suggestions.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="px-4 py-2"
          >
            <ConversationSuggestions 
              suggestions={suggestions}
              onSuggestionClick={handleSuggestionClick}
            />
          </motion.div>
        )}
      </AnimatePresence>
      
      {/* Message Input */}
      <div className="border-t border-gray-200 bg-white">
        <MessageInput 
          onSendMessage={sendMessage}
          disabled={!isConnected}
          placeholder={isConnected ? "Ask me anything about rentals..." : "Connecting..."}
        />
      </div>
    </motion.div>
  );
};

export default IntelligentBotChat;