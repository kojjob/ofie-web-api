// Main Bot Integration Component
import React from 'react';
import FloatingBotWidget from './FloatingBotWidget';

const BotIntegration = ({ 
  user, 
  apiBaseUrl = '/api/v1',
  enabled = true,
  theme = 'default'
}) => {
  // Don't render if bot is disabled or user is not authenticated
  if (!enabled || !user) {
    return null;
  }
  
  return (
    <div id="ofie-bot-container" className={`ofie-bot-theme-${theme}`}>
      <FloatingBotWidget 
        user={user}
        apiBaseUrl={apiBaseUrl}
      />
    </div>
  );
};

// Easy integration function for adding to any page
export const initializeOfieBot = (options = {}) => {
  const {
    containerId = 'ofie-bot-root',
    user,
    apiBaseUrl = '/api/v1',
    theme = 'default',
    enabled = true
  } = options;
  
  // Check if React and ReactDOM are available
  if (typeof React === 'undefined' || typeof ReactDOM === 'undefined') {
    console.error('Ofie Bot requires React and ReactDOM to be loaded');
    return;
  }
  
  // Create container if it doesn't exist
  let container = document.getElementById(containerId);
  if (!container) {
    container = document.createElement('div');
    container.id = containerId;
    document.body.appendChild(container);
  }
  
  // Render the bot
  const root = ReactDOM.createRoot(container);
  root.render(
    React.createElement(BotIntegration, {
      user,
      apiBaseUrl,
      theme,
      enabled
    })
  );
  
  return {
    destroy: () => root.unmount(),
    update: (newOptions) => {
      root.render(
        React.createElement(BotIntegration, {
          user: newOptions.user || user,
          apiBaseUrl: newOptions.apiBaseUrl || apiBaseUrl,
          theme: newOptions.theme || theme,
          enabled: newOptions.enabled !== undefined ? newOptions.enabled : enabled
        })
      );
    }
  };
};

export default BotIntegration;