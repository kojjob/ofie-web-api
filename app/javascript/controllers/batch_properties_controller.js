import { Controller } from "@hotwired/stimulus"

// Enhanced Batch Properties Stimulus Controller with better UX and accessibility
export default class extends Controller {
  static targets = [
    // Modal targets
    "modal", "modalContent", "modalTitle", "modalSubtitle", 
    "viewPropertyBtn", "editPropertyBtn", "retryItemBtn", 
    "propertySummary", "summaryTitle", "summaryStatus",
    
    // Details targets
    "propertyDetails", "propertyDetailsContent", "detailsChevron",
    "detailsLoading", "detailsError",
    
    // Confirmation targets
    "retryConfirmation", "confirmRetryBtn",
    
    // Toast targets
    "toastContainer", "toastTemplate",
    
    // Pagination targets
    "tableContainer", "paginationContainer",
    
    // Debug targets
    "debugData"
  ]
  
  static values = { 
    batchUploadId: String 
  }

  connect() {
    this.currentItemId = null
    this.currentPropertyId = null
    this.currentPropertyData = null
    this.focusedElementBeforeModal = null
    this.bindGlobalEvents()
    this.initializeToastSystem()
  }

  disconnect() {
    this.unbindGlobalEvents()
    this.clearAllToasts()
  }

  bindGlobalEvents() {
    this.handleEscapeKey = this.handleEscapeKey.bind(this)
    this.handleModalClick = this.handleModalClick.bind(this)
    
    document.addEventListener('keydown', this.handleEscapeKey)
    if (this.hasModalTarget) {
      this.modalTarget.addEventListener('click', this.handleModalClick)
    }
  }

  unbindGlobalEvents() {
    document.removeEventListener('keydown', this.handleEscapeKey)
    if (this.hasModalTarget) {
      this.modalTarget.removeEventListener('click', this.handleModalClick)
    }
  }

  handleEscapeKey(event) {
    if (event.key === 'Escape' && this.isModalOpen()) {
      this.closeModal()
    }
  }

  handleModalClick(event) {
    if (event.target === this.modalTarget) {
      this.closeModal()
    }
  }

  // ==================== ENHANCED MODAL METHODS ====================

  /**
   * Open modal with enhanced accessibility and animations
   */
  openModal(event) {
    const button = event.currentTarget
    const itemId = button.dataset.itemId
    const title = button.dataset.title
    const status = button.dataset.status
    const propertyId = button.dataset.propertyId

    // Store current focus for restoration
    this.focusedElementBeforeModal = document.activeElement

    // Update modal state
    this.currentItemId = itemId
    this.currentPropertyId = propertyId

    // Update modal content
    this.updateModalContent(title, status, itemId, propertyId)
    this.updateModalButtons(status)

    // Show modal with animation
    this.showModalWithAnimation()

    // Set focus for accessibility
    this.setModalFocus()

    // Hide any expanded sections
    this.hideAllExpandedSections()
  }

  /**
   * Close modal with proper cleanup
   */
  closeModal() {
    if (!this.isModalOpen()) return

    // Hide modal with animation
    this.hideModalWithAnimation()

    // Reset modal state
    setTimeout(() => {
      this.resetModalState()
      this.restoreFocus()
    }, 300) // Wait for animation to complete
  }

  /**
   * Show modal with smooth animation
   */
  showModalWithAnimation() {
    const modal = this.modalTarget
    const content = this.modalContentTarget

    // Show modal
    modal.classList.remove('hidden')
    document.body.style.overflow = 'hidden'

    // Animate in
    requestAnimationFrame(() => {
      modal.classList.remove('opacity-0')
      modal.classList.add('opacity-100')
      
      content.classList.remove('scale-95', 'opacity-0')
      content.classList.add('scale-100', 'opacity-100')
    })
  }

  /**
   * Hide modal with smooth animation
   */
  hideModalWithAnimation() {
    const modal = this.modalTarget
    const content = this.modalContentTarget

    // Animate out
    modal.classList.remove('opacity-100')
    modal.classList.add('opacity-0')
    
    content.classList.remove('scale-100', 'opacity-100')
    content.classList.add('scale-95', 'opacity-0')

    // Hide after animation
    setTimeout(() => {
      modal.classList.add('hidden')
      document.body.style.overflow = 'auto'
    }, 300)
  }

  /**
   * Update modal content with property information
   */
  updateModalContent(title, status, itemId, propertyId) {
    // Update title and subtitle
    if (this.hasModalTitleTarget) {
      this.modalTitleTarget.textContent = title || 'Property Actions'
    }
    
    if (this.hasModalSubtitleTarget) {
      this.modalSubtitleTarget.textContent = `Row ${itemId} • Status: ${status}`
    }

    // Update property summary
    if (this.hasSummaryTitleTarget) {
      this.summaryTitleTarget.textContent = title || 'Property'
    }
    
    if (this.hasSummaryStatusTarget) {
      this.summaryStatusTarget.textContent = `Status: ${this.humanizeStatus(status)}`
    }
  }

  /**
   * Update modal buttons based on status
   */
  updateModalButtons(status) {
    // Show/hide buttons based on status
    if (status === 'completed') {
      this.showElement(this.viewPropertyBtnTarget)
      this.showElement(this.editPropertyBtnTarget)
      this.hideElement(this.retryItemBtnTarget)
    } else if (status === 'failed') {
      this.hideElement(this.viewPropertyBtnTarget)
      this.hideElement(this.editPropertyBtnTarget)
      this.showElement(this.retryItemBtnTarget)
    } else {
      this.hideElement(this.viewPropertyBtnTarget)
      this.hideElement(this.editPropertyBtnTarget)
      this.hideElement(this.retryItemBtnTarget)
    }
  }

  /**
   * Set focus for modal accessibility
   */
  setModalFocus() {
    // Focus first interactive element in modal
    const firstButton = this.modalTarget.querySelector('button:not([disabled]):not(.hidden)')
    if (firstButton) {
      setTimeout(() => firstButton.focus(), 100)
    }
  }

  /**
   * Restore focus to element that opened modal
   */
  restoreFocus() {
    if (this.focusedElementBeforeModal) {
      this.focusedElementBeforeModal.focus()
      this.focusedElementBeforeModal = null
    }
  }

  /**
   * Reset modal to initial state
   */
  resetModalState() {
    this.hideAllExpandedSections()
    this.currentItemId = null
    this.currentPropertyId = null
    this.currentPropertyData = null
  }

  /**
   * Hide all expanded sections
   */
  hideAllExpandedSections() {
    if (this.hasPropertyDetailsTarget) {
      this.propertyDetailsTarget.classList.add('hidden')
    }
    if (this.hasRetryConfirmationTarget) {
      this.retryConfirmationTarget.classList.add('hidden')
    }
    if (this.hasDebugDataTarget) {
      this.debugDataTarget.classList.add('hidden')
    }
  }

  isModalOpen() {
    return this.hasModalTarget && !this.modalTarget.classList.contains('hidden')
  }

  // ==================== PROPERTY ACTIONS ====================

  /**
   * View property in new tab
   */
  async viewProperty() {
    if (!this.currentPropertyId) {
      this.showToast('error', 'Error', 'No property ID available')
      return
    }
    
    window.open(`/properties/${this.currentPropertyId}`, '_blank')
    this.showToast('info', 'Opening Property', 'Property details opened in new tab')
  }

  /**
   * Edit property in new tab
   */
  async editProperty() {
    if (!this.currentPropertyId) {
      this.showToast('error', 'Error', 'No property ID available')
      return
    }
    
    window.open(`/properties/${this.currentPropertyId}/edit`, '_blank')
    this.showToast('info', 'Opening Editor', 'Property editor opened in new tab')
  }

  /**
   * Show retry confirmation
   */
  showRetryConfirmation() {
    if (this.hasRetryConfirmationTarget) {
      this.retryConfirmationTarget.classList.remove('hidden')
    }
  }

  /**
   * Cancel retry operation
   */
  cancelRetry() {
    if (this.hasRetryConfirmationTarget) {
      this.retryConfirmationTarget.classList.add('hidden')
    }
  }

  /**
   * Confirm and execute retry
   */
  async confirmRetry() {
    if (!this.currentItemId) {
      this.showToast('error', 'Error', 'No item selected for retry')
      return
    }

    const confirmBtn = this.confirmRetryBtnTarget
    if (!confirmBtn) return

    // Show loading state
    const originalContent = confirmBtn.innerHTML
    confirmBtn.innerHTML = this.getLoadingHTML('Retrying...')
    confirmBtn.disabled = true

    try {
      const response = await fetch(`/batch_properties/${this.batchUploadIdValue}/retry_item/${this.currentItemId}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      const data = await response.json()

      if (data.success) {
        this.showToast('success', 'Retry Initiated', 'Item has been queued for reprocessing')
        setTimeout(() => {
          window.location.reload()
        }, 1500)
      } else {
        this.showToast('error', 'Retry Failed', data.error || 'Unknown error occurred')
      }
    } catch (error) {
      console.error('Retry error:', error)
      this.showToast('error', 'Network Error', 'Failed to communicate with server')
    } finally {
      confirmBtn.innerHTML = originalContent
      confirmBtn.disabled = false
      
      // Hide confirmation section
      if (this.hasRetryConfirmationTarget) {
        this.retryConfirmationTarget.classList.add('hidden')
      }
    }
  }

  /**
   * Toggle property details section
   */
  async toggleDetails() {
    if (!this.hasPropertyDetailsTarget) return

    const isVisible = !this.propertyDetailsTarget.classList.contains('hidden')
    
    if (isVisible) {
      // Hide details
      this.propertyDetailsTarget.classList.add('hidden')
      this.rotateChevron(false)
    } else {
      // Show details and load data
      this.propertyDetailsTarget.classList.remove('hidden')
      this.rotateChevron(true)
      await this.loadPropertyDetails()
    }
  }

  /**
   * Load property details with loading states
   */
  async loadPropertyDetails() {
    if (!this.hasPropertyDetailsContentTarget) return

    // Show loading state
    this.showElement(this.detailsLoadingTarget)
    this.hideElement(this.propertyDetailsContentTarget)
    this.hideElement(this.detailsErrorTarget)

    try {
      const data = await this.fetchPropertyDetails()
      
      // Hide loading, show content
      this.hideElement(this.detailsLoadingTarget)
      this.showElement(this.propertyDetailsContentTarget)
      
      // Populate content
      this.propertyDetailsContentTarget.innerHTML = this.formatPropertyDetails(data)
      
    } catch (error) {
      console.error('Error loading details:', error)
      
      // Hide loading, show error
      this.hideElement(this.detailsLoadingTarget)
      this.showElement(this.detailsErrorTarget)
    }
  }

  /**
   * Rotate chevron icon for details section
   */
  rotateChevron(expanded) {
    if (this.hasDetailsChevronTarget) {
      const chevron = this.detailsChevronTarget
      if (expanded) {
        chevron.style.transform = 'rotate(180deg)'
      } else {
        chevron.style.transform = 'rotate(0deg)'
      }
    }
  }

  /**
   * Toggle debug data (development only)
   */
  async toggleDebugData() {
    if (!this.hasDebugDataTarget) return

    if (this.debugDataTarget.classList.contains('hidden')) {
      try {
        const data = await this.fetchPropertyDetails()
        this.debugDataTarget.innerHTML = `<pre>${JSON.stringify(data, null, 2)}</pre>`
        this.debugDataTarget.classList.remove('hidden')
      } catch (error) {
        this.debugDataTarget.innerHTML = '<pre>Failed to load debug data</pre>'
        this.debugDataTarget.classList.remove('hidden')
      }
    } else {
      this.debugDataTarget.classList.add('hidden')
    }
  }

  // ==================== TOAST NOTIFICATION SYSTEM ====================

  /**
   * Initialize toast notification system
   */
  initializeToastSystem() {
    this.toastQueue = []
    this.maxToasts = 5
  }

  /**
   * Show toast notification
   */
  showToast(type, title, message, duration = 5000) {
    if (!this.hasToastContainerTarget || !this.hasToastTemplateTarget) {
      // Fallback to alert if toast system not available
      alert(`${title}: ${message}`)
      return
    }

    // Create toast element from template
    const template = this.toastTemplateTarget
    const toast = template.content.cloneNode(true).querySelector('.toast')
    
    // Configure toast
    this.configureToast(toast, type, title, message, duration)
    
    // Add to container
    this.toastContainerTarget.appendChild(toast)
    
    // Animate in
    requestAnimationFrame(() => {
      toast.classList.add('show')
    })
    
    // Auto-remove after duration
    setTimeout(() => {
      this.removeToast(toast)
    }, duration)
    
    // Limit number of toasts
    this.limitToasts()
  }

  /**
   * Configure toast appearance and behavior
   */
  configureToast(toast, type, title, message, duration) {
    // Add type class
    toast.classList.add(`toast-${type}`)
    
    // Set content
    toast.querySelector('.toast-title').textContent = title
    toast.querySelector('.toast-message').textContent = message
    
    // Set icon
    const iconContainer = toast.querySelector('.toast-icon')
    iconContainer.innerHTML = this.getToastIcon(type)
    
    // Configure progress bar
    const progressBar = toast.querySelector('.toast-progress-bar')
    progressBar.style.transitionDuration = `${duration}ms`
    
    // Add close handler
    const closeBtn = toast.querySelector('.toast-close')
    closeBtn.addEventListener('click', () => this.removeToast(toast))
    
    // Start progress animation
    setTimeout(() => {
      progressBar.style.width = '0%'
    }, 100)
  }

  /**
   * Get icon SVG for toast type
   */
  getToastIcon(type) {
    const icons = {
      success: `<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
      </svg>`,
      error: `<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
      </svg>`,
      warning: `<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
      </svg>`,
      info: `<svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/>
      </svg>`
    }
    
    return icons[type] || icons.info
  }

  /**
   * Remove toast with animation
   */
  removeToast(toast) {
    toast.classList.remove('show')
    toast.classList.add('hide')
    
    setTimeout(() => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast)
      }
    }, 300)
  }

  /**
   * Limit number of visible toasts
   */
  limitToasts() {
    if (!this.hasToastContainerTarget) return
    
    const toasts = this.toastContainerTarget.querySelectorAll('.toast')
    if (toasts.length > this.maxToasts) {
      const oldestToast = toasts[0]
      this.removeToast(oldestToast)
    }
  }

  /**
   * Clear all toasts
   */
  clearAllToasts() {
    if (!this.hasToastContainerTarget) return
    
    const toasts = this.toastContainerTarget.querySelectorAll('.toast')
    toasts.forEach(toast => this.removeToast(toast))
  }

  // ==================== PAGINATION METHODS (Enhanced) ====================

  /**
   * Handle pagination click with better UX
   */
  async handlePaginationClick(event) {
    event.preventDefault()
    const pageNumber = event.currentTarget.dataset.page
    if (!pageNumber) return

    // Show loading state
    this.showPaginationLoading()
    
    try {
      await this.loadPageNumber(pageNumber)
      this.showToast('success', 'Page Loaded', `Switched to page ${pageNumber}`)
    } catch (error) {
      console.error('Pagination error:', error)
      this.showToast('error', 'Loading Failed', 'Failed to load page. Please try again.')
      this.showPaginationError('Failed to load page. Please try again.')
    } finally {
      this.hidePaginationLoading()
    }
  }

  /**
   * Load specific page number
   */
  async loadPageNumber(pageNumber) {
    const currentUrl = new URL(window.location)
    currentUrl.searchParams.set('page', pageNumber)
    
    const response = await fetch(currentUrl.toString(), {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': this.getCSRFToken()
      },
      credentials: 'same-origin'
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()
    this.updateTableContent(data)
    
    // Update browser URL without page reload
    window.history.pushState({ page: pageNumber }, '', currentUrl.toString())
  }

  /**
   * Update table content with enhanced animations
   */
  updateTableContent(data) {
    if (!this.hasTableContainerTarget) return

    const tbody = this.tableContainerTarget.querySelector('tbody')
    if (!tbody) return

    // Fade out current content
    tbody.style.opacity = '0.5'
    
    setTimeout(() => {
      // Clear existing rows
      tbody.innerHTML = ''

      // Add new rows
      if (data.items && data.items.length > 0) {
        data.items.forEach(item => {
          const row = this.createTableRow(item)
          tbody.appendChild(row)
        })
      } else {
        tbody.innerHTML = this.getEmptyStateHTML()
      }

      // Update pagination if provided
      if (data.pagination) {
        this.updatePaginationControls(data.pagination)
      }

      // Fade in new content
      tbody.style.opacity = '1'
    }, 150)
  }

  /**
   * Show pagination loading state
   */
  showPaginationLoading() {
    if (this.hasPaginationContainerTarget) {
      const loadingHTML = `
        <div class="flex items-center justify-center py-8">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <span class="ml-3 text-gray-600">Loading page...</span>
        </div>
      `
      this.paginationContainerTarget.innerHTML = loadingHTML
    }

    if (this.hasTableContainerTarget) {
      this.tableContainerTarget.style.pointerEvents = 'none'
    }
  }

  /**
   * Hide pagination loading state
   */
  hidePaginationLoading() {
    if (this.hasTableContainerTarget) {
      this.tableContainerTarget.style.pointerEvents = 'auto'
    }
  }

  /**
   * Show pagination error
   */
  showPaginationError(message) {
    if (this.hasPaginationContainerTarget) {
      const errorHTML = `
        <div class="flex items-center justify-center py-8 text-red-600">
          <svg class="w-6 h-6 mr-3" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
          </svg>
          <span>${message}</span>
        </div>
      `
      this.paginationContainerTarget.innerHTML = errorHTML
    }
  }

  // ==================== UTILITY METHODS ====================

  async fetchPropertyDetails() {
    const response = await fetch(`/batch_properties/${this.batchUploadIdValue}/item_details/${this.currentItemId}`)
    if (!response.ok) throw new Error('Failed to fetch details')
    return response.json()
  }

  formatPropertyDetails(data) {
    const propertyData = JSON.parse(data.property_data)
    let html = '<div class="space-y-3">'
    
    // Group related fields
    const fieldGroups = {
      'Basic Information': ['title', 'description', 'property_type'],
      'Location': ['address', 'city', 'state', 'zip_code'],
      'Details': ['price', 'bedrooms', 'bathrooms', 'square_feet'],
      'Features': ['parking_available', 'pets_allowed', 'furnished', 'utilities_included']
    }
    
    Object.entries(fieldGroups).forEach(([groupName, fields]) => {
      const groupData = fields.filter(field => propertyData[field] !== undefined && propertyData[field] !== '')
      
      if (groupData.length > 0) {
        html += `
          <div class="bg-white rounded-lg p-3 border border-gray-200">
            <h5 class="font-medium text-gray-900 mb-2 text-xs uppercase tracking-wide">${groupName}</h5>
            <div class="space-y-1">
        `
        
        groupData.forEach(field => {
          const value = propertyData[field]
          html += `
            <div class="flex justify-between text-sm">
              <span class="text-gray-600">${this.formatFieldName(field)}:</span>
              <span class="text-gray-900 font-medium">${this.formatFieldValue(field, value)}</span>
            </div>
          `
        })
        
        html += '</div></div>'
      }
    })
    
    // Add error message if present
    if (data.error_message) {
      html += `
        <div class="bg-red-50 border border-red-200 rounded-lg p-3">
          <h5 class="font-medium text-red-800 text-xs uppercase tracking-wide mb-1">Error Details</h5>
          <p class="text-red-700 text-sm">${data.error_message}</p>
        </div>
      `
    }
    
    html += '</div>'
    return html
  }

  formatFieldName(fieldName) {
    return fieldName.replace(/_/g, ' ')
                   .replace(/\b\w/g, l => l.toUpperCase())
  }

  formatFieldValue(field, value) {
    if (value === null || value === undefined) return 'N/A'
    
    // Format specific field types
    if (field === 'price') {
      return `$${new Intl.NumberFormat().format(value)}`
    }
    
    if (field.includes('_available') || field.includes('_allowed') || field.includes('_included') || field === 'furnished') {
      return value ? 'Yes' : 'No'
    }
    
    if (field === 'square_feet') {
      return `${new Intl.NumberFormat().format(value)} sq ft`
    }
    
    return value.toString()
  }

  humanizeStatus(status) {
    const statusMap = {
      'pending': 'Pending',
      'processing': 'Processing',
      'completed': 'Completed',
      'failed': 'Failed'
    }
    return statusMap[status] || status.charAt(0).toUpperCase() + status.slice(1)
  }

  showElement(element) {
    if (element) {
      element.classList.remove('hidden')
      element.style.display = ''
    }
  }

  hideElement(element) {
    if (element) {
      element.classList.add('hidden')
      element.style.display = 'none'
    }
  }

  getLoadingHTML(text = 'Loading...') {
    return `
      <div class="flex items-center">
        <div class="animate-spin rounded-full h-4 w-4 border-2 border-current border-t-transparent mr-2"></div>
        ${text}
      </div>
    `
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }

  // ==================== TABLE ROW CREATION ====================

  createTableRow(item) {
    const propertyData = JSON.parse(item.property_data)
    const row = document.createElement('tr')
    row.className = 'hover:bg-gray-50 transition-colors duration-200'
    
    row.innerHTML = `
      <td class="px-6 py-4 whitespace-nowrap">
        <div class="flex items-center">
          <div class="flex-shrink-0 h-12 w-12">
            <div class="h-12 w-12 rounded-lg bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2H5a2 2 0 00-2-2z"/>
              </svg>
            </div>
          </div>
          <div class="ml-4">
            <div class="text-sm font-medium text-gray-900">Row ${item.row_number}</div>
            <div class="text-sm text-gray-500">ID: ${item.id}</div>
          </div>
        </div>
      </td>
      <td class="px-6 py-4">
        <div class="text-sm font-medium text-gray-900 max-w-xs">
          ${this.truncateText(propertyData.title, 40)}
        </div>
        <div class="text-sm text-gray-500 max-w-xs">
          ${this.truncateText(propertyData.description, 60)}
        </div>
      </td>
      <td class="px-6 py-4">
        <div class="text-sm text-gray-900 max-w-xs">
          ${this.truncateText(propertyData.address, 30)}
        </div>
        <div class="text-sm text-gray-500">
          ${propertyData.city || ''}
        </div>
      </td>
      <td class="px-6 py-4 whitespace-nowrap">
        <div class="text-sm font-semibold text-green-600">
          $${this.formatNumber(propertyData.price)}
        </div>
        <div class="text-sm text-gray-500">
          ${propertyData.bedrooms || 0}bd / ${propertyData.bathrooms || 0}ba
        </div>
      </td>
      <td class="px-6 py-4 whitespace-nowrap">
        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
          ${this.humanizeText(propertyData.property_type)}
        </span>
      </td>
      <td class="px-6 py-4 whitespace-nowrap">
        ${this.createStatusBadge(item)}
      </td>
      <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
        <div class="flex items-center justify-end space-x-2">
          ${item.property_id ? this.createViewPropertyLink(item.property_id) : ''}
          ${this.createActionButton(item, propertyData)}
        </div>
        ${item.error_message ? this.createErrorMessage(item.error_message) : ''}
      </td>
    `
    
    return row
  }

  truncateText(text, length) {
    if (!text) return ''
    return text.length > length ? text.substring(0, length) + '...' : text
  }

  formatNumber(number) {
    if (!number) return '0'
    return new Intl.NumberFormat().format(number)
  }

  humanizeText(text) {
    if (!text) return ''
    return text.charAt(0).toUpperCase() + text.slice(1).replace(/_/g, ' ')
  }

  createStatusBadge(item) {
    const statusClasses = {
      'pending': 'bg-yellow-100 text-yellow-800',
      'completed': 'bg-green-100 text-green-800', 
      'failed': 'bg-red-100 text-red-800',
      'processing': 'bg-blue-100 text-blue-800'
    }
    
    const statusClass = statusClasses[item.status] || 'bg-gray-100 text-gray-800'
    
    return `
      <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${statusClass}">
        ${this.humanizeText(item.status)}
      </span>
    `
  }

  createViewPropertyLink(propertyId) {
    return `
      <a href="/properties/${propertyId}" target="_blank" 
         class="text-blue-600 hover:text-blue-900 transition-colors duration-200" 
         title="View Property">
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
        </svg>
      </a>
    `
  }

  createActionButton(item, propertyData) {
    return `
      <button type="button"
              class="text-gray-400 hover:text-gray-600 transition-colors duration-200 p-1 rounded-full hover:bg-gray-100"
              data-action="click->batch-properties#openModal"
              data-item-id="${item.id}"
              data-property-id="${item.property_id || ''}"
              data-title="${this.escapeHtml(propertyData.title || '')}"
              data-status="${item.status}"
              title="More Actions">
        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path d="M10 6a2 2 0 110-4 2 2 0 010 4zM10 12a2 2 0 110-4 2 2 0 010 4zM10 18a2 2 0 110-4 2 2 0 010 4z"/>
        </svg>
      </button>
    `
  }

  createErrorMessage(errorMessage) {
    return `
      <div class="mt-2 text-xs text-red-600 max-w-xs">
        ${this.truncateText(errorMessage, 100)}
      </div>
    `
  }

  getEmptyStateHTML() {
    return `
      <tr>
        <td colspan="7" class="px-6 py-12 text-center">
          <div class="text-gray-500">
            <svg class="w-12 h-12 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
            </svg>
            <p class="text-lg font-medium text-gray-900 mb-2">No properties found</p>
            <p class="text-gray-500">Try adjusting your search or upload more properties.</p>
          </div>
        </td>
      </tr>
    `
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  updatePaginationControls(pagination) {
    // This method would update pagination controls based on the data
    // Implementation depends on your pagination component structure
  }
}
