// Mobile Menu Controller with Stimulus.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu", "openIcon", "closeIcon"];

  connect() {
    this.isOpen = false;
    this.setupKeyboardNavigation();
  }

  toggle(event) {
    event.preventDefault();
    
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    this.menuTarget.classList.remove('hidden');
    this.element.setAttribute('aria-expanded', 'true');
    this.isOpen = true;
    
    // Switch icons
    if (this.hasOpenIconTarget) this.openIconTarget.classList.add('hidden');
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.remove('hidden');
    
    // Prevent body scroll when menu is open
    document.body.style.overflow = 'hidden';
    
    // Focus first menu item
    const firstMenuItem = this.menuTarget.querySelector('a');
    if (firstMenuItem) {
      setTimeout(() => firstMenuItem.focus(), 100);
    }
  }

  close() {
    this.menuTarget.classList.add('hidden');
    this.element.setAttribute('aria-expanded', 'false');
    this.isOpen = false;
    
    // Switch icons back
    if (this.hasOpenIconTarget) this.openIconTarget.classList.remove('hidden');
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.add('hidden');
    
    // Restore body scroll
    document.body.style.overflow = '';
    
    // Return focus to toggle button
    this.element.focus();
  }

  setupKeyboardNavigation() {
    document.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && this.isOpen) {
        this.close();
      }
    });
  }

  // Close menu when clicking outside
  disconnect() {
    document.body.style.overflow = '';
  }
}
