// Dropdown Controller with Stimulus.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  connect() {
    this.isOpen = false;
    this.boundClickHandler = null;
    this.setupKeyboardNavigation();
    // Don't set up outside click listener here - only when opening
    console.log('Dropdown controller connected:', this.element);
  }

  toggle(event) {
    event.preventDefault();
    event.stopPropagation();
    
    console.log('Toggle clicked, currently open:', this.isOpen);
    
    // Close any other open dropdowns first
    this.closeOtherDropdowns();
    
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    console.log('Opening dropdown');
    this.menuTarget.classList.remove('hidden');
    const button = this.element.querySelector('button');
    if (button) {
      button.setAttribute('aria-expanded', 'true');
    }
    this.isOpen = true;
    
    // Set up outside click listener when opening
    this.setupOutsideClickListener();
    
    // Focus first menu item for better accessibility
    const firstMenuItem = this.menuTarget.querySelector('a, button');
    if (firstMenuItem) {
      setTimeout(() => firstMenuItem.focus(), 50);
    }
  }

  close() {
    console.log('Closing dropdown');
    this.menuTarget.classList.add('hidden');
    const button = this.element.querySelector('button');
    if (button) {
      button.setAttribute('aria-expanded', 'false');
      // Return focus to button
      button.focus();
    }
    this.isOpen = false;
    
    // Remove outside click listener when closing
    this.removeOutsideClickListener();
  }

  setupKeyboardNavigation() {
    this.element.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && this.isOpen) {
        this.close();
      }

      if (event.key === 'ArrowDown' && !this.isOpen) {
        event.preventDefault();
        this.open();
      }

      if (this.isOpen && (event.key === 'ArrowDown' || event.key === 'ArrowUp')) {
        event.preventDefault();
        this.navigateMenu(event.key === 'ArrowDown' ? 1 : -1);
      }
    });
  }

  setupOutsideClickListener() {
    // Remove any existing listener first
    this.removeOutsideClickListener();
    
    // Create the click handler
    this.boundClickHandler = (event) => {
      // Check if click is outside the dropdown
      if (!this.element.contains(event.target)) {
        this.close();
      }
    };
    
    // Use a longer timeout to ensure the opening click is not caught
    setTimeout(() => {
      if (this.isOpen) {  // Double-check dropdown is still open
        document.addEventListener('click', this.boundClickHandler);
      }
    }, 10);
  }
  
  removeOutsideClickListener() {
    if (this.boundClickHandler) {
      document.removeEventListener('click', this.boundClickHandler);
      this.boundClickHandler = null;
    }
  }

  closeOtherDropdowns() {
    // Find all other dropdown controllers and close them
    const otherDropdowns = document.querySelectorAll('[data-controller*="dropdown"]');
    otherDropdowns.forEach(dropdown => {
      if (dropdown !== this.element) {
        const controller = this.application.getControllerForElementAndIdentifier(dropdown, 'dropdown');
        if (controller && controller.isOpen) {
          controller.close();
        }
      }
    });
  }

  disconnect() {
    this.removeOutsideClickListener();
  }

  navigateMenu(direction) {
    const menuItems = Array.from(this.menuTarget.querySelectorAll('a'));
    const currentIndex = menuItems.indexOf(document.activeElement);
    let nextIndex = currentIndex + direction;
    
    if (nextIndex < 0) nextIndex = menuItems.length - 1;
    if (nextIndex >= menuItems.length) nextIndex = 0;
    
    menuItems[nextIndex].focus();
  }
}
