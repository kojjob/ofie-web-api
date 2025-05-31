import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notifications"
export default class extends Controller {
  static targets = ["dropdown", "badge", "list"]
  static values = {
    unreadCount: Number,
    refreshInterval: { type: Number, default: 30000 } // 30 seconds
  }

  connect() {
    console.log("Notifications controller connected")
    this.loadNotifications()
    this.startPolling()
    this.updateBadge()

    // Add outside click listener
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this)
    document.addEventListener('click', this.boundHandleOutsideClick)
  }

  disconnect() {
    this.stopPolling()
    document.removeEventListener('click', this.boundHandleOutsideClick)
  }

  toggle(event) {
    event.preventDefault()
    console.log("Toggling notifications dropdown")

    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.toggle("hidden")

      if (!this.dropdownTarget.classList.contains("hidden")) {
        this.loadNotifications()
      }
    }
  }

  markAllAsRead(event) {
    event.preventDefault()
    console.log("Marking all notifications as read")

    fetch('/notifications/mark_all_read', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getCSRFToken(),
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.updateUnreadCount(0)
        this.loadNotifications()
        this.showToast('All notifications marked as read', 'success')
      }
    })
    .catch(error => {
      console.error('Error marking notifications as read:', error)
      this.showToast('Failed to mark notifications as read', 'error')
    })
  }

  loadNotifications() {
    console.log("Loading notifications...")

    fetch('/notifications.json', {
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': this.getCSRFToken()
      }
    })
    .then(response => response.json())
    .then(data => {
      this.renderNotifications(data.notifications)
      this.updateUnreadCount(data.unread_count)
    })
    .catch(error => {
      console.error('Error loading notifications:', error)
      this.renderError()
    })
  }

  renderNotifications(notifications) {
    if (!this.hasListTarget) return

    if (!notifications || notifications.length === 0) {
      this.listTarget.innerHTML = `
        <div class="p-6 text-center text-gray-500">
          <svg class="w-12 h-12 mx-auto mb-4 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5v-5zM10.5 3.75a6 6 0 0 1 6 6v2.25l1.5 1.5v2.25h-15v-2.25l1.5-1.5v-2.25a6 6 0 0 1 6-6z"></path>
          </svg>
          <p>No notifications yet</p>
        </div>
      `
      return
    }

    const notificationsHTML = notifications.slice(0, 5).map(notification => this.renderNotification(notification)).join('')
    this.listTarget.innerHTML = notificationsHTML
  }

  renderNotification(notification) {
    const isUnread = !notification.read_at
    const timeAgo = this.timeAgo(new Date(notification.created_at))
    const iconColor = this.getNotificationIconColor(notification.notification_type)
    const icon = this.getNotificationIcon(notification.notification_type)

    return `
      <div class="border-b border-gray-100 last:border-b-0 hover:bg-gray-50 transition-colors duration-200">
        <a href="${notification.url || '#'}" class="block p-4">
          <div class="flex items-start space-x-3">
            <div class="flex-shrink-0">
              <div class="w-8 h-8 ${iconColor} rounded-xl flex items-center justify-center">
                ${icon}
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center justify-between mb-1">
                <p class="text-sm font-semibold text-gray-900 truncate">
                  ${notification.title}
                </p>
                ${isUnread ? '<div class="w-2 h-2 bg-blue-500 rounded-full"></div>' : ''}
              </div>
              <p class="text-xs text-gray-600 line-clamp-2 mb-1">
                ${notification.message}
              </p>
              <p class="text-xs text-gray-400">
                ${timeAgo}
              </p>
            </div>
          </div>
        </a>
      </div>
    `
  }

  renderError() {
    if (!this.hasListTarget) return

    this.listTarget.innerHTML = `
      <div class="p-6 text-center text-red-500">
        <svg class="w-12 h-12 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        <p>Failed to load notifications</p>
        <button class="mt-2 text-sm text-blue-600 hover:text-blue-800" onclick="this.closest('[data-controller=notifications]').controller.loadNotifications()">
          Try again
        </button>
      </div>
    `
  }

  updateUnreadCount(count) {
    this.unreadCountValue = count
    this.updateBadge()
  }

  updateBadge() {
    if (this.hasBadgeTarget) {
      if (this.unreadCountValue > 0) {
        this.badgeTarget.classList.remove('hidden')
        if (this.unreadCountValue > 99) {
          this.badgeTarget.textContent = '99+'
        } else if (this.unreadCountValue > 0) {
          this.badgeTarget.textContent = this.unreadCountValue
        }
      } else {
        this.badgeTarget.classList.add('hidden')
      }
    }
  }

  startPolling() {
    this.pollingInterval = setInterval(() => {
      // Only poll if dropdown is not open to avoid interrupting user
      if (this.hasDropdownTarget && this.dropdownTarget.classList.contains('hidden')) {
        this.loadNotifications()
      }
    }, this.refreshIntervalValue)
  }

  stopPolling() {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval)
    }
  }

  handleOutsideClick(event) {
    if (!this.element.contains(event.target) && this.hasDropdownTarget) {
      this.dropdownTarget.classList.add('hidden')
    }
  }

  getNotificationIconColor(type) {
    const colors = {
      'comment': 'bg-gradient-to-r from-blue-100 to-indigo-100',
      'comment_flagged': 'bg-gradient-to-r from-red-100 to-pink-100',
      'property': 'bg-gradient-to-r from-green-100 to-emerald-100',
      'payment': 'bg-gradient-to-r from-purple-100 to-indigo-100',
      'message': 'bg-gradient-to-r from-indigo-100 to-purple-100',
      'system': 'bg-gradient-to-r from-gray-100 to-slate-100'
    }
    return colors[type] || colors['system']
  }

  getNotificationIcon(type) {
    const icons = {
      'comment': '<svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg>',
      'comment_flagged': '<svg class="w-4 h-4 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9"></path></svg>',
      'property': '<svg class="w-4 h-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path></svg>',
      'payment': '<svg class="w-4 h-4 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"></path></svg>',
      'message': '<svg class="w-4 h-4 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg>',
      'system': '<svg class="w-4 h-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>'
    }
    return icons[type] || icons['system']
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
}