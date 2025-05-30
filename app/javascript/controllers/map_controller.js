import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    latitude: Number,
    longitude: Number,
    address: String
  }

  connect() {
    // Wait for Leaflet to be loaded
    if (typeof L === 'undefined') {
      // If Leaflet is not loaded yet, wait and try again
      setTimeout(() => this.initializeMap(), 100)
    } else {
      this.initializeMap()
    }
  }

  initializeMap() {
    if (typeof L === 'undefined') {
      console.error('Leaflet library is not loaded')
      return
    }

    // Create the map
    this.map = L.map(this.element, {
      center: [this.latitudeValue, this.longitudeValue],
      zoom: 15,
      zoomControl: true,
      scrollWheelZoom: false // Disable scroll wheel zoom by default
    })

    // Add tile layer (OpenStreetMap)
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
      maxZoom: 19
    }).addTo(this.map)

    // Create custom icon for the property marker
    const propertyIcon = L.divIcon({
      className: 'custom-property-marker',
      html: `
        <div class="bg-blue-600 text-white rounded-full w-8 h-8 flex items-center justify-center shadow-lg border-2 border-white">
          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd"></path>
          </svg>
        </div>
      `,
      iconSize: [32, 32],
      iconAnchor: [16, 32],
      popupAnchor: [0, -32]
    })

    // Add marker for the property
    const marker = L.marker([this.latitudeValue, this.longitudeValue], {
      icon: propertyIcon
    }).addTo(this.map)

    // Add popup with property address
    marker.bindPopup(`
      <div class="text-center p-2">
        <div class="font-semibold text-gray-900 mb-1">Property Location</div>
        <div class="text-sm text-gray-600">${this.addressValue}</div>
      </div>
    `)

    // Add click event to enable scroll wheel zoom when user interacts with map
    this.map.on('click', () => {
      this.map.scrollWheelZoom.enable()
    })

    // Disable scroll wheel zoom when mouse leaves the map
    this.map.on('mouseout', () => {
      this.map.scrollWheelZoom.disable()
    })

    // Add area circle to show approximate neighborhood
    L.circle([this.latitudeValue, this.longitudeValue], {
      color: '#3B82F6',
      fillColor: '#3B82F6',
      fillOpacity: 0.1,
      radius: 500 // 500 meters radius
    }).addTo(this.map)

    // Fit the map to show both the marker and the circle
    const group = new L.featureGroup([marker])
    this.map.fitBounds(group.getBounds().pad(0.1))
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }
}