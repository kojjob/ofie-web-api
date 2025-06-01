// Beautiful Message Input Component with Enhanced Features
import React, { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const MessageInput = ({ 
  onSendMessage, 
  disabled = false, 
  placeholder = "Type your message...",
  onTyping
}) => {
  const [message, setMessage] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const inputRef = useRef(null);
  const typingTimeoutRef = useRef(null);
  
  // Common emojis for quick access
  const quickEmojis = ['😊', '👍', '🏠', '❤️', '🤔', '😅', '🎉', '👋', '💡', '🔥'];
  
  useEffect(() => {
    if (inputRef.current && !disabled) {
      inputRef.current.focus();
    }
  }, [disabled]);
  
  const handleInputChange = (e) => {
    const value = e.target.value;
    setMessage(value);
    
    // Handle typing indicator
    if (onTyping && value.length > 0) {
      if (!isTyping) {
        setIsTyping(true);
        onTyping('start');
      }
      
      // Reset typing timeout
      if (typingTimeoutRef.current) {
        clearTimeout(typingTimeoutRef.current);
      }
      
      typingTimeoutRef.current = setTimeout(() => {
        setIsTyping(false);
        onTyping('stop');
      }, 1000);
    }
  };
  
  const handleSubmit = (e) => {
    e.preventDefault();
    if (message.trim() && !disabled) {
      onSendMessage(message.trim());
      setMessage('');
      setShowEmojiPicker(false);
      
      // Stop typing indicator
      if (isTyping) {
        setIsTyping(false);
        if (onTyping) onTyping('stop');
      }
      
      // Clear typing timeout
      if (typingTimeoutRef.current) {
        clearTimeout(typingTimeoutRef.current);
      }
    }
  };
  
  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSubmit(e);
    }
  };
  
  const insertEmoji = (emoji) => {
    const newMessage = message + emoji;
    setMessage(newMessage);
    setShowEmojiPicker(false);
    inputRef.current?.focus();
  };
  
  const startVoiceRecording = () => {
    setIsRecording(true);
    // Implement voice recording logic here
    console.log('Starting voice recording...');
  };
  
  const stopVoiceRecording = () => {
    setIsRecording(false);
    // Implement stop recording and transcription logic here
    console.log('Stopping voice recording...');
  };
  
  return (
    <div className="relative">
      {/* Emoji Picker */}
      <AnimatePresence>
        {showEmojiPicker && (
          <motion.div
            initial={{ opacity: 0, y: 10, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 10, scale: 0.95 }}
            className="absolute bottom-full left-0 right-0 mb-2 p-3 bg-white rounded-lg shadow-xl border border-gray-200 z-50"
          >
            <div className="grid grid-cols-5 gap-2">
              {quickEmojis.map((emoji, index) => (
                <motion.button
                  key={emoji}
                  initial={{ opacity: 0, scale: 0 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: index * 0.05 }}
                  whileHover={{ scale: 1.2 }}
                  whileTap={{ scale: 0.9 }}
                  onClick={() => insertEmoji(emoji)}
                  className="w-8 h-8 flex items-center justify-center text-lg hover:bg-gray-100 rounded-lg transition-colors duration-200"
                >
                  {emoji}
                </motion.button>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
      
      {/* Input Container */}
      <form onSubmit={handleSubmit} className="relative">
        <div className="flex items-end space-x-2 p-4 bg-white border-t border-gray-200">
          {/* Emoji Button */}
          <motion.button
            type="button"
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            onClick={() => setShowEmojiPicker(!showEmojiPicker)}
            disabled={disabled}
            className="flex-shrink-0 p-2 text-gray-500 hover:text-gray-700 transition-colors duration-200 rounded-full hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </motion.button>
          
          {/* Message Input */}
          <div className="flex-1 relative">
            <motion.textarea
              ref={inputRef}
              value={message}
              onChange={handleInputChange}
              onKeyPress={handleKeyPress}
              placeholder={placeholder}
              disabled={disabled}
              rows={1}
              className="
                w-full resize-none rounded-2xl border border-gray-300 px-4 py-3 pr-12
                focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 focus:outline-none
                disabled:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-50
                placeholder-gray-500 text-gray-900
                max-h-32 min-h-[48px]
                transition-all duration-200
              "
              style={{
                background: disabled 
                  ? '#f3f4f6' 
                  : 'linear-gradient(135deg, #ffffff 0%, #f8fafc 100%)',
                boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1), inset 0 1px 2px rgba(0, 0, 0, 0.05)'
              }}
            />
            
            {/* Character Counter */}
            {message.length > 100 && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                className="absolute -top-6 right-0 text-xs text-gray-500"
              >
                {message.length}/1000
              </motion.div>
            )}
          </div>
          
          {/* Voice Recording Button */}
          <motion.button
            type="button"
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
            onMouseDown={startVoiceRecording}
            onMouseUp={stopVoiceRecording}
            onMouseLeave={stopVoiceRecording}
            disabled={disabled}
            className={`
              flex-shrink-0 p-2 rounded-full transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed
              ${isRecording 
                ? 'bg-red-500 text-white shadow-lg' 
                : 'text-gray-500 hover:text-gray-700 hover:bg-gray-100'
              }
            `}
          >
            <motion.div
              animate={isRecording ? { scale: [1, 1.2, 1] } : {}}
              transition={{ duration: 0.5, repeat: isRecording ? Infinity : 0 }}
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
              </svg>
            </motion.div>
          </motion.button>
          
          {/* Send Button */}
          <motion.button
            type="submit"
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            disabled={!message.trim() || disabled}
            className="
              flex-shrink-0 p-3 bg-gradient-to-r from-blue-500 to-purple-600 
              text-white rounded-full shadow-lg hover:shadow-xl
              disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:shadow-lg
              transition-all duration-300 transform
              focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50
            "
          >
            <motion.div
              initial={false}
              animate={message.trim() ? { rotate: 0 } : { rotate: -45 }}
              transition={{ duration: 0.2 }}
            >
              {message.trim() ? (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8" />
                </svg>
              ) : (
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
              )}
            </motion.div>
          </motion.button>
        </div>
        
        {/* Connection Status */}
        {disabled && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="absolute inset-0 bg-white/80 backdrop-blur-sm flex items-center justify-center rounded-2xl"
          >
            <div className="flex items-center space-x-2 text-gray-500">
              <motion.div
                animate={{ rotate: 360 }}
                transition={{ duration: 1, repeat: Infinity, ease: "linear" }}
                className="w-4 h-4"
              >
                <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
              </motion.div>
              <span className="text-sm">Connecting...</span>
            </div>
          </motion.div>
        )}
      </form>
      
      {/* Recording Indicator */}
      <AnimatePresence>
        {isRecording && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 20 }}
            className="absolute bottom-full left-0 right-0 mb-2 p-3 bg-red-500 text-white rounded-lg shadow-xl"
          >
            <div className="flex items-center space-x-2">
              <motion.div
                animate={{ scale: [1, 1.2, 1] }}
                transition={{ duration: 0.5, repeat: Infinity }}
                className="w-3 h-3 bg-white rounded-full"
              />
              <span className="text-sm font-medium">Recording... Release to send</span>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default MessageInput;