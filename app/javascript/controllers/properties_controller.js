import { Controller } from "@hotwired/stimulus"

// Properties Management Stimulus Controller
export default class extends Controller {
  static targets = ["modal", "modalTitle", "modalSubtitle", "searchInput", "filterSelect"]
  static values = { }

  connect() {
    this.currentPropertyId = null
    this.currentPropertyTitle = null
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
    const propertyId = button.dataset.propertyId
    const title = button.dataset.title
    const status = button.dataset.status

    this.currentPropertyId = propertyId
    this.currentPropertyTitle = title
    
    // Update modal content
    this.updateModalTitle(title, status)
    
    // Show modal
    this.modalTarget.classList.remove('hidden')
    document.body.style.overflow = 'hidden'
  }

  // Close modal action
  closeModal() {
    this.modalTarget.classList.add('hidden')
    document.body.style.overflow = 'auto'
    
    // Reset modal state
    this.currentPropertyId = null
    this.currentPropertyTitle = null
  }

  isModalOpen() {
    return this.hasModalTarget && !this.modalTarget.classList.contains('hidden')
  }

  updateModalTitle(title, status) {
    if (this.hasModalTitleTarget) {
      this.modalTitleTarget.textContent = title || 'Property Actions'
    }
    if (this.hasModalSubtitleTarget) {
      this.modalSubtitleTarget.textContent = `Status: ${status} • Choose an action`
    }
  }

  // Property actions
  async viewProperty() {
    if (!this.currentPropertyId) return
    window.open(`/properties/${this.currentPropertyId}`, '_blank')
    this.closeModal()
  }

  async editProperty() {
    if (!this.currentPropertyId) return
    window.location.href = `/properties/${this.currentPropertyId}/edit`
  }

  async deleteProperty() {
    if (!this.currentPropertyId || !this.currentPropertyTitle) return
    
    const confirmed = confirm(`Are you sure you want to delete '${this.currentPropertyTitle}'? This action cannot be undone.`)
    
    if (confirmed) {
      try {
        const response = await fetch(`/properties/${this.currentPropertyId}`, {
          method: 'DELETE',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': this.getCSRFToken()
          }
        })

        if (response.ok) {
          this.showSuccessMessage('Property deleted successfully!')
          window.location.reload()
        } else {
          this.showErrorMessage('Failed to delete property. Please try again.')
        }
      } catch (error) {
        console.error('Error:', error)
        this.showErrorMessage('Failed to delete property. Please try again.')
      }
    }
    
    this.closeModal()
  }

  async duplicateProperty() {
    if (!this.currentPropertyId) return
    
    try {
      const response = await fetch(`/properties/${this.currentPropertyId}/duplicate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      if (response.ok) {
        this.showSuccessMessage('Property duplicated successfully!')
        window.location.reload()
      } else {
        this.showErrorMessage('Failed to duplicate property. Please try again.')
      }
    } catch (error) {
      console.error('Error:', error)
      this.showErrorMessage('Failed to duplicate property. Please try again.')
    }
    
    this.closeModal()
  }

  // Search functionality
  search(event) {
    const query = event.target.value.toLowerCase()
    const rows = document.querySelectorAll('[data-property-row]')
    
    rows.forEach(row => {
      const title = row.dataset.title?.toLowerCase() || ''
      const address = row.dataset.address?.toLowerCase() || ''
      const city = row.dataset.city?.toLowerCase() || ''
      
      const matches = title.includes(query) || address.includes(query) || city.includes(query)
      row.style.display = matches ? '' : 'none'
    })
  }

  // Filter functionality
  filter(event) {
    const status = event.target.value
    const rows = document.querySelectorAll('[data-property-row]')
    
    rows.forEach(row => {
      const propertyStatus = row.dataset.status
      const matches = status === 'all' || propertyStatus === status
      row.style.display = matches ? '' : 'none'
    })
  }

  // Helper methods
  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.getAttribute('content') : ''
  }

  showSuccessMessage(message) {
    // Replace with toast notification system
    alert(message)
  }

  showErrorMessage(message) {
    // Replace with toast notification system
    alert(message)
  }
}
