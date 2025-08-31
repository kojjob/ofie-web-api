// Floating Bot Widget - Main Entry Point
import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import IntelligentBotChat from './IntelligentBotChat';

const FloatingBotWidget = ({ user, apiBaseUrl = '/api/v1' }) => {
  const [isOpen, setIsOpen] = useState(false);
  const [conversationId, setConversationId] = useState(null);
  const [hasNewMessage, setHasNewMessage] = useState(false);
  const [isOnline, setIsOnline] = useState(true);
  const [greeting, setGreeting] = useState('');
  const [suggestions, setSuggestions] = useState([]);
  
  useEffect(() => {
    // Fetch initial bot data
    fetchBotGreeting();
    initializeConversation();
    
    // Set up online/offline detection
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);
    
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);
  
  const fetchBotGreeting = async () => {
    try {
      const response = await fetch(`${apiBaseUrl}/bot/conversation_starters`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
          'Content-Type': 'application/json'
        }
      });
      
      if (response.ok) {
        const data = await response.json();
        setGreeting(data.greeting);
        setSuggestions(data.conversation_starters);
      }
    } catch (error) {
      console.error('Failed to fetch bot greeting:', error);
    }
  };
  
  const initializeConversation = async () => {
    try {
      // Create or get existing conversation
      const response = await fetch(`${apiBaseUrl}/bot/send_message`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          message: '', // Empty message to initialize conversation
          property_id: null // General conversation
        })
      });
      
      if (response.ok) {
        const data = await response.json();
        setConversationId(data.conversation_id);
      }
    } catch (error) {
      console.error('Failed to initialize conversation:', error);
    }
  };
  
  const handleToggleChat = () => {
    setIsOpen(!isOpen);
    if (hasNewMessage) {
      setHasNewMessage(false);
    }
  };
  
  const handleNewMessage = () => {
    if (!isOpen) {
      setHasNewMessage(true);
    }
  };
  
  const BotButton = () => (
    <motion.button
      initial={{ scale: 0, rotate: -180 }}
      animate={{ scale: 1, rotate: 0 }}
      whileHover={{ scale: 1.1, y: -2 }}
      whileTap={{ scale: 0.9 }}
      onClick={handleToggleChat}
      className="relative group"
    >
      {/* Main Button */}
      <div className="w-16 h-16 bg-gradient-to-br from-blue-500 via-purple-600 to-blue-700 rounded-full shadow-2xl hover:shadow-blue-500/25 transition-all duration-300 flex items-center justify-center overflow-hidden">
        {/* Animated Background */}
        <motion.div
          animate={{ 
            rotate: [0, 360],
            scale: [1, 1.2, 1]
          }}
          transition={{ 
            duration: 8, 
            repeat: Infinity, 
            ease: "linear" 
          }}
          className="absolute inset-0 bg-gradient-to-br from-blue-400/30 via-purple-500/30 to-blue-600/30"
        />
        
        {/* Bot Icon */}
        <motion.div
          animate={{ 
            rotate: isOpen ? 45 : 0,
            scale: isOpen ? 0.8 : 1
          }}
          transition={{ duration: 0.3 }}
          className="relative z-10 text-white"
        >
          {isOpen ? (
            <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          ) : (
            <motion.div
              animate={{ 
                y: [0, -2, 0],
                rotate: [0, 5, -5, 0]
              }}
              transition={{ 
                duration: 2, 
                repeat: Infinity, 
                ease: "easeInOut" 
              }}
            >
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.847a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456z" />
              </svg>
            </motion.div>
          )}
        </motion.div>
        
        {/* Pulse Animation */}
        <motion.div
          animate={{ scale: [1, 1.5, 1], opacity: [0.7, 0, 0.7] }}
          transition={{ duration: 2, repeat: Infinity }}
          className="absolute inset-0 bg-blue-500 rounded-full"
        />
      </div>
      
      {/* Online/Offline Status */}
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        className={`absolute -top-1 -right-1 w-5 h-5 rounded-full border-2 border-white shadow-lg ${
          isOnline ? 'bg-green-500' : 'bg-red-500'
        }`}
      >
        <motion.div
          animate={{ scale: [1, 1.2, 1] }}
          transition={{ duration: 2, repeat: Infinity }}
          className={`w-full h-full rounded-full ${
            isOnline ? 'bg-green-400' : 'bg-red-400'
          } animate-ping`}
        />
      </motion.div>
      
      {/* New Message Indicator */}
      <AnimatePresence>
        {hasNewMessage && (
          <motion.div
            initial={{ scale: 0, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0, opacity: 0 }}
            className="absolute -top-2 -left-2 w-6 h-6 bg-red-500 rounded-full flex items-center justify-center text-white text-xs font-bold shadow-lg"
          >
            <motion.span
              animate={{ scale: [1, 1.2, 1] }}
              transition={{ duration: 0.5, repeat: Infinity }}
            >
              !
            </motion.span>
          </motion.div>
        )}
      </AnimatePresence>
      
      {/* Floating Particles */}
      <div className="absolute inset-0 pointer-events-none">
        {[...Array(3)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-1 h-1 bg-white/60 rounded-full"
            animate={{
              y: [-20, -40],
              x: [Math.random() * 20 - 10, Math.random() * 20 - 10],
              opacity: [0, 1, 0],
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
              delay: i * 0.7,
              ease: "easeOut"
            }}
            style={{
              left: '50%',
              top: '50%',
            }}
          />
        ))}
      </div>
    </motion.button>
  );
  
  const WelcomeBubble = () => (
    <AnimatePresence>
      {!isOpen && greeting && (
        <motion.div
          initial={{ opacity: 0, x: 20, scale: 0.8 }}
          animate={{ opacity: 1, x: 0, scale: 1 }}
          exit={{ opacity: 0, x: 20, scale: 0.8 }}
          transition={{ delay: 1 }}
          className="absolute bottom-full right-0 mb-4 max-w-xs"
        >
          <div className="bg-white rounded-2xl rounded-br-md shadow-xl border border-gray-200 p-4 relative">
            {/* Speech Bubble Arrow */}
            <div className="absolute bottom-0 right-4 w-0 h-0 border-l-[12px] border-l-transparent border-r-[12px] border-r-transparent border-t-[12px] border-t-white transform translate-y-full"></div>
            <div className="absolute bottom-0 right-4 w-0 h-0 border-l-[14px] border-l-transparent border-r-[14px] border-r-transparent border-t-[14px] border-t-gray-200 transform translate-y-full -z-10"></div>
            
            {/* Content */}
            <div className="flex items-start space-x-3">
              <div className="flex-shrink-0 w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
                <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.847a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456z" />
                </svg>
              </div>
              <div className="flex-1">
                <p className="text-sm text-gray-800 mb-2">{greeting}</p>
                <button
                  onClick={handleToggleChat}
                  className="text-xs text-blue-600 hover:text-blue-800 font-medium transition-colors duration-200"
                >
                  Click to chat →
                </button>
              </div>
            </div>
            
            {/* Close Button */}
            <button
              onClick={() => setGreeting('')}
              className="absolute top-2 right-2 w-6 h-6 flex items-center justify-center text-gray-400 hover:text-gray-600 transition-colors duration-200"
            >
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
  
  return (
    <div className="fixed bottom-6 right-6 z-50">
      {/* Chat Interface */}
      <AnimatePresence mode="wait">
        {isOpen && conversationId && (
          <motion.div
            initial={{ opacity: 0, scale: 0.8, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.8, y: 20 }}
            transition={{ type: "spring", damping: 25, stiffness: 300 }}
            className="absolute bottom-20 right-0 w-96 h-[600px] shadow-2xl rounded-2xl overflow-hidden bg-white border border-gray-200"
            style={{
              maxHeight: '80vh',
              maxWidth: '90vw'
            }}
          >
            <IntelligentBotChat
              conversationId={conversationId}
              user={user}
              onConversationUpdate={handleNewMessage}
              onToggleMinimize={handleToggleChat}
            />
          </motion.div>
        )}
      </AnimatePresence>
      
      {/* Welcome Bubble */}
      <WelcomeBubble />
      
      {/* Bot Button */}
      <BotButton />
      
      {/* Background Glow Effect */}
      <div className="absolute inset-0 bg-gradient-to-r from-blue-500/20 via-purple-600/20 to-blue-700/20 rounded-full blur-xl -z-10 animate-pulse"></div>
    </div>
  );
};

export default FloatingBotWidget;