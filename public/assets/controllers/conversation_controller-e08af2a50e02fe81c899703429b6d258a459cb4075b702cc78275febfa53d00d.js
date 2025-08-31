import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="conversation"
export default class extends Controller {
  static targets = ["messagesList", "sendButton", "characterCount"]
  static values = { conversationId: Number }

  connect() {
    console.log("Conversation controller connected")
    this.setupTextareaHandlers()
    this.scrollToBottom()
    this.markMessagesAsRead()
    
    // Auto-refresh messages every 10 seconds
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  setupTextareaHandlers() {
    const textarea = this.element.querySelector('textarea[name="message[content]"]')
    if (textarea) {
      // Character counting
      textarea.addEventListener('input', (e) => {
        this.updateCharacterCount(e.target.value.length)
      })
      
      // Enter key handling
      textarea.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
          e.preventDefault()
          this.sendMessage(e)
        }
      })
    }
  }

  updateCharacterCount(count) {
    if (this.hasCharacterCountTarget) {
      this.characterCountTarget.textContent = count
      
      // Change color based on character count
      if (count > 1800) {
        this.characterCountTarget.className = 'text-red-500 font-bold'
      } else if (count > 1500) {
        this.characterCountTarget.className = 'text-amber-500 font-bold'
      } else {
        this.characterCountTarget.className = 'text-gray-500'
      }
    }
  }

  sendMessage(event) {
    event.preventDefault()
    
    const form = event.target.closest('form')
    const textarea = form.querySelector('textarea[name="message[content]"]')
    const content = textarea.value.trim()
    
    if (!content) {
      this.showToast('Please enter a message', 'error')
      return
    }
    
    // Disable send button
    if (this.hasSendButtonTarget) {
      this.sendButtonTarget.disabled = true
      this.sendButtonTarget.textContent = 'Sending...'
    }
    
    const formData = new FormData(form)
    
    fetch(form.action, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': this.getCSRFToken(),
        'Accept': 'application/json'
      },
      body: formData
    })
    .then(response => response.json())
    .then(data => {
      if (data.message) {
        // Add message to DOM
        this.addMessageToDOM(data.message)
        
        // Clear form
        textarea.value = ''
        this.updateCharacterCount(0)
        
        // Scroll to bottom
        this.scrollToBottom()
        
        this.showToast('Message sent!', 'success')
      } else {
        throw new Error(data.error || 'Failed to send message')
      }
    })
    .catch(error => {
      console.error('Error sending message:', error)
      this.showToast('Failed to send message. Please try again.', 'error')
    })
    .finally(() => {
      // Re-enable send button
      if (this.hasSendButtonTarget) {
        this.sendButtonTarget.disabled = false
        this.sendButtonTarget.textContent = 'Send'
      }
    })
  }

  addMessageToDOM(messageData) {
    if (!this.hasMessagesListTarget) return
    
    const messageHTML = this.createMessageHTML(messageData)
    this.messagesListTarget.insertAdjacentHTML('beforeend', messageHTML)
  }

  createMessageHTML(message) {
    const isCurrentUser = message.sender.id === this.getCurrentUserId()
    const timeAgo = this.timeAgo(new Date(message.created_at))
    
    return `
      <div class="flex ${isCurrentUser ? 'justify-end' : 'justify-start'}">
        <div class="max-w-xs lg:max-w-md">
          <!-- Message Bubble -->
          <div class="${isCurrentUser ? 'bg-gradient-to-r from-indigo-600 to-purple-600 text-white' : 'bg-gray-100 text-gray-900'} rounded-2xl px-4 py-3 shadow-lg">
            <p class="text-sm leading-relaxed">${this.formatContent(message.content)}</p>
          </div>
          
          <!-- Message Info -->
          <div class="flex items-center ${isCurrentUser ? 'justify-end' : 'justify-start'} mt-1 space-x-2">
            <p class="text-xs text-gray-500">
              ${message.sender.name || message.sender.email.split('@')[0]}
            </p>
            <span class="text-xs text-gray-400">•</span>
            <p class="text-xs text-gray-500">
              ${timeAgo}
            </p>
          </div>
        </div>
      </div>
    `
  }

  formatContent(content) {
    return content.replace(/\n/g, '<br>')
  }

  scrollToBottom() {
    if (this.hasMessagesListTarget) {
      setTimeout(() => {
        this.messagesListTarget.scrollTop = this.messagesListTarget.scrollHeight
      }, 100)
    }
  }

  markMessagesAsRead() {
    fetch(`/conversations/${this.conversationIdValue}/messages/mark_all_read`, {
      method: 'PATCH',
      headers: {
        'X-CSRF-Token': this.getCSRFToken(),
        'Accept': 'application/json'
      }
    }).catch(error => console.log('Error marking messages as read:', error))
  }

  startPolling() {
    this.pollingInterval = setInterval(() => {
      this.refreshMessages()
    }, 10000) // 10 seconds
  }

  stopPolling() {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval)
    }
  }

  refreshMessages() {
    fetch(`/conversations/${this.conversationIdValue}/messages.json`, {
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': this.getCSRFToken()
      }
    })
    .then(response => response.json())
    .then(data => {
      // Simple refresh - in a real app you'd want to be smarter about this
      // For now, just check if we have new messages
      const currentMessageCount = this.messagesListTarget.querySelectorAll('.flex').length
      if (data.messages && data.messages.length > currentMessageCount) {
        // Reload the page to show new messages
        // In production, you'd want to append only new messages
        window.location.reload()
      }
    })
    .catch(error => console.log('Error refreshing messages:', error))
  }

  getCurrentUserId() {
    return parseInt(this.element.dataset.currentUserId)
  }

  timeAgo(date) {
    const now = new Date()
    const diffInSeconds = Math.floor((now - date) / 1000)
    
    if (diffInSeconds < 60) return 'just now'
    if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`
    if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`
    if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)}d ago`
    
    return date.toLocaleDateString()
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
  }

  showToast(message, type) {
    const toast = document.createElement('div')
    toast.className = `fixed top-4 right-4 z-50 px-6 py-3 rounded-2xl font-bold text-white shadow-lg transform transition-all duration-300 ${
      type === 'success' ? 'bg-green-500' : 'bg-red-500'
    }`
    toast.textContent = message
    
    document.body.appendChild(toast)
    
    setTimeout(() => {
      toast.style.transform = 'translateX(0)'
    }, 100)
    
    setTimeout(() => {
      toast.style.transform = 'translateX(100%)'
      setTimeout(() => {
        if (document.body.contains(toast)) {
          document.body.removeChild(toast)
        }
      }, 300)
    }, 3000)
  }
};
