import { Controller } from "@hotwired/stimulus"

// Real-time Progress Controller for Batch Properties
export default class extends Controller {
  static targets = [
    "statsContainer", "totalUploads", "propertiesCreated", "processing", "failedItems",
    "tableContainer", "tableBody", "uploadRow", "statusCell", "progressBar", "progressText",
    "successCount", "failedCount", "statusIndicator", "statusText", "processingQueue"
  ]
  
  static values = { 
    pollInterval: { type: Number, default: 3000 } // 3 seconds
  }

  connect() {
    this.isPolling = false
    this.pollTimer = null
    this.hasActiveUploads = this.checkForActiveUploads()
    
    console.log('🔄 Batch Progress Controller connected')
    
    // Start polling if there are active uploads
    if (this.hasActiveUploads) {
      this.startPolling()
    }
    
    // Initialize connection status
    this.updateConnectionStatus(true)
  }

  disconnect() {
    this.stopPolling()
    console.log('🔄 Batch Progress Controller disconnected')
  }

  // ==================== POLLING MANAGEMENT ====================

  /**
   * Start polling for progress updates
   */
  startPolling() {
    if (this.isPolling) return
    
    this.isPolling = true
    this.updateConnectionStatus(true)
    
    console.log(`🔄 Starting progress polling (${this.pollIntervalValue}ms interval)`)
    
    // Initial fetch
    this.fetchUpdates()
    
    // Start interval
    this.pollTimer = setInterval(() => {
      this.fetchUpdates()
    }, this.pollIntervalValue)
  }

  /**
   * Stop polling for progress updates
   */
  stopPolling() {
    if (!this.isPolling) return
    
    this.isPolling = false
    this.updateConnectionStatus(false)
    
    if (this.pollTimer) {
      clearInterval(this.pollTimer)
      this.pollTimer = null
    }
    
    console.log('🔄 Stopped progress polling')
  }

  /**
   * Manual refresh triggered by user
   */
  refreshData() {
    console.log('🔄 Manual refresh triggered')
    this.fetchUpdates()
    this.showRefreshFeedback()
  }

  // ==================== DATA FETCHING ====================

  /**
   * Fetch latest updates from server
   */
  async fetchUpdates() {
    try {
      const response = await fetch('/batch_properties/progress', {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        credentials: 'same-origin'
      })

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`)
      }

      const data = await response.json()
      this.updateUI(data)
      
      // Check if we should continue polling
      this.hasActiveUploads = data.has_active_uploads || false
      
      if (!this.hasActiveUploads && this.isPolling) {
        console.log('🔄 No active uploads, stopping polling')
        this.stopPolling()
      }

    } catch (error) {
      console.error('🔄 Progress fetch error:', error)
      this.handleFetchError(error)
    }
  }

  // ==================== UI UPDATES ====================

  /**
   * Update UI with latest data
   */
  updateUI(data) {
    this.updateStats(data.stats)
    this.updateUploads(data.uploads)
    this.updateProcessingQueue(data.processing_queue)
  }

  /**
   * Update statistics in header
   */
  updateStats(stats) {
    if (!stats) return

    this.updateStatElement(this.totalUploadsTarget, stats.total_uploads)
    this.updateStatElement(this.propertiesCreatedTarget, stats.properties_created)
    this.updateStatElement(this.processingTarget, stats.processing)
    this.updateStatElement(this.failedItemsTarget, stats.failed_items)
  }

  /**
   * Update individual stat element with animation
   */
  updateStatElement(element, newValue) {
    if (!element) return

    const currentValue = parseInt(element.textContent) || 0
    
    if (currentValue !== newValue) {
      // Animate the change
      element.style.transform = 'scale(1.1)'
      element.style.transition = 'transform 0.2s ease'
      
      setTimeout(() => {
        element.textContent = newValue
        element.style.transform = 'scale(1)'
      }, 100)
    }
  }

  /**
   * Update upload rows
   */
  updateUploads(uploads) {
    if (!uploads || !this.hasUploadRowTargets) return

    uploads.forEach(uploadData => {
      const row = this.findUploadRow(uploadData.id)
      if (row) {
        this.updateUploadRow(row, uploadData)
      }
    })
  }

  /**
   * Find upload row by ID
   */
  findUploadRow(uploadId) {
    return this.uploadRowTargets.find(row => 
      row.dataset.uploadId === uploadId.toString()
    )
  }

  /**
   * Update individual upload row
   */
  updateUploadRow(row, uploadData) {
    // Update status
    const statusCell = row.querySelector('[data-batch-progress-target="statusCell"]')
    if (statusCell && uploadData.status_html) {
      statusCell.innerHTML = uploadData.status_html
    }

    // Update progress bar
    const progressBar = row.querySelector('[data-batch-progress-target="progressBar"]')
    const progressText = row.querySelector('[data-batch-progress-target="progressText"]')
    
    if (progressBar && uploadData.progress_percentage !== undefined) {
      const newProgress = uploadData.progress_percentage
      const currentProgress = parseFloat(progressBar.style.width) || 0
      
      if (Math.abs(currentProgress - newProgress) > 0.1) {
        progressBar.style.width = `${newProgress}%`
        
        if (progressText) {
          progressText.textContent = `${newProgress}%`
        }
      }
    }

    // Update success/failed counts
    const successCount = row.querySelector('[data-batch-progress-target="successCount"] span')
    const failedCount = row.querySelector('[data-batch-progress-target="failedCount"] span')
    
    if (successCount && uploadData.successful_items !== undefined) {
      this.updateCountElement(successCount, uploadData.successful_items)
    }
    
    if (failedCount && uploadData.failed_items !== undefined) {
      this.updateCountElement(failedCount, uploadData.failed_items)
    }
  }

  /**
   * Update count element with animation
   */
  updateCountElement(element, newValue) {
    const currentValue = parseInt(element.textContent) || 0
    
    if (currentValue !== newValue) {
      element.style.transform = 'scale(1.2)'
      element.style.transition = 'transform 0.3s ease'
      
      setTimeout(() => {
        element.textContent = newValue
        element.style.transform = 'scale(1)'
      }, 150)
    }
  }

  /**
   * Update processing queue
   */
  updateProcessingQueue(queueData) {
    if (!queueData || !this.hasProcessingQueueTarget) return

    if (queueData.items && queueData.items.length > 0) {
      // Show processing queue if hidden
      this.processingQueueTarget.classList.remove('hidden')
      
      // Update queue items
      queueData.items.forEach(item => {
        const queueItem = this.findQueueItem(item.id)
        if (queueItem) {
          this.updateQueueItem(queueItem, item)
        }
      })
    } else {
      // Hide processing queue if no items
      this.processingQueueTarget.classList.add('hidden')
    }
  }

  /**
   * Find queue item by ID
   */
  findQueueItem(itemId) {
    return this.processingQueueTarget.querySelector(`[data-queue-id="${itemId}"]`)
  }

  /**
   * Update queue item progress
   */
  updateQueueItem(item, itemData) {
    const progressBar = item.querySelector('.bg-blue-600')
    const progressText = item.querySelector('.text-blue-600')
    
    if (progressBar && itemData.progress_percentage !== undefined) {
      progressBar.style.width = `${itemData.progress_percentage}%`
    }
    
    if (progressText && itemData.progress_percentage !== undefined) {
      progressText.textContent = `${itemData.progress_percentage}%`
    }
  }

  // ==================== CONNECTION STATUS ====================

  /**
   * Update connection status indicator
   */
  updateConnectionStatus(isConnected) {
    if (this.hasStatusIndicatorTarget && this.hasStatusTextTarget) {
      if (isConnected) {
        this.statusIndicatorTarget.className = 'w-2 h-2 bg-green-400 rounded-full animate-pulse mr-2'
        this.statusTextTarget.textContent = 'Live Updates Active'
      } else {
        this.statusIndicatorTarget.className = 'w-2 h-2 bg-gray-400 rounded-full mr-2'
        this.statusTextTarget.textContent = 'Updates Paused'
      }
    }
  }

  /**
   * Show refresh feedback
   */
  showRefreshFeedback() {
    if (this.hasStatusTextTarget) {
      const originalText = this.statusTextTarget.textContent
      this.statusTextTarget.textContent = 'Refreshing...'
      
      setTimeout(() => {
        this.statusTextTarget.textContent = originalText
      }, 1000)
    }
  }

  // ==================== ERROR HANDLING ====================

  /**
   * Handle fetch errors
   */
  handleFetchError(error) {
    console.error('🔄 Progress update failed:', error)
    
    // Update connection status
    this.updateConnectionStatus(false)
    
    // Show error state temporarily
    if (this.hasStatusTextTarget) {
      const originalText = this.statusTextTarget.textContent
      this.statusTextTarget.textContent = 'Connection Error'
      
      setTimeout(() => {
        this.statusTextTarget.textContent = originalText
      }, 3000)
    }
  }

  // ==================== UTILITY METHODS ====================

  /**
   * Check if there are currently active uploads
   */
  checkForActiveUploads() {
    if (!this.hasUploadRowTargets) return false
    
    return this.uploadRowTargets.some(row => {
      const status = row.querySelector('[data-batch-progress-target="statusCell"]')
      if (!status) return false
      
      const statusText = status.textContent.toLowerCase()
      return statusText.includes('processing') || statusText.includes('validated')
    })
  }

  /**
   * Get CSRF token for requests
   */
  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }

  // ==================== LIFECYCLE EVENTS ====================

  /**
   * Handle visibility change (pause when tab not visible)
   */
  handleVisibilityChange() {
    if (document.hidden) {
      if (this.isPolling) {
        this.stopPolling()
        this.wasPollingBeforeHidden = true
      }
    } else {
      if (this.wasPollingBeforeHidden && this.hasActiveUploads) {
        this.startPolling()
        this.wasPollingBeforeHidden = false
      }
    }
  }

  /**
   * Handle page focus/blur
   */
  handleFocus() {
    if (this.hasActiveUploads && !this.isPolling) {
      this.startPolling()
    }
  }

  handleBlur() {
    // Keep polling in background but reduce frequency
    if (this.isPolling) {
      this.pollIntervalValue = Math.max(this.pollIntervalValue * 2, 10000) // Max 10 seconds
    }
  }
}

// Global event listeners for visibility and focus
document.addEventListener('visibilitychange', () => {
  const controller = document.querySelector('[data-controller*="batch-progress"]')
  if (controller && controller.batchProgressController) {
    controller.batchProgressController.handleVisibilityChange()
  }
})

window.addEventListener('focus', () => {
  const controller = document.querySelector('[data-controller*="batch-progress"]')
  if (controller && controller.batchProgressController) {
    controller.batchProgressController.handleFocus()
  }
})

window.addEventListener('blur', () => {
  const controller = document.querySelector('[data-controller*="batch-progress"]')
  if (controller && controller.batchProgressController) {
    controller.batchProgressController.handleBlur()
  }
});
