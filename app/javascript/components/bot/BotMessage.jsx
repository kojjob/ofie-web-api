// Beautiful Bot Message Component with Rich Content Support
import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import ReactMarkdown from 'react-markdown';

const BotMessage = ({ 
  message, 
  onFeedback,
  showFeedback,
  onToggleFeedback 
}) => {
  const [isExpanded, setIsExpanded] = useState(false);
  const [feedbackDetails, setFeedbackDetails] = useState('');
  
  const formatTimestamp = (timestamp) => {
    return new Date(timestamp).toLocaleTimeString([], { 
      hour: '2-digit', 
      minute: '2-digit' 
    });
  };
  
  const renderContent = () => {
    // Check if message contains structured content
    if (message.metadata?.type === 'property_recommendations') {
      return renderPropertyRecommendations();
    }
    
    // Render markdown content with custom styling
    return (
      <ReactMarkdown 
        className="prose prose-sm max-w-none text-gray-800"
        components={{
          h1: ({children}) => <h1 className="text-lg font-bold text-gray-900 mb-2">{children}</h1>,
          h2: ({children}) => <h2 className="text-base font-semibold text-gray-800 mb-2">{children}</h2>,
          h3: ({children}) => <h3 className="text-sm font-medium text-gray-800 mb-1">{children}</h3>,
          p: ({children}) => <p className="mb-2 leading-relaxed">{children}</p>,
          ul: ({children}) => <ul className="mb-2 space-y-1">{children}</ul>,
          li: ({children}) => <li className="flex items-start"><span className="mr-2 text-blue-500">•</span><span>{children}</span></li>,
          strong: ({children}) => <strong className="font-semibold text-gray-900">{children}</strong>,
          em: ({children}) => <em className="italic text-gray-700">{children}</em>,
          code: ({children}) => <code className="bg-gray-100 px-1 py-0.5 rounded text-sm font-mono">{children}</code>,
          blockquote: ({children}) => <blockquote className="border-l-4 border-blue-500 pl-3 italic text-gray-700">{children}</blockquote>
        }}
      >
        {message.content}
      </ReactMarkdown>
    );
  };
  
  const renderPropertyRecommendations = () => {
    const properties = message.metadata?.property_ids || [];
    
    return (
      <div className="space-y-4">
        <div className="text-gray-800">{message.content}</div>
        
        {properties.length > 0 && (
          <div className="grid gap-3">
            {properties.slice(0, 3).map((property, index) => (
              <motion.div
                key={property.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
                className="bg-gradient-to-r from-blue-50 to-purple-50 border border-blue-200 rounded-lg p-4 hover:shadow-md transition-all duration-300 cursor-pointer"
                onClick={() => openPropertyDetails(property.id)}
              >
                <div className="flex items-start space-x-3">
                  {property.photos?.[0] && (
                    <img 
                      src={property.photos[0]} 
                      alt={property.title}
                      className="w-16 h-16 rounded-lg object-cover"
                    />
                  )}
                  <div className="flex-1 min-w-0">
                    <h4 className="font-semibold text-gray-900 truncate">{property.title}</h4>
                    <p className="text-sm text-gray-600">{property.address}, {property.city}</p>
                    <div className="flex items-center space-x-4 mt-2 text-sm text-gray-700">
                      <span className="font-medium text-green-600">${property.price}/month</span>
                      <span>🛏️ {property.bedrooms} bed</span>
                      <span>🚿 {property.bathrooms} bath</span>
                    </div>
                    {property.amenities && (
                      <div className="mt-2 flex flex-wrap gap-1">
                        {property.amenities.slice(0, 3).map((amenity, idx) => (
                          <span key={idx} className="inline-block bg-blue-100 text-blue-800 text-xs px-2 py-1 rounded-full">
                            {amenity}
                          </span>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </div>
    );
  };
  
  const renderConfidenceIndicator = () => {
    if (!message.metadata?.confidence) return null;
    
    const confidence = message.metadata.confidence;
    const confidenceColor = confidence > 0.8 ? 'green' : confidence > 0.5 ? 'yellow' : 'red';
    const confidenceWidth = `${confidence * 100}%`;
    
    return (
      <div className="mt-2 flex items-center space-x-2 text-xs text-gray-500">
        <span>Confidence:</span>
        <div className="flex-1 bg-gray-200 rounded-full h-1 max-w-16">
          <div 
            className={`h-1 rounded-full bg-${confidenceColor}-500`}
            style={{ width: confidenceWidth }}
          />
        </div>
        <span>{Math.round(confidence * 100)}%</span>
      </div>
    );
  };
  
  const renderFeedbackForm = () => {
    if (!showFeedback) return null;
    
    return (
      <motion.div
        initial={{ opacity: 0, height: 0 }}
        animate={{ opacity: 1, height: 'auto' }}
        exit={{ opacity: 0, height: 0 }}
        className="mt-3 p-3 bg-gray-50 rounded-lg border"
      >
        <div className="flex flex-wrap gap-2 mb-3">
          {[
            { type: 'helpful', label: '👍 Helpful', color: 'green' },
            { type: 'not_helpful', label: '👎 Not Helpful', color: 'red' },
            { type: 'inaccurate', label: '❌ Inaccurate', color: 'red' },
            { type: 'excellent', label: '⭐ Excellent', color: 'blue' }
          ].map((feedback) => (
            <button
              key={feedback.type}
              onClick={() => onFeedback(feedback.type, feedbackDetails)}
              className={`px-3 py-1 text-xs rounded-full border transition-all duration-200 hover:scale-105 bg-${feedback.color}-50 border-${feedback.color}-200 text-${feedback.color}-700 hover:bg-${feedback.color}-100`}
            >
              {feedback.label}
            </button>
          ))}
        </div>
        
        <textarea
          value={feedbackDetails}
          onChange={(e) => setFeedbackDetails(e.target.value)}
          placeholder="Any additional feedback? (optional)"
          className="w-full p-2 text-sm border border-gray-300 rounded-md resize-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          rows={2}
        />
        
        <div className="flex justify-end space-x-2 mt-2">
          <button
            onClick={onToggleFeedback}
            className="px-3 py-1 text-xs text-gray-600 hover:text-gray-800 transition-colors"
          >
            Cancel
          </button>
        </div>
      </motion.div>
    );
  };
  
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="flex items-start space-x-3 group"
    >
      {/* Bot Avatar */}
      <motion.div
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ delay: 0.1 }}
        className="flex-shrink-0 w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center shadow-lg"
      >
        <svg className="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.813 15.904L9 18.75l-.813-2.846a4.5 4.5 0 00-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 003.09-3.09L9 5.25l.813 2.847a4.5 4.5 0 003.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 00-3.09 3.09zM18.259 8.715L18 9.75l-.259-1.035a3.375 3.375 0 00-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 002.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 002.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 00-2.456 2.456z" />
        </svg>
      </motion.div>
      
      {/* Message Content */}
      <div className="flex-1 min-w-0">
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.2 }}
          className="bg-white border border-gray-200 rounded-2xl rounded-tl-md px-4 py-3 shadow-sm hover:shadow-md transition-all duration-300 relative"
        >
          {/* Message Content */}
          <div className="relative">
            {renderContent()}
            
            {/* Intent and Confidence Info */}
            {message.metadata?.intent && (
              <div className="mt-2 flex items-center space-x-2 text-xs text-gray-400">
                <span className="bg-gray-100 px-2 py-0.5 rounded-full">
                  {message.metadata.intent.replace(/_/g, ' ')}
                </span>
                {renderConfidenceIndicator()}
              </div>
            )}
          </div>
          
          {/* Message Actions */}
          <div className="flex items-center justify-between mt-3 pt-2 border-t border-gray-100">
            <span className="text-xs text-gray-500">
              {formatTimestamp(message.created_at)}
            </span>
            
            <div className="flex items-center space-x-2 opacity-0 group-hover:opacity-100 transition-opacity duration-200">
              <button
                onClick={onToggleFeedback}
                className="p-1 text-gray-400 hover:text-gray-600 transition-colors rounded-full hover:bg-gray-100"
                title="Provide feedback"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z" />
                </svg>
              </button>
              
              <button
                onClick={() => navigator.clipboard.writeText(message.content)}
                className="p-1 text-gray-400 hover:text-gray-600 transition-colors rounded-full hover:bg-gray-100"
                title="Copy message"
              >
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
              </button>
            </div>
          </div>
        </motion.div>
        
        {/* Feedback Form */}
        <AnimatePresence>
          {renderFeedbackForm()}
        </AnimatePresence>
      </div>
    </motion.div>
  );
};

export default BotMessage;