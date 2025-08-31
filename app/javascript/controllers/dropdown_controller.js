// Enhanced Dropdown Controller with Stimulus.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu", "button"];
  static classes = ["open"];

  connect() {
    this.isOpen = false;
    this.boundClickHandler = null;
    this.boundKeydownHandler = null;
    this.setupKeyboardNavigation();
    this.setupAccessibility();
    console.log('Dropdown controller connected:', this.element);
  }

  disconnect() {
    this.removeOutsideClickListener();
    this.removeKeyboardListener();
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

    // Add opening animation class if available
    if (this.hasOpenClass) {
      this.menuTarget.classList.add(this.openClass);
    }

    this.menuTarget.classList.remove('hidden');
    this.menuTarget.style.opacity = '0';
    this.menuTarget.style.transform = 'translateY(-10px)';

    // Prevent body scroll on mobile
    if (window.innerWidth <= 768) {
      document.body.classList.add('dropdown-open');
    }

    // Trigger animation
    requestAnimationFrame(() => {
      this.menuTarget.style.opacity = '1';
      this.menuTarget.style.transform = 'translateY(0)';
    });

    const button = this.getButton();
    if (button) {
      button.setAttribute('aria-expanded', 'true');
    }
    this.isOpen = true;

    // Set up outside click listener when opening
    this.setupOutsideClickListener();
    this.setupKeyboardListener();

    // Focus first menu item for better accessibility (but not on mobile to avoid keyboard)
    if (window.innerWidth > 768) {
      const firstMenuItem = this.menuTarget.querySelector('a, button');
      if (firstMenuItem) {
        setTimeout(() => firstMenuItem.focus(), 100);
      }
    }
  }

  close() {
    console.log('Closing dropdown');

    // Add closing animation
    this.menuTarget.style.opacity = '0';
    this.menuTarget.style.transform = 'translateY(-10px)';

    // Restore body scroll on mobile
    if (window.innerWidth <= 768) {
      document.body.classList.remove('dropdown-open');
    }

    setTimeout(() => {
      this.menuTarget.classList.add('hidden');
      if (this.hasOpenClass) {
        this.menuTarget.classList.remove(this.openClass);
      }
    }, 150);

    const button = this.getButton();
    if (button) {
      button.setAttribute('aria-expanded', 'false');
      // Return focus to button only if focus is currently in the dropdown and not on mobile
      if (this.menuTarget.contains(document.activeElement) && window.innerWidth > 768) {
        button.focus();
      }
    }
    this.isOpen = false;

    // Remove listeners when closing
    this.removeOutsideClickListener();
    this.removeKeyboardListener();
  }

  setupKeyboardNavigation() {
    this.element.addEventListener('keydown', (event) => {
      if (event.key === 'Escape' && this.isOpen) {
        event.preventDefault();
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

      if (event.key === 'Enter' || event.key === ' ') {
        const button = this.getButton();
        if (event.target === button) {
          event.preventDefault();
          this.toggle(event);
        }
      }
    });
  }

  setupKeyboardListener() {
    this.boundKeydownHandler = (event) => {
      if (event.key === 'Escape' && this.isOpen) {
        event.preventDefault();
        this.close();
      }
    };
    document.addEventListener('keydown', this.boundKeydownHandler);
  }

  removeKeyboardListener() {
    if (this.boundKeydownHandler) {
      document.removeEventListener('keydown', this.boundKeydownHandler);
      this.boundKeydownHandler = null;
    }
  }

  setupAccessibility() {
    const button = this.getButton();
    if (button) {
      button.setAttribute('aria-haspopup', 'true');
      button.setAttribute('aria-expanded', 'false');

      // Add unique IDs for ARIA relationship
      const menuId = this.menuTarget.id || `dropdown-menu-${Math.random().toString(36).substr(2, 9)}`;
      this.menuTarget.id = menuId;
      button.setAttribute('aria-controls', menuId);
    }
  }

  setupOutsideClickListener() {
    // Remove any existing listener first
    this.removeOutsideClickListener();

    // Create the click handler
    this.boundClickHandler = (event) => {
      // Check if click is outside the dropdown and not on the trigger button
      if (!this.element.contains(event.target)) {
        this.close();
      }
    };

    // Use a longer timeout to ensure the opening click is not caught
    setTimeout(() => {
      if (this.isOpen) {  // Double-check dropdown is still open
        document.addEventListener('click', this.boundClickHandler, { passive: true });
      }
    }, 50);
  }

  removeOutsideClickListener() {
    if (this.boundClickHandler) {
      document.removeEventListener('click', this.boundClickHandler);
      this.boundClickHandler = null;
    }
  }

  getButton() {
    return this.hasButtonTarget ? this.buttonTarget : this.element.querySelector('button');
  }

  closeOtherDropdowns() {
    // Find all other dropdown controllers and close them
    const otherDropdowns = document.querySelectorAll('[data-controller*="dropdown"]');
    otherDropdowns.forEach(dropdown => {
      if (dropdown !== this.element) {
        try {
          const controller = this.application.getControllerForElementAndIdentifier(dropdown, 'dropdown');
          if (controller && controller.isOpen) {
            controller.close();
          }
        } catch (error) {
          // Fallback: manually close dropdown
          const menu = dropdown.querySelector('[data-dropdown-target="menu"]');
          if (menu && !menu.classList.contains('hidden')) {
            menu.classList.add('hidden');
            const button = dropdown.querySelector('button');
            if (button) {
              button.setAttribute('aria-expanded', 'false');
            }
          }
        }
      }
    });

    // Also close notifications dropdown if it's open
    const notificationsDropdown = document.querySelector('[data-controller*="notifications"]');
    if (notificationsDropdown && notificationsDropdown !== this.element) {
      try {
        const controller = this.application.getControllerForElementAndIdentifier(notificationsDropdown, 'notifications');
        if (controller && controller.isOpen) {
          controller.close();
        }
      } catch (error) {
        // Fallback: manually close notifications
        const menu = notificationsDropdown.querySelector('[data-notifications-target="dropdown"]');
        if (menu && !menu.classList.contains('hidden')) {
          menu.classList.add('hidden');
        }
      }
    }
  }

  navigateMenu(direction) {
    const menuItems = Array.from(this.menuTarget.querySelectorAll('a, button'));
    const currentIndex = menuItems.indexOf(document.activeElement);
    let nextIndex = currentIndex + direction;

    if (nextIndex < 0) nextIndex = menuItems.length - 1;
    if (nextIndex >= menuItems.length) nextIndex = 0;

    if (menuItems[nextIndex]) {
      menuItems[nextIndex].focus();
    }
  }
}
