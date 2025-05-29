import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["input", "results"]
  static values = { url: String }

  connect() {
    this.timeout = null
    this.minQueryLength = 2
  }

  search() {
    const query = this.inputTarget.value.trim()
    
    if (query.length < this.minQueryLength) {
      this.hideResults()
      return
    }

    // Clear previous timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Debounce search requests
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 300)
  }

  async performSearch(query) {
    try {
      const url = new URL(this.urlValue || '/properties/search', window.location.origin)
      url.searchParams.set('q', query)
      url.searchParams.set('format', 'json')

      const response = await fetch(url)
      const data = await response.json()
      
      this.displayResults(data.properties || [])
    } catch (error) {
      console.error('Search error:', error)
      this.hideResults()
    }
  }

  displayResults(properties) {
    if (!this.hasResultsTarget) return

    if (properties.length === 0) {
      this.resultsTarget.innerHTML = `
        <div class="p-4 text-center text-gray-500">
          <p>No properties found</p>
        </div>
      `
    } else {
      this.resultsTarget.innerHTML = properties.map(property => `
        <a href="/properties/${property.id}" class="block p-3 hover:bg-gray-50 border-b border-gray-100 last:border-b-0">
          <div class="flex items-center space-x-3">
            <div class="flex-shrink-0">
              <div class="h-10 w-10 bg-blue-100 rounded-lg flex items-center justify-center">
                <svg class="h-5 w-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"></path>
                </svg>
              </div>
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-sm font-medium text-gray-900 truncate">${property.title}</p>
              <p class="text-sm text-gray-500 truncate">${property.location}</p>
              <p class="text-sm font-semibold text-blue-600">$${property.price}/month</p>
            </div>
          </div>
        </a>
      `).join('')
    }

    this.showResults()
  }

  showResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.remove('hidden')
    }
  }

  hideResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.add('hidden')
    }
  }

  clear() {
    this.inputTarget.value = ''
    this.hideResults()
  }

  // Hide results when clicking outside
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }
}