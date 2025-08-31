// Dropdown Controller with Stimulus.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu"];

  connect() {
    this.isOpen = false;
    this.setupKeyboardNavigation();
    this.setupOutsideClickListener();
  }

  toggle(event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    this.menuTarget.classList.remove('hidden');
    this.element.querySelector('button').setAttribute('aria-expanded', 'true');
    this.isOpen = true;
    
    // Add animation
    setTimeout(() => {
      this.menuTarget.classList.add('opacity-100', 'translate-y-0');
      this.menuTarget.classList.remove('opacity-0', 'translate-y-2');
    }, 10);
    
    // Focus first menu item after animation
    setTimeout(() => {
      const firstMenuItem = this.menuTarget.querySelector('a');
      if (firstMenuItem) {
        firstMenuItem.focus();
      }
    }, 100);
  }

  close() {
    // Add closing animation
    this.menuTarget.classList.add('opacity-0', 'translate-y-2');
    this.menuTarget.classList.remove('opacity-100', 'translate-y-0');
    
    setTimeout(() => {
      this.menuTarget.classList.add('hidden');
      this.element.querySelector('button').setAttribute('aria-expanded', 'false');
      this.isOpen = false;
      
      // Return focus to button
      this.element.querySelector('button').focus();
    }, 200);
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
    this.boundClickHandler = (event) => {
      // Only close if the dropdown is actually open and the click is outside
      if (this.isOpen && !this.element.contains(event.target)) {
        this.close();
      }
    };
    
    // Use capture phase to ensure we get the event before other handlers
    document.addEventListener('click', this.boundClickHandler, true);
  }

  disconnect() {
    if (this.boundClickHandler) {
      document.removeEventListener('click', this.boundClickHandler, true);
    }
  }

  navigateMenu(direction) {
    const menuItems = Array.from(this.menuTarget.querySelectorAll('a'));
    const currentIndex = menuItems.indexOf(document.activeElement);
    let nextIndex = currentIndex + direction;
    
    if (nextIndex < 0) nextIndex = menuItems.length - 1;
    if (nextIndex >= menuItems.length) nextIndex = 0;
    
    menuItems[nextIndex].focus();
  }
};
