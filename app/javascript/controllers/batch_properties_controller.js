import { Controller } from "@hotwired/stimulus"

// Batch Properties Stimulus Controller
export default class extends Controller {
  static targets = ["modal", "modalTitle", "modalSubtitle", "viewPropertyBtn", "editPropertyBtn", "retryItemBtn", "propertyDetails", "propertyDetailsContent", "debugData"]
  static values = { batchUploadId: String }

  connect() {
    this.currentPropertyId = null
    this.currentPropertyData = null
    this.bindGlobalEvents()
  }

  disconnect() {
    this.unbindGlobalEvents()
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

  // Open modal action
  openModal(event) {
    const button = event.currentTarget
    const itemId = button.dataset.itemId
    const title = button.dataset.title
    const status = button.dataset.status

    this.currentPropertyId = itemId
    
    // Update modal content
    this.updateModalTitle(title, status, itemId)
    this.updateModalButtons(status)
    
    // Show modal
    this.modalTarget.classList.remove('hidden')
    this.modalTarget.classList.add('flex')
    document.body.style.overflow = 'hidden'
  }

  // Close modal action
  closeModal() {
    this.modalTarget.classList.add('hidden')
    this.modalTarget.classList.remove('flex')
    document.body.style.overflow = 'auto'
    
    // Reset modal state
    this.hideDetails()
    this.hideDebugData()
    this.currentPropertyId = null
    this.currentPropertyData = null
  }

  isModalOpen() {
    return this.hasModalTarget && !this.modalTarget.classList.contains('hidden')
  }

  updateModalTitle(title, status, itemId) {
    if (this.hasModalTitleTarget) {
      this.modalTitleTarget.textContent = title || 'Property Actions'
    }
    if (this.hasModalSubtitleTarget) {
      this.modalSubtitleTarget.textContent = `Status: ${status} • Row ${itemId}`
    }
  }

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

  showElement(element) {
    if (element) element.style.display = 'flex'
  }

  hideElement(element) {
    if (element) element.style.display = 'none'
  }

  hideDetails() {
    if (this.hasPropertyDetailsTarget) {
      this.propertyDetailsTarget.classList.add('hidden')
    }
  }

  hideDebugData() {
    if (this.hasDebugDataTarget) {
      this.debugDataTarget.classList.add('hidden')
    }
  }

  // Property actions
  async viewProperty() {
    if (!this.currentPropertyId) return
    window.open(`/properties/${this.currentPropertyId}`, '_blank')
  }

  async editProperty() {
    if (!this.currentPropertyId) return
    window.open(`/properties/${this.currentPropertyId}/edit`, '_blank')
  }

  async retryItem() {
    if (!this.currentPropertyId) return
    
    const retryBtn = this.retryItemBtnTarget
    if (!retryBtn) return

    // Show loading state
    const originalContent = retryBtn.innerHTML
    retryBtn.innerHTML = this.getLoadingHTML()
    retryBtn.disabled = true
    
    try {
      const response = await fetch(`/batch_properties/${this.batchUploadIdValue}/retry_item/${this.currentPropertyId}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      const data = await response.json()
      
      if (data.success) {
        this.showSuccessMessage('Item retry initiated successfully!')
        window.location.reload()
      } else {
        this.showErrorMessage('Failed to retry item: ' + (data.error || 'Unknown error'))
      }
    } catch (error) {
      console.error('Error:', error)
      this.showErrorMessage('Failed to retry item. Please try again.')
    } finally {
      retryBtn.innerHTML = originalContent
      retryBtn.disabled = false
    }
  }

  async viewDetails() {
    if (!this.hasPropertyDetailsTarget || !this.hasPropertyDetailsContentTarget) return

    if (this.propertyDetailsTarget.classList.contains('hidden')) {
      try {
        const data = await this.fetchPropertyDetails()
        this.propertyDetailsContentTarget.innerHTML = this.formatPropertyDetails(data)
        this.propertyDetailsTarget.classList.remove('hidden')
      } catch (error) {
        this.propertyDetailsContentTarget.innerHTML = '<p class="text-red-600">Failed to load property details</p>'
        this.propertyDetailsTarget.classList.remove('hidden')
      }
    } else {
      this.propertyDetailsTarget.classList.add('hidden')
    }
  }

  async toggleDebugData() {
    if (!this.hasDebugDataTarget) return

    if (this.debugDataTarget.classList.contains('hidden')) {
      try {
        const data = await this.fetchPropertyDetails()
        this.debugDataTarget.innerHTML = '<pre>' + JSON.stringify(data, null, 2) + '</pre>'
        this.debugDataTarget.classList.remove('hidden')
      } catch (error) {
        this.debugDataTarget.innerHTML = '<pre>Failed to load debug data</pre>'
        this.debugDataTarget.classList.remove('hidden')
      }
    } else {
      this.debugDataTarget.classList.add('hidden')
    }
  }

  async fetchPropertyDetails() {
    const response = await fetch(`/batch_properties/${this.batchUploadIdValue}/item_details/${this.currentPropertyId}`)
    if (!response.ok) throw new Error('Failed to fetch details')
    return response.json()
  }

  formatPropertyDetails(data) {
    const propertyData = JSON.parse(data.property_data)
    let html = ''
    
    Object.entries(propertyData).forEach(([key, value]) => {
      html += `
        <div class="flex justify-between py-2 border-b border-gray-200">
          <span class="font-medium text-gray-700">${this.formatFieldName(key)}:</span>
          <span class="text-gray-900">${value || 'N/A'}</span>
        </div>
      `
    })
    
    if (data.error_message) {
      html += `
        <div class="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg">
          <h5 class="font-medium text-red-800">Error Message:</h5>
          <p class="text-red-700 text-sm mt-1">${data.error_message}</p>
        </div>
      `
    }
    
    return html
  }

  formatFieldName(fieldName) {
    return fieldName.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())
  }

  getLoadingHTML() {
    return '<div class="animate-spin w-4 h-4 border-2 border-orange-600 border-t-transparent rounded-full"></div> Retrying...'
  }

  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }

  showSuccessMessage(message) {
    alert(message) // Replace with toast notification system
  }

  showErrorMessage(message) {
    alert(message) // Replace with toast notification system
  }
}
