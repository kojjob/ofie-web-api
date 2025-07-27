import { Controller } from "@hotwired/stimulus"

// Properties Management Stimulus Controller
export default class extends Controller {
  static targets = ["searchInput", "filterSelect"]
  static values = { }

  connect() {
    this.currentDropdown = null
    this.bindGlobalEvents()
  }

  disconnect() {
    this.unbindGlobalEvents()
  }

  bindGlobalEvents() {
    this.handleClickOutside = this.handleClickOutside.bind(this)
    this.handleEscapeKey = this.handleEscapeKey.bind(this)

    document.addEventListener('click', this.handleClickOutside)
    document.addEventListener('keydown', this.handleEscapeKey)
  }

  unbindGlobalEvents() {
    document.removeEventListener('click', this.handleClickOutside)
    document.removeEventListener('keydown', this.handleEscapeKey)
  }

  handleClickOutside(event) {
    if (this.currentDropdown && !this.currentDropdown.contains(event.target)) {
      this.closeAllDropdowns()
    }
  }

  handleEscapeKey(event) {
    if (event.key === 'Escape') {
      this.closeAllDropdowns()
    }
  }

  // Toggle dropdown action
  toggleDropdown(event) {
    event.preventDefault()
    event.stopPropagation()

    const button = event.currentTarget
    const dropdown = button.nextElementSibling

    // Close other dropdowns first
    this.closeAllDropdowns()

    if (dropdown && dropdown.hasAttribute('data-dropdown')) {
      // Show this dropdown
      dropdown.classList.remove('hidden')
      this.currentDropdown = dropdown
    }
  }

  closeAllDropdowns() {
    const dropdowns = document.querySelectorAll('[data-dropdown]')
    dropdowns.forEach(dropdown => {
      dropdown.classList.add('hidden')
    })
    this.currentDropdown = null
  }

  // Property actions
  async viewProperty(event) {
    const propertyId = event.currentTarget.dataset.propertyId
    if (!propertyId) return

    window.open(`/properties/${propertyId}`, '_blank')
    this.closeAllDropdowns()
  }

  async editProperty(event) {
    const propertyId = event.currentTarget.dataset.propertyId
    if (!propertyId) return

    window.location.href = `/properties/${propertyId}/edit`
  }

  async deleteProperty(event) {
    const propertyId = event.currentTarget.dataset.propertyId
    const propertyTitle = event.currentTarget.dataset.propertyTitle

    if (!propertyId || !propertyTitle) return

    const confirmed = confirm(`Are you sure you want to delete '${propertyTitle}'? This action cannot be undone.`)

    if (confirmed) {
      try {
        const response = await fetch(`/properties/${propertyId}`, {
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

    this.closeAllDropdowns()
  }

  async duplicateProperty(event) {
    const propertyId = event.currentTarget.dataset.propertyId
    if (!propertyId) return

    try {
      const response = await fetch(`/properties/${propertyId}/duplicate`, {
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

    this.closeAllDropdowns()
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
