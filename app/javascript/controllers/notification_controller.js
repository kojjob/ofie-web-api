import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notification"
export default class extends Controller {
  static targets = ["badge", "dropdown", "list"]
  static values = { 
    url: String,
    count: Number,
    autoRefresh: Boolean,
    refreshInterval: Number
  }

  connect() {
    this.refreshTimer = null
    this.isOpen = false
    
    // Initialize notification count
    this.updateBadge(this.countValue || 0)
    
    // Set up auto-refresh if enabled
    if (this.autoRefreshValue) {
      this.startAutoRefresh()
    }
    
    // Load initial notifications
    this.loadNotifications()
  }

  disconnect() {
    this.stopAutoRefresh()
  }

  // Toggle notification dropdown
  toggle() {
    this.isOpen = !this.isOpen
    
    if (this.isOpen) {
      this.showDropdown()
      this.loadNotifications()
    } else {
      this.hideDropdown()
    }
  }

  // Show notification dropdown
  showDropdown() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.remove('hidden')
      this.dropdownTarget.classList.add('block')
    }
  }

  // Hide notification dropdown
  hideDropdown() {
    if (this.hasDropdownTarget) {
      this.dropdownTarget.classList.add('hidden')
      this.dropdownTarget.classList.remove('block')
    }
    this.isOpen = false
  }

  // Load notifications from server
  async loadNotifications() {
    if (!this.urlValue) return
    
    try {
      const response = await fetch(this.urlValue, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.updateNotifications(data.notifications || [])
        this.updateBadge(data.unread_count || 0)
      }
    } catch (error) {
      console.error('Failed to load notifications:', error)
    }
  }

  // Update notification list
  updateNotifications(notifications) {
    if (!this.hasListTarget) return
    
    if (notifications.length === 0) {
      this.listTarget.innerHTML = `
        <div class="p-4 text-center text-gray-500">
          <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5-5-5h5v-12"></path>
          </svg>
          <p class="mt-2">No notifications</p>
        </div>
      `
    } else {
      this.listTarget.innerHTML = notifications.map(notification => `
        <div class="notification-item p-3 border-b border-gray-100 last:border-b-0 ${
          notification.read ? 'bg-white' : 'bg-blue-50'
        }" data-notification-id="${notification.id}">
          <div class="flex items-start space-x-3">
            <div class="flex-shrink-0">
              <div class="h-8 w-8 rounded-full flex items-center justify-center ${
                notification.type === 'favorite' ? 'bg-red-100 text-red-600' :
                notification.type === 'message' ? 'bg-blue-100 text-blue-600' :
                notification.type === 'booking' ? 'bg-green-100 text-green-600' :
                'bg-gray-100 text-gray-600'
              }">
                ${this.getNotificationIcon(notification.type)}
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900">${notification.title}</p>
              <p class="text-sm text-gray-500 mt-1">${notification.message}</p>
              <p class="text-xs text-gray-400 mt-1">${this.formatTime(notification.created_at)}</p>
            </div>
            ${!notification.read ? '<div class="flex-shrink-0"><div class="h-2 w-2 bg-blue-600 rounded-full"></div></div>' : ''}
          </div>
        </div>
      `).join('')
    }
  }

  // Get icon for notification type
  getNotificationIcon(type) {
    const icons = {
      favorite: '<svg class="h-4 w-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" clip-rule="evenodd"></path></svg>',
      message: '<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg>',
      booking: '<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>',
      default: '<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-5 5-5-5h5v-12"></path></svg>'
    }
    return icons[type] || icons.default
  }

  // Format notification time
  formatTime(timestamp) {
    const date = new Date(timestamp)
    const now = new Date()
    const diff = now - date
    
    if (diff < 60000) return 'Just now'
    if (diff < 3600000) return `${Math.floor(diff / 60000)}m ago`
    if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`
    return date.toLocaleDateString()
  }

  // Update notification badge
  updateBadge(count) {
    if (!this.hasBadgeTarget) return
    
    if (count > 0) {
      this.badgeTarget.textContent = count > 99 ? '99+' : count.toString()
      this.badgeTarget.classList.remove('hidden')
    } else {
      this.badgeTarget.classList.add('hidden')
    }
  }

  // Mark notification as read
  async markAsRead(event) {
    const notificationItem = event.target.closest('.notification-item')
    if (!notificationItem) return
    
    const notificationId = notificationItem.dataset.notificationId
    if (!notificationId) return
    
    try {
      const response = await fetch(`/notifications/${notificationId}/mark_read`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        notificationItem.classList.remove('bg-blue-50')
        notificationItem.classList.add('bg-white')
        
        // Remove unread indicator
        const unreadIndicator = notificationItem.querySelector('.bg-blue-600')
        if (unreadIndicator) {
          unreadIndicator.parentElement.remove()
        }
        
        // Update badge count
        const currentCount = parseInt(this.badgeTarget.textContent) || 0
        this.updateBadge(Math.max(0, currentCount - 1))
      }
    } catch (error) {
      console.error('Failed to mark notification as read:', error)
    }
  }

  // Mark all notifications as read
  async markAllAsRead() {
    try {
      const response = await fetch('/notifications/mark_all_read', {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        // Update UI
        const unreadItems = this.listTarget.querySelectorAll('.bg-blue-50')
        unreadItems.forEach(item => {
          item.classList.remove('bg-blue-50')
          item.classList.add('bg-white')
          
          const unreadIndicator = item.querySelector('.bg-blue-600')
          if (unreadIndicator) {
            unreadIndicator.parentElement.remove()
          }
        })
        
        this.updateBadge(0)
      }
    } catch (error) {
      console.error('Failed to mark all notifications as read:', error)
    }
  }

  // Start auto-refresh timer
  startAutoRefresh() {
    const interval = this.refreshIntervalValue || 30000 // Default 30 seconds
    this.refreshTimer = setInterval(() => {
      this.loadNotifications()
    }, interval)
  }

  // Stop auto-refresh timer
  stopAutoRefresh() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer)
      this.refreshTimer = null
    }
  }

  // Handle clicks outside to close dropdown
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideDropdown()
    }
  }
}