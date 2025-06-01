// Beautiful User Message Component
import React from 'react';
import { motion } from 'framer-motion';

const UserMessage = ({ message }) => {
  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  };
  
  const getStatusIcon = () => {
    if (message.read) {
      return (
        <svg className="w-4 h-4 text-blue-500" fill="currentColor" viewBox="0 0 24 24">
          <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
        </svg>
      );
    }
    
    return (
      <svg className="w-4 h-4 text-gray-400" fill="currentColor" viewBox="0 0 24 24">
        <path d="M9 16.17L4.83 12l-1.42 1.41L9 19 21 7l-1.41-1.41z"/>
      </svg>
    );
  };
  
  return (
    <motion.div
      initial={{ opacity: 0, y: 10, x: 20 }}
      animate={{ opacity: 1, y: 0, x: 0 }}
      className="flex items-end justify-end space-x-2 group"
    >
      <div className="flex flex-col items-end max-w-xs lg:max-w-md">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.1 }}
          className="bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-2xl rounded-tr-md px-4 py-3 shadow-lg hover:shadow-xl transition-all duration-300 transform hover:scale-[1.02]"
        >
          <p className="text-sm leading-relaxed break-words">
            {message.content}
          </p>
        </motion.div>
        
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.3 }}
          className="flex items-center space-x-1 mt-1 opacity-0 group-hover:opacity-100 transition-opacity duration-200"
        >
          <span className="text-xs text-gray-500">
            {formatTimestamp(message.created_at)}
          </span>
          {getStatusIcon()}
        </motion.div>
      </div>
      
      {/* User Avatar */}
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ delay: 0.2 }}
        className="flex-shrink-0 w-8 h-8 bg-gray-300 rounded-full overflow-hidden shadow-lg"
      >
        {message.sender_avatar ? (
          <img 
            src={message.sender_avatar} 
            alt={message.sender_name}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full bg-gradient-to-br from-gray-400 to-gray-600 flex items-center justify-center">
            <span className="text-white text-sm font-medium">
              {message.sender_name?.charAt(0)?.toUpperCase() || 'U'}
            </span>
          </div>
        )}
      </motion.div>
    </motion.div>
  );
};

export default UserMessage;