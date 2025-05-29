import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["form", "results", "clearButton"]
  static values = { url: String }

  connect() {
    console.log("Search controller connected")
    this.updateClearButtonVisibility()
  }

  // Handle form submission
  submit(event) {
    event.preventDefault()
    this.performSearch()
  }

  // Handle input changes for real-time search
  input() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      this.performSearch()
    }, 500) // Debounce for 500ms
  }

  // Clear all filters
  clear() {
    const form = this.formTarget
    const inputs = form.querySelectorAll('input, select')
    
    inputs.forEach(input => {
      if (input.type === 'text' || input.type === 'number') {
        input.value = ''
      } else if (input.tagName === 'SELECT') {
        input.selectedIndex = 0
      }
    })
    
    this.updateClearButtonVisibility()
    this.performSearch()
  }

  // Perform the search
  async performSearch() {
    const formData = new FormData(this.formTarget)
    const params = new URLSearchParams(formData)
    
    try {
      const response = await fetch(`${this.urlValue}?${params}`, {
        headers: {
          'Accept': 'text/html',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
      
      if (response.ok) {
        const html = await response.text()
        this.resultsTarget.innerHTML = html
        this.updateClearButtonVisibility()
      }
    } catch (error) {
      console.error('Search failed:', error)
    }
  }

  // Update clear button visibility based on form state
  updateClearButtonVisibility() {
    const form = this.formTarget
    const inputs = form.querySelectorAll('input[type="text"], input[type="number"], select')
    let hasValues = false
    
    inputs.forEach(input => {
      if (input.value && input.value !== '' && input.selectedIndex !== 0) {
        hasValues = true
      }
    })
    
    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.style.display = hasValues ? 'inline-flex' : 'none'
    }
  }
}