// Beautiful Typing Indicator Component
import React from 'react';
import { motion } from 'framer-motion';

const TypingIndicator = ({ userName = "Ofie Assistant" }) => {
  const dotVariants = {
    start: { y: "0%" },
    end: { y: "100%" }
  };
  
  const dotTransition = {
    duration: 0.5,
    repeat: Infinity,
    repeatType: "reverse",
    ease: "easeInOut"
  };
  
  return (
    <div className="flex items-start space-x-3">
      {/* Bot Avatar */}
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        className="flex-shrink-0 w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center shadow-lg"
      >
        <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.847a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456z" />
        </svg>
      </motion.div>
      
      {/* Typing Animation */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="bg-white border border-gray-200 rounded-2xl rounded-tl-md px-4 py-3 shadow-sm"
      >
        <div className="flex items-center space-x-1">
          <span className="text-sm text-gray-600 mr-2">{userName} is typing</span>
          <div className="flex space-x-1">
            {[0, 1, 2].map((index) => (
              <motion.div
                key={index}
                className="w-2 h-2 bg-blue-500 rounded-full"
                variants={dotVariants}
                initial="start"
                animate="end"
                transition={{
                  ...dotTransition,
                  delay: index * 0.2
                }}
              />
            ))}
          </div>
        </div>
      </motion.div>
    </div>
  );
};

export default TypingIndicator;