import { Controller } from "@hotwired/stimulus"

// Infinite scroll controller for pagination
export default class extends Controller {
  static targets = ["items", "loader", "noMore"]
  static values = {
    url: String,
    page: { type: Number, default: 1 },
    loading: { type: Boolean, default: false },
    hasMore: { type: Boolean, default: true }
  }

  connect() {
    this.observeScroll()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  observeScroll() {
    // Use Intersection Observer for better performance
    const options = {
      root: null,
      rootMargin: '100px',
      threshold: 0.1
    }

    this.observer = new IntersectionObserver((entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting && this.hasMoreValue && !this.loadingValue) {
          this.loadMore()
        }
      })
    }, options)

    // Observe the loader element
    if (this.hasLoaderTarget) {
      this.observer.observe(this.loaderTarget)
    }
  }

  async loadMore() {
    if (this.loadingValue || !this.hasMoreValue) return

    this.loadingValue = true
    this.showLoader()

    try {
      const nextPage = this.pageValue + 1
      const url = this.buildUrl(nextPage)
      
      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()
      
      if (data.html) {
        this.appendItems(data.html)
      } else if (data.items) {
        this.appendItems(this.renderItems(data.items))
      }

      // Update pagination state
      this.pageValue = nextPage
      this.hasMoreValue = data.has_more !== false && (data.items ? data.items.length > 0 : true)

      // Show "no more" message if no more items
      if (!this.hasMoreValue) {
        this.showNoMore()
      }

      // Dispatch event
      this.dispatch('loaded', { detail: { page: nextPage, items: data.items } })
    } catch (error) {
      console.error('Error loading more items:', error)
      this.showError()
    } finally {
      this.loadingValue = false
      this.hideLoader()
    }
  }

  buildUrl(page) {
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set('page', page)
    
    // Preserve existing query parameters
    const currentParams = new URLSearchParams(window.location.search)
    currentParams.forEach((value, key) => {
      if (key !== 'page') {
        url.searchParams.set(key, value)
      }
    })
    
    return url.toString()
  }

  appendItems(html) {
    if (this.hasItemsTarget) {
      // Create temporary container
      const temp = document.createElement('div')
      temp.innerHTML = html
      
      // Append each child element
      while (temp.firstChild) {
        this.itemsTarget.appendChild(temp.firstChild)
      }
    }
  }

  renderItems(items) {
    // Override this method in specific implementations
    // This is a fallback for generic item rendering
    return items.map(item => `
      <div class="item p-4 border rounded mb-4">
        ${JSON.stringify(item)}
      </div>
    `).join('')
  }

  showLoader() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.remove('hidden')
    }
  }

  hideLoader() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.add('hidden')
    }
  }

  showNoMore() {
    if (this.hasNoMoreTarget) {
      this.noMoreTarget.classList.remove('hidden')
    }
    if (this.hasLoaderTarget) {
      this.loaderTarget.classList.add('hidden')
    }
  }

  showError() {
    const errorHtml = `
      <div class="text-center py-4 text-red-600">
        <p>Error loading more items. Please try again.</p>
        <button data-action="click->infinite-scroll#retry" class="mt-2 px-4 py-2 bg-blue-500 text-white rounded">
          Retry
        </button>
      </div>
    `
    
    if (this.hasItemsTarget) {
      const errorDiv = document.createElement('div')
      errorDiv.innerHTML = errorHtml
      this.itemsTarget.appendChild(errorDiv)
    }
  }

  retry() {
    // Remove error message
    const errorMessage = this.itemsTarget.querySelector('.text-red-600')?.parentElement
    if (errorMessage) {
      errorMessage.remove()
    }
    
    // Try loading again
    this.loadMore()
  }

  // Manual trigger to load more
  loadMoreManually(event) {
    if (event) event.preventDefault()
    this.loadMore()
  }

  // Reset pagination
  reset() {
    this.pageValue = 1
    this.hasMoreValue = true
    this.loadingValue = false
    
    if (this.hasItemsTarget) {
      this.itemsTarget.innerHTML = ''
    }
    
    if (this.hasNoMoreTarget) {
      this.noMoreTarget.classList.add('hidden')
    }
    
    this.loadMore()
  }
};
