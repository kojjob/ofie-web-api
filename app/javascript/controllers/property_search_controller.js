import { Controller } from "@hotwired/stimulus"

// Property search controller with real-time filtering
export default class extends Controller {
  static targets = ["input", "results", "loading", "filters", "count"]
  static values = { 
    url: String,
    delay: { type: Number, default: 300 }
  }

  connect() {
    this.searchTimeout = null
    this.currentRequest = null
    console.log("Property search controller connected")
  }

  disconnect() {
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }
    if (this.currentRequest) {
      this.currentRequest.abort()
    }
  }

  // Handle search input changes
  search() {
    // Clear existing timeout
    if (this.searchTimeout) {
      clearTimeout(this.searchTimeout)
    }

    // Set new timeout for debouncing
    this.searchTimeout = setTimeout(() => {
      this.performSearch()
    }, this.delayValue)
  }

  // Handle filter changes
  filterChanged() {
    this.performSearch()
  }

  // Clear all filters
  clearFilters() {
    this.filtersTarget.querySelectorAll('input[type="text"], input[type="number"]').forEach(input => {
      input.value = ''
    })
    this.filtersTarget.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
      checkbox.checked = false
    })
    this.filtersTarget.querySelectorAll('select').forEach(select => {
      select.selectedIndex = 0
    })
    this.performSearch()
  }

  // Perform the actual search
  async performSearch() {
    // Cancel any existing request
    if (this.currentRequest) {
      this.currentRequest.abort()
    }

    // Show loading state
    this.showLoading()

    // Build search parameters
    const params = this.buildSearchParams()
    const url = `${this.urlValue}?${params.toString()}`

    try {
      // Create abort controller for this request
      const abortController = new AbortController()
      this.currentRequest = abortController

      const response = await fetch(url, {
        signal: abortController.signal,
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      this.displayResults(data)
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error('Search error:', error)
        this.displayError(error.message)
      }
    } finally {
      this.hideLoading()
      this.currentRequest = null
    }
  }

  // Build search parameters from form inputs
  buildSearchParams() {
    const params = new URLSearchParams()

    // Add search query
    if (this.hasInputTarget && this.inputTarget.value) {
      params.append('q', this.inputTarget.value)
    }

    // Add filters
    if (this.hasFiltersTarget) {
      // Text and number inputs
      this.filtersTarget.querySelectorAll('input[type="text"], input[type="number"]').forEach(input => {
        if (input.value) {
          params.append(input.name, input.value)
        }
      })

      // Checkboxes
      this.filtersTarget.querySelectorAll('input[type="checkbox"]:checked').forEach(checkbox => {
        params.append(checkbox.name, checkbox.value)
      })

      // Select dropdowns
      this.filtersTarget.querySelectorAll('select').forEach(select => {
        if (select.value) {
          params.append(select.name, select.value)
        }
      })

      // Radio buttons
      this.filtersTarget.querySelectorAll('input[type="radio"]:checked').forEach(radio => {
        params.append(radio.name, radio.value)
      })
    }

    return params
  }

  // Display search results
  displayResults(data) {
    if (this.hasResultsTarget) {
      this.resultsTarget.innerHTML = data.html || this.renderResults(data.properties)
    }

    if (this.hasCountTarget) {
      this.countTarget.textContent = `${data.total_count || 0} properties found`
    }

    // Update URL without page reload
    const params = this.buildSearchParams()
    const newUrl = `${window.location.pathname}?${params.toString()}`
    window.history.pushState({}, '', newUrl)
  }

  // Render results HTML
  renderResults(properties) {
    if (!properties || properties.length === 0) {
      return '<div class="text-center py-8 text-gray-500">No properties found</div>'
    }

    return properties.map(property => `
      <div class="property-card border rounded-lg p-4 mb-4 hover:shadow-lg transition-shadow">
        <div class="flex justify-between items-start">
          <div class="flex-1">
            <h3 class="text-lg font-semibold mb-2">
              <a href="/properties/${property.id}" class="text-blue-600 hover:text-blue-800">
                ${this.escapeHtml(property.title)}
              </a>
            </h3>
            <p class="text-gray-600 mb-2">${this.escapeHtml(property.location)}</p>
            <div class="flex items-center space-x-4 text-sm text-gray-500">
              <span>${property.bedrooms} bed</span>
              <span>${property.bathrooms} bath</span>
              <span>${property.square_feet} sqft</span>
            </div>
          </div>
          <div class="text-right">
            <div class="text-2xl font-bold text-green-600">$${property.price}</div>
            <div class="text-sm text-gray-500">/month</div>
          </div>
        </div>
        ${property.featured ? '<span class="inline-block mt-2 px-2 py-1 bg-yellow-100 text-yellow-800 text-xs rounded">Featured</span>' : ''}
      </div>
    `).join('')
  }

  // Display error message
  displayError(message) {
    if (this.hasResultsTarget) {
      this.resultsTarget.innerHTML = `
        <div class="alert alert-danger text-center py-4">
          <p class="text-red-600">An error occurred while searching. Please try again.</p>
          <p class="text-sm text-gray-500 mt-2">${this.escapeHtml(message)}</p>
        </div>
      `
    }
  }

  // Show loading state
  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove('hidden')
    }
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.add('opacity-50')
    }
  }

  // Hide loading state
  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add('hidden')
    }
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.remove('opacity-50')
    }
  }

  // Escape HTML to prevent XSS
  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}