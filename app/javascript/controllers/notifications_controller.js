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
          <svg class="w-12 h-12 mx-auto mb-4 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0M3.124 7.5A8.969 8.969 0 015.292 3m13.416 0a8.969 8.969 0 012.168 4.5" />
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
        <svg class="w-12 h-12 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
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
      'comment': '<svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg>',
      'comment_flagged': '<svg class="w-4 h-4 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M3 21v-4m0 0V5a2 2 0 012-2h6.5l1 1H21l-3 6 3 6h-8.5l-1-1H5a2 2 0 00-2 2zm9-13.5V9"></path></svg>',
      'property': '<svg class="w-4 h-4 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"></path></svg>',
      'payment': '<svg class="w-4 h-4 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M2.25 8.25h19.5M2.25 9h19.5m-16.5 5.25h6m-6 2.25h3m-3.75 3h15a2.25 2.25 0 002.25-2.25V6.75A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25v10.5A2.25 2.25 0 004.5 19.5z"></path></svg>',
      'message': '<svg class="w-4 h-4 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75"></path></svg>',
      'system': '<svg class="w-4 h-4 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.324.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.24-.438.613-.431.992a6.759 6.759 0 010 .255c-.007.378.138.75.43.99l1.005.828c.424.35.534.954.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.57 6.57 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.28c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.02-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.992a6.932 6.932 0 010-.255c.007-.378-.138-.75-.43-.99l-1.004-.828a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.087.22-.128.332-.183.582-.495.644-.869l.214-1.281z M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>'
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