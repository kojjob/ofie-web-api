// Mobile Menu Controller with Stimulus.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["menu", "openIcon", "closeIcon"];

  connect() {
    console.log("Mobile menu controller connected")
    console.log("Menu target found:", this.hasMenuTarget)
    console.log("Open icon target found:", this.hasOpenIconTarget)
    console.log("Close icon target found:", this.hasCloseIconTarget)

    this.isOpen = false;
    this.boundKeydownHandler = null;
    this.boundClickHandler = null;
    this.touchStarted = false;
    this.setupKeyboardNavigation();
    // Don't set up outside click listener immediately - only when menu opens
  }

  toggle(event) {
    event.preventDefault();
    event.stopPropagation();

    console.log("Mobile menu toggle triggered, currently open:", this.isOpen);

    // Close any open dropdowns first
    this.closeOtherDropdowns();

    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  open() {
    console.log("Opening mobile menu")

    // Ensure menu is visible first
    this.menuTarget.classList.remove('hidden');

    // Force initial position (off-screen to the right)
    this.menuTarget.style.transform = 'translateX(100%)';
    this.menuTarget.style.transition = 'none';

    // Set ARIA state
    this.element.setAttribute('aria-expanded', 'true');
    this.isOpen = true;

    // Set up outside click listener when opening
    this.setupOutsideClickListener();

    // Switch icons
    if (this.hasOpenIconTarget) this.openIconTarget.classList.add('hidden');
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.remove('hidden');

    // Prevent body scroll when menu is open
    document.body.style.overflow = 'hidden';
    document.body.style.position = 'fixed';
    document.body.style.width = '100%';

    // Trigger animation after a brief delay
    requestAnimationFrame(() => {
      this.menuTarget.style.transition = 'transform 0.3s ease-in-out';
      this.menuTarget.style.transform = 'translateX(0)';
    });

    // Don't auto-focus on mobile to avoid keyboard popup
    if (window.innerWidth > 768) {
      const firstMenuItem = this.menuTarget.querySelector('a');
      if (firstMenuItem) {
        setTimeout(() => firstMenuItem.focus(), 300);
      }
    }
  }

  close() {
    console.log("Closing mobile menu")

    // Animate menu out
    this.menuTarget.style.transition = 'transform 0.3s ease-in-out';
    this.menuTarget.style.transform = 'translateX(100%)';

    // Set ARIA state
    this.element.setAttribute('aria-expanded', 'false');
    this.isOpen = false;

    // Remove outside click listener
    this.removeOutsideClickListener();

    // Switch icons back
    if (this.hasOpenIconTarget) this.openIconTarget.classList.remove('hidden');
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.add('hidden');

    // Hide menu after animation completes
    setTimeout(() => {
      this.menuTarget.classList.add('hidden');
      this.menuTarget.style.transition = '';
      this.menuTarget.style.transform = '';
    }, 300);

    // Restore body scroll
    document.body.style.overflow = '';
    document.body.style.position = '';
    document.body.style.width = '';

    // Return focus to toggle button only on desktop
    if (window.innerWidth > 768) {
      this.element.focus();
    }
  }

  setupKeyboardNavigation() {
    this.boundKeydownHandler = (event) => {
      if (event.key === 'Escape' && this.isOpen) {
        this.close();
      }
    };
    document.addEventListener('keydown', this.boundKeydownHandler);
  }

  setupOutsideClickListener() {
    // Remove any existing listener first
    this.removeOutsideClickListener();

    this.boundClickHandler = (event) => {
      // Check if click is outside the entire mobile menu area (button + menu)
      const menuElement = this.menuTarget;
      const buttonElement = this.element;

      if (this.isOpen &&
          !buttonElement.contains(event.target) &&
          !menuElement.contains(event.target)) {
        this.close();
      }
    };

    // Use a timeout to avoid catching the opening click
    setTimeout(() => {
      if (this.isOpen) {
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

  closeOtherDropdowns() {
    // Close all user dropdowns
    const userDropdowns = document.querySelectorAll('[data-controller*="dropdown"]')
    userDropdowns.forEach(dropdown => {
      try {
        const controller = this.application.getControllerForElementAndIdentifier(dropdown, 'dropdown')
        if (controller && controller.isOpen) {
          controller.close()
        }
      } catch (error) {
        // Fallback: manually close dropdown
        const menu = dropdown.querySelector('[data-dropdown-target="menu"]')
        if (menu && !menu.classList.contains('hidden')) {
          menu.classList.add('hidden')
        }
      }
    })

    // Close notifications dropdown
    const notificationsDropdown = document.querySelector('[data-controller*="notifications"]')
    if (notificationsDropdown) {
      try {
        const controller = this.application.getControllerForElementAndIdentifier(notificationsDropdown, 'notifications')
        if (controller && controller.isOpen) {
          controller.close()
        }
      } catch (error) {
        // Fallback: manually close notifications
        const menu = notificationsDropdown.querySelector('[data-notifications-target="dropdown"]')
        if (menu && !menu.classList.contains('hidden')) {
          menu.classList.add('hidden')
        }
      }
    }
  }

  // Close menu when clicking on a link
  linkClicked(event) {
    console.log("Mobile menu link clicked")

    // Small delay to allow navigation to start
    setTimeout(() => {
      this.close()
    }, 100)
  }

  // Clean up event listeners
  disconnect() {
    // Restore body scroll
    document.body.style.overflow = '';
    document.body.style.position = '';
    document.body.style.width = '';

    // Remove event listeners
    if (this.boundKeydownHandler) {
      document.removeEventListener('keydown', this.boundKeydownHandler);
      this.boundKeydownHandler = null;
    }

    this.removeOutsideClickListener();
  }
}
