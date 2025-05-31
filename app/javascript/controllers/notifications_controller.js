import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="notifications"
export default class extends Controller {
  static targets = ["count", "list", "item"]
  static values = { userId: Number }

  connect() {
    console.log("Notifications controller connected")
    this.setupTurboStreamListeners()
  }

  setupTurboStreamListeners() {
    // Listen for Turbo Stream updates
    document.addEventListener("turbo:before-stream-render", this.handleStreamUpdate.bind(this))
  }

  handleStreamUpdate(event) {
    // Update notification count when new notifications arrive
    if (event.detail.newStream && event.detail.newStream.includes('notification')) {
      this.updateNotificationCount()
    }
  }

  markAsRead(event) {
    const notificationId = event.currentTarget.dataset.notificationId
    const notificationItem = this.element.querySelector(`[data-notification-id="${notificationId}"]`)
    
    if (notificationItem) {
      // Optimistically update UI
      notificationItem.classList.remove('unread')
      const unreadBadge = notificationItem.querySelector('.w-2.h-2.bg-blue-600')
      if (unreadBadge) {
        unreadBadge.remove()
      }
      
      // Update count
      this.decrementCount()
    }
  }

  markAllAsRead() {
    // Remove unread class from all notifications
    const unreadNotifications = this.element.querySelectorAll('.notification-item.unread')
    unreadNotifications.forEach(notification => {
      notification.classList.remove('unread')
      const unreadBadge = notification.querySelector('.w-2.h-2.bg-blue-600')
      if (unreadBadge) {
        unreadBadge.remove()
      }
    })
    
    // Reset count to 0
    this.setCount(0)
  }

  updateNotificationCount() {
    // Fetch current unread count from server
    fetch('/notifications/unread_count', {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(data => {
      this.setCount(data.count)
    })
    .catch(error => {
      console.error('Error fetching notification count:', error)
    })
  }

  decrementCount() {
    if (this.hasCountTarget) {
      const currentCount = parseInt(this.countTarget.textContent) || 0
      const newCount = Math.max(0, currentCount - 1)
      this.setCount(newCount)
    }
  }

  setCount(count) {
    if (this.hasCountTarget) {
      if (count > 0) {
        this.countTarget.textContent = count
        this.countTarget.classList.remove('hidden')
      } else {
        this.countTarget.classList.add('hidden')
      }
    }
  }

  addNotification(notification) {
    if (this.hasListTarget) {
      // Add new notification to the top of the list
      this.listTarget.insertAdjacentHTML('afterbegin', notification)
      
      // Remove oldest notification if we have more than 10
      const notifications = this.listTarget.querySelectorAll('.notification-item')
      if (notifications.length > 10) {
        notifications[notifications.length - 1].remove()
      }
      
      // Increment count
      this.incrementCount()
    }
  }

  incrementCount() {
    if (this.hasCountTarget) {
      const currentCount = parseInt(this.countTarget.textContent) || 0
      this.setCount(currentCount + 1)
    }
  }

  disconnect() {
    document.removeEventListener("turbo:before-stream-render", this.handleStreamUpdate.bind(this))
  }
}