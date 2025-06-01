// Conversation Suggestions Component for Quick Replies
import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const ConversationSuggestions = ({ suggestions, onSuggestionClick }) => {
  if (!suggestions || suggestions.length === 0) return null;
  
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="mb-4"
    >
      <div className="flex items-center space-x-2 mb-3">
        <div className="w-4 h-0.5 bg-gradient-to-r from-green-500 to-blue-500 rounded-full"></div>
        <span className="text-xs font-medium text-gray-600 uppercase tracking-wide">Suggestions</span>
        <div className="flex-1 h-0.5 bg-gradient-to-r from-blue-500 to-green-500 rounded-full"></div>
      </div>
      
      <div className="space-y-2">
        <AnimatePresence>
          {suggestions.map((suggestion, index) => (
            <motion.button
              key={`suggestion-${index}`}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 20 }}
              transition={{ delay: index * 0.1 }}
              whileHover={{ scale: 1.02, x: 4 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => onSuggestionClick(suggestion)}
              className="
                w-full text-left px-4 py-3 rounded-xl border border-gray-200 
                bg-gradient-to-r from-gray-50 to-blue-50
                hover:from-blue-50 hover:to-purple-50 
                hover:border-blue-300 hover:shadow-md
                transition-all duration-300 transform
                focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50
                group
              "
            >
              <div className="flex items-start space-x-3">
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  transition={{ delay: index * 0.1 + 0.2 }}
                  className="flex-shrink-0 w-8 h-8 bg-gradient-to-br from-blue-400 to-purple-500 rounded-full flex items-center justify-center mt-0.5 group-hover:shadow-lg transition-shadow duration-300"
                >
                  <svg className="w-4 h-4 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-3.582 8-8 8a8.013 8.013 0 01-7-4L0 20l4-4" />
                  </svg>
                </motion.div>
                
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-gray-900 group-hover:text-blue-900 transition-colors duration-300">
                    {suggestion}
                  </p>
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: "100%" }}
                    transition={{ delay: index * 0.1 + 0.4, duration: 0.5 }}
                    className="mt-1 h-0.5 bg-gradient-to-r from-blue-400 to-purple-500 rounded-full opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                  />
                </div>
                
                <motion.div
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.1 + 0.3 }}
                  className="flex-shrink-0 text-gray-400 group-hover:text-blue-500 transition-colors duration-300"
                >
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
                  </svg>
                </motion.div>
              </div>
            </motion.button>
          ))}
        </AnimatePresence>
      </div>
      
      {/* Decorative bottom gradient */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: suggestions.length * 0.1 + 0.5 }}
        className="mt-3 h-1 bg-gradient-to-r from-transparent via-blue-200 to-transparent rounded-full"
      />
    </motion.div>
  );
};

export default ConversationSuggestions;