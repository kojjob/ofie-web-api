import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["widget", "messages", "input", "sendButton", "minimizeButton"]
  static values = { conversationId: String }

  connect() {
    this.isMinimized = true
    this.conversationIdValue = null
    this.setupEventListeners()
    this.setupIntersectionObserver()
  }

  setupEventListeners() {
    // Handle Enter key in input
    this.inputTarget.addEventListener('keypress', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault()
        this.sendMessage()
      }
    })

    // Auto-resize input
    this.inputTarget.addEventListener('input', () => {
      this.adjustInputHeight()
    })
  }

  setupIntersectionObserver() {
    // Subtle entrance animation when widget becomes visible
    const observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('animate-fade-in')
        }
      })
    })
    observer.observe(this.element)
  }

  toggleWidget() {
    this.isMinimized = !this.isMinimized

    if (this.isMinimized) {
      // Smooth close animation
      this.widgetTarget.classList.add('translate-y-full', 'opacity-0')
      this.widgetTarget.classList.remove('translate-y-0', 'opacity-100')
    } else {
      // Smooth open animation
      this.widgetTarget.classList.remove('translate-y-full', 'opacity-0')
      this.widgetTarget.classList.add('translate-y-0', 'opacity-100')

      // Focus input when opening with delay for animation
      setTimeout(() => {
        this.inputTarget.focus()
        this.inputTarget.placeholder = "How can I help you today?"
      }, 300)

      // Load initial greeting if no conversation exists
      if (!this.conversationIdValue && this.messagesTarget.children.length === 0) {
        setTimeout(() => this.loadInitialGreeting(), 500)
      }
    }
  }

  adjustInputHeight() {
    const input = this.inputTarget
    // Reset height to auto to get accurate scrollHeight
    input.classList.remove('h-10', 'h-12', 'h-14', 'h-16', 'h-20', 'h-24', 'h-28', 'h-32')
    
    // Calculate appropriate height class based on content
    const scrollHeight = input.scrollHeight
    if (scrollHeight <= 40) {
      input.classList.add('h-10')
    } else if (scrollHeight <= 48) {
      input.classList.add('h-12')
    } else if (scrollHeight <= 56) {
      input.classList.add('h-14')
    } else if (scrollHeight <= 64) {
      input.classList.add('h-16')
    } else if (scrollHeight <= 80) {
      input.classList.add('h-20')
    } else if (scrollHeight <= 96) {
      input.classList.add('h-24')
    } else if (scrollHeight <= 112) {
      input.classList.add('h-28')
    } else {
      input.classList.add('h-32') // Max height
    }
    
    input.classList.add('transition-height')
  }

  async loadInitialGreeting() {
    // Add a subtle typing indicator first
    this.showTypingIndicator()

    setTimeout(() => {
      this.hideTypingIndicator()
      this.addBotMessage("Hi! I'm your Ofie Assistant 👋\n\nI can help you with:\n• Finding properties\n• Application process\n• Platform navigation\n• General questions\n\nWhat would you like to know?")
    }, 1000)
  }

  async sendMessage() {
    const message = this.inputTarget.value.trim()
    if (!message) return

    // Add user message to chat
    this.addUserMessage(message)
    this.inputTarget.value = ''
    this.inputTarget.style.height = 'auto'
    this.sendButtonTarget.disabled = true
    this.updateSendButton('sending')

    // Show typing indicator
    this.showTypingIndicator()

    try {
      const response = await this.sendToBotAPI(message)
      const data = await response.json()

      console.log('Bot response:', data) // Debug logging

      if (response.ok && data.message) {
        this.conversationIdValue = data.conversation_id

        // Simulate realistic response time
        setTimeout(() => {
          this.hideTypingIndicator()
          this.addBotMessage(data.message.content)
        }, 800 + Math.random() * 1200)
      } else if (data.message) {
        // Handle error responses that still contain a message
        this.hideTypingIndicator()
        this.addBotMessage(data.message.content)
      } else {
        this.hideTypingIndicator()
        this.addBotMessage("I'm experiencing some technical difficulties. Please try again in a moment.")
      }
    } catch (error) {
      console.error('Bot chat error:', error)
      this.hideTypingIndicator()
      this.addBotMessage("I'm having trouble connecting right now. Please check your internet connection and try again.")
    } finally {
      this.sendButtonTarget.disabled = false
      this.updateSendButton('ready')
    }
  }

  updateSendButton(state) {
    const button = this.sendButtonTarget
    switch(state) {
      case 'sending':
        button.innerHTML = `
          <svg class="w-4 h-4 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
          </svg>
        `
        break
      case 'ready':
        button.innerHTML = `
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"></path>
          </svg>
        `
        break
    }
  }

  async sendToBotAPI(message) {
    const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
    
    const payload = {
      query: message
    }
    
    if (this.conversationIdValue) {
      payload.conversation_id = this.conversationIdValue
    }

    return fetch('/api/v1/bot/chat', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': token
      },
      body: JSON.stringify(payload)
    })
  }

  addUserMessage(message) {
    const messageElement = this.createMessageElement(message, 'user')
    this.messagesTarget.appendChild(messageElement)
    this.scrollToBottom()
  }

  addBotMessage(message) {
    const messageElement = this.createMessageElement(message, 'bot')
    this.messagesTarget.appendChild(messageElement)
    this.scrollToBottom()
  }

  createMessageElement(message, sender) {
    const messageDiv = document.createElement('div')
    messageDiv.className = `flex ${sender === 'user' ? 'justify-end' : 'justify-start'} mb-4 animate-fade-in-up`

    const isBot = sender === 'bot'
    const bgColor = isBot ? 'bg-white/80 backdrop-blur-sm border border-gray-200/50' : 'bg-gradient-to-br from-slate-700 via-slate-800 to-slate-900'
    const textColor = isBot ? 'text-gray-800' : 'text-white'
    const alignment = isBot ? 'rounded-br-2xl' : 'rounded-bl-2xl'
    const shadow = isBot ? 'shadow-sm' : 'shadow-lg shadow-slate-800/25'

    // Format message with line breaks
    const formattedMessage = this.formatMessage(message)

    messageDiv.innerHTML = `
      <div class="max-w-xs lg:max-w-md px-4 py-3 ${bgColor} ${textColor} rounded-2xl ${alignment} ${shadow} transition-all duration-300 hover:shadow-lg">
        ${isBot ? `
          <div class="flex items-center mb-2">
            <div class="w-4 h-4 bg-gradient-to-r from-slate-600 to-slate-700 rounded-full mr-2"></div>
            <span class="text-xs font-semibold text-slate-600">Ofie Assistant</span>
          </div>
        ` : ''}
        <div class="text-sm leading-relaxed">${formattedMessage}</div>
        <div class="text-xs opacity-75 mt-2 ${isBot ? 'text-gray-500' : 'text-white/80'}">${this.formatTime()}</div>
      </div>
    `

    return messageDiv
  }

  formatMessage(message) {
    // Convert line breaks and format lists
    return this.escapeHtml(message)
      .replace(/\n/g, '<br>')
      .replace(/•\s/g, '<span class="inline-block w-2 h-2 bg-current rounded-full mr-2 opacity-60"></span>')
  }

  formatTime() {
    return new Date().toLocaleTimeString([], {
      hour: '2-digit',
      minute: '2-digit',
      hour12: true
    })
  }

  showTypingIndicator() {
    const typingDiv = document.createElement('div')
    typingDiv.className = 'flex justify-start mb-4 typing-indicator'
    typingDiv.innerHTML = `
      <div class="bg-white/80 backdrop-blur-sm border border-gray-200/50 rounded-2xl rounded-br-2xl px-4 py-3 shadow-sm">
        <div class="flex items-center space-x-1">
          <div class="w-4 h-4 bg-gradient-to-r from-slate-600 to-slate-700 rounded-full mr-2"></div>
          <div class="flex space-x-1">
            <span class="typing-dot"></span>
            <span class="typing-dot"></span>
            <span class="typing-dot"></span>
          </div>
        </div>
      </div>
    `
    this.messagesTarget.appendChild(typingDiv)
    this.scrollToBottom()
  }

  hideTypingIndicator() {
    const typingIndicator = this.messagesTarget.querySelector('.typing-indicator')
    if (typingIndicator) {
      typingIndicator.remove()
    }
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  scrollToBottom() {
    setTimeout(() => {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }, 100)
  }
}