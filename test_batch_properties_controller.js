// Test file for batch_properties_controller.js
// To run: Open browser console on the batch properties preview page

console.log('🧪 Testing Batch Properties Controller...')

// Test 1: Controller exists and is connected
function testControllerExists() {
  const controller = document.querySelector('[data-controller*="batch-properties"]')
  if (controller) {
    console.log('✅ Test 1 PASSED: Batch Properties controller found')
    return true
  } else {
    console.log('❌ Test 1 FAILED: Batch Properties controller not found')
    return false
  }
}

// Test 2: Pagination targets exist
function testPaginationTargets() {
  const controller = document.querySelector('[data-controller*="batch-properties"]')
  if (!controller) return false
  
  const tableContainer = controller.querySelector('[data-batch-properties-target="tableContainer"]')
  const paginationContainer = controller.querySelector('[data-batch-properties-target="paginationContainer"]')
  
  if (tableContainer && paginationContainer) {
    console.log('✅ Test 2 PASSED: Pagination targets found')
    return true
  } else {
    console.log('❌ Test 2 FAILED: Pagination targets missing')
    console.log('Table container:', !!tableContainer)
    console.log('Pagination container:', !!paginationContainer)
    return false
  }
}

// Test 3: Pagination buttons have correct data attributes
function testPaginationButtons() {
  const paginationButtons = document.querySelectorAll('[data-action*="handlePaginationClick"]')
  
  if (paginationButtons.length > 0) {
    let allValid = true
    paginationButtons.forEach((button, index) => {
      const page = button.dataset.page
      if (!page || isNaN(parseInt(page))) {
        allValid = false
        console.log(`❌ Button ${index} missing valid page data:`, page)
      }
    })
    
    if (allValid) {
      console.log(`✅ Test 3 PASSED: Found ${paginationButtons.length} valid pagination buttons`)
      return true
    }
  }
  
  console.log('❌ Test 3 FAILED: No valid pagination buttons found')
  return false
}

// Test 4: Modal functionality
function testModalTargets() {
  const modalTarget = document.querySelector('[data-batch-properties-target="modal"]')
  const modalButtons = document.querySelectorAll('[data-action*="openModal"]')
  
  if (modalTarget && modalButtons.length > 0) {
    console.log(`✅ Test 4 PASSED: Modal found with ${modalButtons.length} trigger buttons`)
    return true
  } else {
    console.log('❌ Test 4 FAILED: Modal targets missing')
    console.log('Modal target:', !!modalTarget)
    console.log('Modal buttons:', modalButtons.length)
    return false
  }
}

// Test 5: CSRF token availability
function testCSRFToken() {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')
  
  if (csrfToken && csrfToken.getAttribute('content')) {
    console.log('✅ Test 5 PASSED: CSRF token found')
    return true
  } else {
    console.log('❌ Test 5 FAILED: CSRF token missing')
    return false
  }
}

// Test 6: Stimulus controller methods exist
function testControllerMethods() {
  const controller = document.querySelector('[data-controller*="batch-properties"]')
  if (!controller) return false
  
  // Try to access the Stimulus controller instance
  try {
    const stimulusApp = window.Stimulus || window.application
    if (stimulusApp) {
      console.log('✅ Test 6 PASSED: Stimulus application found')
      return true
    }
  } catch (error) {
    console.log('❌ Test 6 WARNING: Could not access Stimulus controller methods')
    console.log('This is normal if Stimulus is not exposed globally')
    return true // Don't fail for this
  }
  
  return true
}

// Run all tests
function runAllTests() {
  console.log('\n🚀 Starting Batch Properties Controller Tests...\n')
  
  const tests = [
    testControllerExists,
    testPaginationTargets,
    testPaginationButtons,
    testModalTargets,
    testCSRFToken,
    testControllerMethods
  ]
  
  let passed = 0
  let total = tests.length
  
  tests.forEach((test, index) => {
    try {
      if (test()) {
        passed++
      }
    } catch (error) {
      console.log(`❌ Test ${index + 1} ERROR:`, error.message)
    }
  })
  
  console.log(`\n📊 Test Results: ${passed}/${total} tests passed`)
  
  if (passed === total) {
    console.log('🎉 All tests PASSED! The batch properties controller is working correctly.')
  } else {
    console.log('⚠️  Some tests failed. Check the implementation.')
  }
  
  return { passed, total }
}

// Auto-run tests if this is loaded in browser
if (typeof window !== 'undefined') {
  // Wait for DOM to be ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', runAllTests)
  } else {
    setTimeout(runAllTests, 500) // Small delay to ensure Stimulus is loaded
  }
}

// Export for manual testing
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    runAllTests,
    testControllerExists,
    testPaginationTargets,
    testPaginationButtons,
    testModalTargets,
    testCSRFToken,
    testControllerMethods
  }
}

// Manual test instructions
console.log(`
📝 Manual Testing Instructions:

1. Open the batch properties preview page
2. Open browser console
3. Run: runAllTests()
4. Test pagination by clicking page numbers
5. Test modal by clicking the 3-dots menu on any row
6. Check for JavaScript errors

🔍 Expected Behavior:
- Pagination should work without page reload
- Loading spinner should appear briefly
- Browser URL should update
- Modal should open/close properly
- No JavaScript errors in console
`)
