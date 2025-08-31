import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "applicationsList", "searchInput", "selectedApplication", "createButton"]
  static values = { 
    applicationsUrl: String,
    createUrl: String 
  }

  connect() {
    this.selectedApplicationId = null
    this.applications = []
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Close modal when clicking outside
    if (this.hasModalTarget) {
      this.modalTarget.addEventListener('click', (e) => {
        if (e.target === this.modalTarget) {
          this.closeModal()
        }
      })
    }

    // Close modal with Escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && this.isModalOpen()) {
        this.closeModal()
      }
    })

    // Search functionality
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.addEventListener('input', (e) => {
        this.filterApplications(e.target.value)
      })
    }
  }

  async openModal() {
    try {
      // Show modal
      this.modalTarget.classList.remove('hidden')
      this.modalTarget.classList.add('flex')
      
      // Add animation classes
      setTimeout(() => {
        this.modalTarget.querySelector('.modal-content').classList.remove('scale-95', 'opacity-0')
        this.modalTarget.querySelector('.modal-content').classList.add('scale-100', 'opacity-100')
      }, 10)

      // Load applications
      await this.loadApplications()
      
      // Focus search input
      if (this.hasSearchInputTarget) {
        this.searchInputTarget.focus()
      }
    } catch (error) {
      console.error('Error opening application selector:', error)
      this.showError('Failed to load applications. Please try again.')
    }
  }

  closeModal() {
    // Add closing animation
    this.modalTarget.querySelector('.modal-content').classList.remove('scale-100', 'opacity-100')
    this.modalTarget.querySelector('.modal-content').classList.add('scale-95', 'opacity-0')
    
    // Hide modal after animation
    setTimeout(() => {
      this.modalTarget.classList.add('hidden')
      this.modalTarget.classList.remove('flex')
      this.resetModal()
    }, 200)
  }

  async loadApplications() {
    try {
      const response = await fetch('/api/v1/rental_applications/approved', {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      if (!response.ok) {
        throw new Error('Failed to fetch applications')
      }

      const data = await response.json()
      this.applications = data.applications || []
      this.renderApplications()
    } catch (error) {
      console.error('Error loading applications:', error)
      this.showError('Failed to load applications. Please try again.')
    }
  }

  renderApplications() {
    if (this.applications.length === 0) {
      this.applicationsListTarget.innerHTML = this.getEmptyStateHTML()
      return
    }

    const applicationsHTML = this.applications.map(app => this.getApplicationHTML(app)).join('')
    this.applicationsListTarget.innerHTML = applicationsHTML
  }

  filterApplications(searchTerm) {
    const filteredApps = this.applications.filter(app => {
      const searchText = searchTerm.toLowerCase()
      return (
        app.tenant_name.toLowerCase().includes(searchText) ||
        app.property_address.toLowerCase().includes(searchText) ||
        app.tenant_email.toLowerCase().includes(searchText)
      )
    })

    const applicationsHTML = filteredApps.map(app => this.getApplicationHTML(app)).join('')
    this.applicationsListTarget.innerHTML = applicationsHTML
  }

  selectApplication(event) {
    const applicationId = event.currentTarget.dataset.applicationId
    this.selectedApplicationId = applicationId
    
    // Update UI to show selection
    this.applicationsListTarget.querySelectorAll('.application-item').forEach(item => {
      item.classList.remove('ring-2', 'ring-blue-500', 'bg-blue-50')
    })
    
    event.currentTarget.classList.add('ring-2', 'ring-blue-500', 'bg-blue-50')
    
    // Enable create button
    if (this.hasCreateButtonTarget) {
      this.createButtonTarget.disabled = false
      this.createButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed')
      this.createButtonTarget.classList.add('hover:from-blue-700', 'hover:to-indigo-700')
    }
  }

  async createLeaseFromApplication() {
    if (!this.selectedApplicationId) {
      this.showError('Please select an application first.')
      return
    }

    try {
      // Disable button and show loading
      this.createButtonTarget.disabled = true
      this.createButtonTarget.innerHTML = `
        <svg class="w-4 h-4 mr-2 animate-spin" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path>
        </svg>
        Creating Lease...
      `

      // Navigate to new lease form with application ID
      const url = `/rental_applications/${this.selectedApplicationId}/lease_agreements/new`
      window.location.href = url
      
    } catch (error) {
      console.error('Error creating lease:', error)
      this.showError('Failed to create lease. Please try again.')
      this.resetCreateButton()
    }
  }

  getApplicationHTML(app) {
    return `
      <div class="application-item p-4 border border-gray-200 rounded-2xl hover:border-blue-300 hover:shadow-md transition-all duration-300 cursor-pointer"
           data-action="click->application-selector#selectApplication"
           data-application-id="${app.id}">
        <div class="flex items-center justify-between">
          <div class="flex-1">
            <div class="flex items-center space-x-3">
              <div class="w-10 h-10 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-xl flex items-center justify-center">
                <span class="text-white font-bold text-sm">${app.tenant_name.charAt(0)}</span>
              </div>
              <div>
                <h3 class="font-semibold text-gray-900">${app.tenant_name}</h3>
                <p class="text-sm text-gray-600">${app.tenant_email}</p>
              </div>
            </div>
            <div class="mt-3 grid grid-cols-2 gap-4 text-sm">
              <div>
                <span class="text-gray-500">Property:</span>
                <p class="font-medium text-gray-900">${app.property_address}</p>
              </div>
              <div>
                <span class="text-gray-500">Move-in Date:</span>
                <p class="font-medium text-gray-900">${app.move_in_date}</p>
              </div>
              <div>
                <span class="text-gray-500">Monthly Rent:</span>
                <p class="font-medium text-green-600">$${app.monthly_rent}</p>
              </div>
              <div>
                <span class="text-gray-500">Applied:</span>
                <p class="font-medium text-gray-900">${app.application_date}</p>
              </div>
            </div>
          </div>
          <div class="ml-4">
            <span class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
              Approved
            </span>
          </div>
        </div>
      </div>
    `
  }

  getEmptyStateHTML() {
    return `
      <div class="text-center py-12">
        <svg class="w-16 h-16 mx-auto text-gray-400 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path>
        </svg>
        <h3 class="text-lg font-medium text-gray-900 mb-2">No Approved Applications</h3>
        <p class="text-gray-500">There are no approved applications available to create leases from.</p>
      </div>
    `
  }

  resetModal() {
    this.selectedApplicationId = null
    if (this.hasSearchInputTarget) {
      this.searchInputTarget.value = ''
    }
    this.resetCreateButton()
  }

  resetCreateButton() {
    if (this.hasCreateButtonTarget) {
      this.createButtonTarget.disabled = true
      this.createButtonTarget.classList.add('opacity-50', 'cursor-not-allowed')
      this.createButtonTarget.classList.remove('hover:from-blue-700', 'hover:to-indigo-700')
      this.createButtonTarget.innerHTML = `
        <svg class="w-4 h-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path>
        </svg>
        Create Lease Agreement
      `
    }
  }

  showError(message) {
    // You can implement a toast notification here
    alert(message)
  }

  isModalOpen() {
    return this.hasModalTarget && !this.modalTarget.classList.contains('hidden')
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
  }
};
