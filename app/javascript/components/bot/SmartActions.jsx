// Smart Actions Component for Bot Suggestions
import React from 'react';
import { motion, AnimatePresence } from 'framer-motion';

const SmartActions = ({ actions, onActionClick }) => {
  if (!actions || actions.length === 0) return null;
  
  const getActionIcon = (actionType) => {
    const icons = {
      'quick_search': (
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      ),
      'save_search': (
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
        </svg>
      ),
      'schedule_viewing': (
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>
      ),
      'start_application': (
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
      ),
      'contact_support': (
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192L5.636 18.364M12 2.25a9.75 9.75 0 109.75 9.75A9.75 9.75 0 0012 2.25z" />
        </svg>
      ),
      'create_request': (
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
        </svg>
      ),
      'upload_documents': (
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
        </svg>
      ),
      'make_payment': (
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z" />
        </svg>
      ),
      'get_alerts': (
        <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-5 5v-5zM4.343 12.344l1.414 1.414a2 2 0 002.828 0l4.243-4.243a2 2 0 000-2.828l-1.414-1.414a2 2 0 00-2.828 0L4.343 9.515a2 2 0 000 2.829z" />
        </svg>
      )
    };
    
    return icons[actionType] || (
      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 10V3L4 14h7v7l9-11h-7z" />
      </svg>
    );
  };
  
  const getActionColor = (actionType) => {
    const colors = {
      'quick_search': 'blue',
      'save_search': 'purple',
      'schedule_viewing': 'green',
      'start_application': 'indigo',
      'contact_support': 'red',
      'create_request': 'yellow',
      'upload_documents': 'gray',
      'make_payment': 'emerald',
      'get_alerts': 'orange'
    };
    
    return colors[actionType] || 'blue';
  };
  
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="mb-4"
    >
      <div className="flex items-center space-x-2 mb-2">
        <div className="w-6 h-0.5 bg-gradient-to-r from-blue-500 to-purple-600 rounded-full"></div>
        <span className="text-xs font-medium text-gray-600 uppercase tracking-wide">Quick Actions</span>
        <div className="flex-1 h-0.5 bg-gradient-to-r from-purple-600 to-blue-500 rounded-full"></div>
      </div>
      
      <div className="flex flex-wrap gap-2">
        <AnimatePresence>
          {actions.map((action, index) => {
            const color = getActionColor(action.type);
            
            return (
              <motion.button
                key={`${action.type}-${index}`}
                initial={{ opacity: 0, scale: 0.8, y: 20 }}
                animate={{ opacity: 1, scale: 1, y: 0 }}
                exit={{ opacity: 0, scale: 0.8, y: -20 }}
                transition={{ delay: index * 0.1 }}
                whileHover={{ scale: 1.05, y: -2 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => onActionClick(action)}
                className={`
                  inline-flex items-center space-x-2 px-3 py-2 rounded-lg text-sm font-medium
                  transition-all duration-300 transform hover:shadow-lg
                  bg-${color}-50 border border-${color}-200 text-${color}-700 
                  hover:bg-${color}-100 hover:border-${color}-300
                  focus:outline-none focus:ring-2 focus:ring-${color}-500 focus:ring-opacity-50
                `}
              >
                <span className={`text-${color}-500`}>
                  {action.icon ? (
                    <span className="text-base">{action.icon}</span>
                  ) : (
                    getActionIcon(action.type)
                  )}
                </span>
                <span>{action.label}</span>
              </motion.button>
            );
          })}
        </AnimatePresence>
      </div>
    </motion.div>
  );
};

export default SmartActions;