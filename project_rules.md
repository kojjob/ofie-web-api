## Enhanced `project_rules.md` for a Ruby on Rails Rental Application

This document outlines the coding, architectural, and collaboration rules for developing a rental application using Ruby on Rails with built-in features, Hotwire, TailwindCSS, and PostgreSQL. It emphasizes Test Driven Development (TDD), Domain-Driven Design (DDD), and proper separation of concerns.

---

### **1. Project Stack and Philosophy**

- **Framework:** Ruby on Rails 8
- **Frontend:** Hotwire (Turbo + Stimulus) - Rails built-in
- **Styling:** TailwindCSS (via tailwindcss-rails gem)
- **Database:** PostgreSQL
- **Development Methodology:** Test Driven Development (TDD) + Domain-Driven Design (DDD)
- **Architecture:** Clean separation of concerns with well-defined boundaries
- **Dependencies:** Rails built-in features only, except for authentication (Devise)

---

### **2. Domain-Driven Design Principles**

- **Domain Models:** Models should accurately reflect the business domain (e.g., `Rental`, `Property`, `Tenant`, `Lease`)
- **Bounded Contexts:** Organize code around business capabilities, not technical layers
- **Value Objects:** Use Rails built-in `composed_of` or custom classes for domain concepts (e.g., `Money`, `Address`)
- **Domain Services:** Extract complex business logic into service objects in `app/services/`
- **Repositories:** Use Rails models as repositories, but keep query logic in scopes and class methods
- **Entities vs Value Objects:** Distinguish between entities (have identity) and value objects (immutable, no identity)

```ruby
# Example Domain Model
class Rental < ApplicationRecord
  # Domain relationships
  belongs_to :property
  belongs_to :tenant
  has_many :lease_agreements, dependent: :destroy
  
  # Domain validations
  validates :start_date, :end_date, :monthly_rent, presence: true
  validates :monthly_rent, numericality: { greater_than: 0 }
  
  # Domain scopes
  scope :active, -> { where('start_date <= ? AND end_date >= ?', Date.current, Date.current) }
  scope :expired, -> { where('end_date < ?', Date.current) }
  
  # Domain methods
  def active?
    Date.current.between?(start_date, end_date)
  end
  
  def total_rent_amount
    (end_date - start_date).to_i / 30 * monthly_rent
  end
end
```

---

### **3. Test Driven Development (TDD) Rules**

- **Red-Green-Refactor:** Write failing tests first, make them pass, then refactor
- **Test Coverage:** Aim for 100% test coverage with meaningful tests
- **Test Types:**
  - **Unit Tests:** Model tests (`test/models/`)
  - **Integration Tests:** Controller tests (`test/controllers/`)
  - **System Tests:** End-to-end tests (`test/system/`)
  - **Component Tests:** Helper and view tests

```ruby
# Example Model Test (TDD approach)
class RentalTest < ActiveSupport::TestCase
  test "should be active when current date is between start and end dates" do
    rental = rentals(:active_rental)
    assert rental.active?
  end
  
  test "should calculate total rent amount correctly" do
    rental = rentals(:monthly_rental)
    expected_amount = rental.monthly_rent * 12 # assuming 1 year lease
    assert_equal expected_amount, rental.total_rent_amount
  end
end
```

---

### **4. Separation of Concerns Architecture**

#### **4.1 Controllers (Thin Controllers)**
```ruby
class RentalsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_rental, only: [:show, :edit, :update, :destroy]
  
  def index
    @rentals = RentalSearchService.new(rental_search_params).call
                                  .page(params[:page])
  end
  
  def create
    @rental = RentalCreationService.new(rental_params, current_user).call
    
    if @rental.persisted?
      redirect_to @rental, notice: 'Rental was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  private
  
  def rental_params
    params.require(:rental).permit(:property_id, :tenant_id, :start_date, :end_date, :monthly_rent)
  end
end
```

#### **4.2 Service Objects (Business Logic)**
```ruby
# app/services/rental_creation_service.rb
class RentalCreationService
  def initialize(rental_params, current_user)
    @rental_params = rental_params
    @current_user = current_user
  end
  
  def call
    ActiveRecord::Base.transaction do
      @rental = Rental.new(@rental_params)
      @rental.created_by = @current_user
      
      if @rental.save
        NotificationService.new(@rental).notify_tenant_of_new_rental
        @rental
      else
        raise ActiveRecord::Rollback
      end
    end
    
    @rental
  end
  
  private
  
  attr_reader :rental_params, :current_user
end
```

#### **4.3 View Components (Reusable UI)**
```erb
<!-- app/views/shared/_rental_card.html.erb -->
<div class="bg-white rounded-lg shadow-md p-6 mb-4">
  <div class="flex justify-between items-start">
    <div>
      <h3 class="text-lg font-semibold text-gray-900">
        <%= rental.property.address %>
      </h3>
      <p class="text-gray-600 mt-1">
        <%= rental.tenant.full_name %>
      </p>
    </div>
    <div class="text-right">
      <p class="text-2xl font-bold text-green-600">
        $<%= number_with_delimiter(rental.monthly_rent) %>
      </p>
      <p class="text-sm text-gray-500">per month</p>
    </div>
  </div>
  
  <div class="mt-4 flex justify-between items-center">
    <span class="<%= rental_status_class(rental) %>">
      <%= rental.status.humanize %>
    </span>
    <div class="space-x-2">
      <%= link_to "View", rental, class: "btn btn-sm btn-outline" %>
      <%= link_to "Edit", edit_rental_path(rental), class: "btn btn-sm btn-primary" %>
    </div>
  </div>
</div>
```

---

### **5. Rails Built-in Features Usage**

#### **5.1 Pagination (Rails Built-in)**
```ruby
# Use Rails built-in pagination instead of external gems
class RentalsController < ApplicationController
  def index
    @rentals = Rental.includes(:property, :tenant)
                     .page(params[:page])
                     .per(20) # Using built-in pagination
  end
end

# In models, use offset and limit
class Rental < ApplicationRecord
  scope :paginated, ->(page, per_page = 20) {
    offset((page.to_i - 1) * per_page).limit(per_page)
  }
end
```

#### **5.2 Background Jobs (Active Job)**
```ruby
# Use Rails built-in Active Job instead of Sidekiq
class RentalNotificationJob < ApplicationJob
  queue_as :default
  
  def perform(rental_id)
    rental = Rental.find(rental_id)
    RentalMailer.lease_expiry_reminder(rental).deliver_now
  end
end

# Enqueue jobs
RentalNotificationJob.perform_later(rental.id)
```

#### **5.3 Authorization (Rails Built-in Patterns)**
```ruby
# Use Rails built-in authorization patterns instead of Pundit
class ApplicationController < ActionController::Base
  private
  
  def authorize_rental_access!(rental)
    unless can_access_rental?(rental)
      redirect_to root_path, alert: 'Access denied.'
    end
  end
  
  def can_access_rental?(rental)
    current_user.admin? || rental.property.owner == current_user
  end
end

# Or use concerns for reusable authorization
module Authorizable
  extend ActiveSupport::Concern
  
  def authorize!(action, resource)
    unless authorized?(action, resource)
      raise ActionController::Forbidden, "Not authorized to #{action} #{resource.class.name}"
    end
  end
  
  private
  
  def authorized?(action, resource)
    case resource
    when Rental
      authorize_rental(action, resource)
    else
      false
    end
  end
end
```

#### **5.4 Caching (Rails Built-in)**
```ruby
# Use Rails built-in caching
class RentalsController < ApplicationController
  def show
    @rental = Rails.cache.fetch("rental_#{params[:id]}", expires_in: 1.hour) do
      Rental.includes(:property, :tenant, :lease_agreements).find(params[:id])
    end
  end
end

# Fragment caching in views
<% cache(@rental) do %>
  <%= render 'rental_details', rental: @rental %>
<% end %>
```

---

### **6. Hotwire & TailwindCSS Best Practices**

#### **6.1 Separation of Concerns with Hotwire**
```erb
<!-- Turbo Frame for isolated updates -->
<%= turbo_frame_tag "rental_#{rental.id}" do %>
  <%= render 'rental_card', rental: rental %>
<% end %>

<!-- Turbo Stream for real-time updates -->
<%= turbo_stream.replace "rental_#{@rental.id}" do %>
  <%= render 'rental_card', rental: @rental %>
<% end %>
```

#### **6.2 Stimulus Controllers (Separate JS Concerns)**
```javascript
// app/javascript/controllers/rental_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["monthlyRent", "totalRent", "leaseDuration"]
  
  calculateTotal() {
    const monthlyRent = parseFloat(this.monthlyRentTarget.value) || 0
    const duration = parseInt(this.leaseDurationTarget.value) || 0
    const total = monthlyRent * duration
    
    this.totalRentTarget.textContent = total.toLocaleString('en-US', {
      style: 'currency',
      currency: 'USD'
    })
  }
}
```

#### **6.3 TailwindCSS Component Classes**
```css
/* app/assets/stylesheets/components.css - Only when Tailwind cannot achieve the design */
@layer components {
  .btn {
    @apply px-4 py-2 rounded-md font-medium transition-colors duration-200;
  }
  
  .btn-primary {
    @apply bg-blue-600 text-white hover:bg-blue-700 focus:ring-2 focus:ring-blue-500;
  }
  
  .rental-card {
    @apply bg-white rounded-lg shadow-md hover:shadow-lg transition-shadow duration-200;
  }
}
```

---

### **7. Database and Data Integrity (Rails Built-in)**

#### **7.1 Migrations with Constraints**
```ruby
class CreateRentals < ActiveRecord::Migration[7.0]
  def change
    create_table :rentals do |t|
      t.references :property, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.decimal :monthly_rent, precision: 10, scale: 2, null: false
      t.integer :status, default: 0, null: false
      
      t.timestamps
    end
    
    add_index :rentals, [:property_id, :start_date]
    add_index :rentals, :status
    add_check_constraint :rentals, "end_date > start_date", name: "valid_date_range"
    add_check_constraint :rentals, "monthly_rent > 0", name: "positive_rent"
  end
end
```

#### **7.2 Model Validations and Callbacks**
```ruby
class Rental < ApplicationRecord
  enum status: { draft: 0, active: 1, expired: 2, terminated: 3 }
  
  validates :start_date, :end_date, :monthly_rent, presence: true
  validates :monthly_rent, numericality: { greater_than: 0 }
  validate :end_date_after_start_date
  validate :no_overlapping_rentals, on: :create
  
  before_save :calculate_total_amount
  after_create :schedule_expiry_notification
  
  private
  
  def end_date_after_start_date
    return unless start_date && end_date
    
    errors.add(:end_date, "must be after start date") if end_date <= start_date
  end
  
  def no_overlapping_rentals
    overlapping = Rental.where(property: property)
                        .where.not(id: id)
                        .where("start_date <= ? AND end_date >= ?", end_date, start_date)
    
    errors.add(:base, "Property already rented during this period") if overlapping.exists?
  end
end
```

---

### **8. Testing Strategy (TDD Implementation)**

#### **8.1 Model Tests (Domain Logic)**
```ruby
# test/models/rental_test.rb
require 'test_helper'

class RentalTest < ActiveSupport::TestCase
  def setup
    @property = properties(:downtown_apartment)
    @tenant = tenants(:john_doe)
  end
  
  test "should create valid rental" do
    rental = Rental.new(
      property: @property,
      tenant: @tenant,
      start_date: Date.current,
      end_date: 1.year.from_now,
      monthly_rent: 1500.00
    )
    
    assert rental.valid?
    assert rental.save
  end
  
  test "should not allow overlapping rentals" do
    # Create first rental
    Rental.create!(
      property: @property,
      tenant: @tenant,
      start_date: Date.current,
      end_date: 6.months.from_now,
      monthly_rent: 1500.00
    )
    
    # Try to create overlapping rental
    overlapping_rental = Rental.new(
      property: @property,
      tenant: tenants(:jane_smith),
      start_date: 3.months.from_now,
      end_date: 9.months.from_now,
      monthly_rent: 1600.00
    )
    
    assert_not overlapping_rental.valid?
    assert_includes overlapping_rental.errors[:base], "Property already rented during this period"
  end
end
```

#### **8.2 Controller Tests (Integration)**
```ruby
# test/controllers/rentals_controller_test.rb
require 'test_helper'

class RentalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:landlord)
    @rental = rentals(:active_rental)
    sign_in @user
  end
  
  test "should get index" do
    get rentals_url
    assert_response :success
    assert_select 'h1', 'Rentals'
  end
  
  test "should create rental with valid params" do
    assert_difference('Rental.count') do
      post rentals_url, params: {
        rental: {
          property_id: properties(:downtown_apartment).id,
          tenant_id: tenants(:john_doe).id,
          start_date: Date.current,
          end_date: 1.year.from_now,
          monthly_rent: 1500.00
        }
      }
    end
    
    assert_redirected_to rental_url(Rental.last)
    follow_redirect!
    assert_select '.notice', 'Rental was successfully created.'
  end
end
```

#### **8.3 System Tests (End-to-End)**
```ruby
# test/system/rentals_test.rb
require 'application_system_test_case'

class RentalsTest < ApplicationSystemTestCase
  setup do
    @user = users(:landlord)
    login_as @user
  end
  
  test "creating a rental" do
    visit rentals_path
    click_on "New Rental"
    
    select properties(:downtown_apartment).address, from: "Property"
    select tenants(:john_doe).full_name, from: "Tenant"
    fill_in "Start date", with: Date.current
    fill_in "End date", with: 1.year.from_now
    fill_in "Monthly rent", with: "1500.00"
    
    click_on "Create Rental"
    
    assert_text "Rental was successfully created"
    assert_current_path rental_path(Rental.last)
  end
  
  test "editing a rental updates the display in real-time" do
    rental = rentals(:active_rental)
    visit edit_rental_path(rental)
    
    fill_in "Monthly rent", with: "1800.00"
    click_on "Update Rental"
    
    # Test Turbo Frame update
    within "#rental_#{rental.id}" do
      assert_text "$1,800"
    end
  end
end
```

---

### **9. Performance and Security (Rails Built-in)**

#### **9.1 Query Optimization**
```ruby
# Avoid N+1 queries with includes
class RentalsController < ApplicationController
  def index
    @rentals = Rental.includes(:property, :tenant, :lease_agreements)
                     .where(created_at: 1.year.ago..Time.current)
                     .order(:start_date)
  end
end

# Use counter caches for performance
class Property < ApplicationRecord
  has_many :rentals, dependent: :destroy
end

class Rental < ApplicationRecord
  belongs_to :property, counter_cache: true
end
```

#### **9.2 Security (Rails Built-in)**
```ruby
# Strong parameters
def rental_params
  params.require(:rental).permit(:property_id, :tenant_id, :start_date, :end_date, :monthly_rent, :notes)
end

# CSRF protection (built-in)
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
end

# SQL injection prevention (use ActiveRecord)
# GOOD:
Rental.where(property_id: params[:property_id])

# BAD:
Rental.where("property_id = #{params[:property_id]}")
```

---

### **10. Git Strategy and Workflow**

#### **10.1 Branch Strategy (GitFlow with Domain Focus)**

```bash
# Main branches
main           # Production-ready code
develop        # Integration branch for features
release/*      # Release preparation branches
hotfix/*       # Critical production fixes

# Feature branches (domain-focused naming)
feature/rental-creation-domain     # Domain model implementation
feature/rental-search-capability   # Search functionality
feature/tenant-management-ui       # UI components
feature/payment-processing-logic   # Business logic

# Technical branches
tech/database-optimization        # Performance improvements
tech/security-enhancement         # Security updates
refactor/rental-service-extraction # Code refactoring
```

#### **10.2 Branch Naming Conventions**

```bash
# Domain-driven feature branches
feature/[domain-area]-[capability]
feature/rental-lifecycle-management
feature/property-valuation-engine
feature/tenant-screening-process

# Technical improvement branches
tech/[area]-[improvement]
tech/database-indexing
tech/api-response-caching
tech/security-audit-fixes

# Bug fix branches
fix/[domain-area]-[issue]
fix/rental-calculation-error
fix/tenant-notification-delivery

# Refactoring branches
refactor/[component]-[purpose]
refactor/rental-service-extraction
refactor/payment-model-simplification
```

#### **10.3 Commit Message Strategy (Domain-Focused)**

```bash
# Commit message format
<type>(<domain-area>): <description>

# Types
feat     # New domain capability
fix      # Domain logic correction
refactor # Code restructuring
test     # Test implementation
docs     # Documentation
style    # Code formatting
perf     # Performance improvement
security # Security enhancement

# Examples
feat(rental): implement lease expiration notification system
fix(payment): correct monthly rent calculation for leap years
test(tenant): add comprehensive validation test suite
refactor(property): extract valuation logic into service object
docs(rental): document domain model relationships and constraints
```

#### **10.4 Detailed Commit Message Template**

```bash
# Template for complex commits
feat(rental): implement automated lease renewal process

## Domain Context
- Rental agreements need automatic renewal capability
- Business rule: 60-day notice period for non-renewal
- Integration with notification system required

## Implementation Details
- Added RenewalService with business logic validation
- Created RenewalNotificationJob for automated alerts
- Updated Rental model with renewal_status enum

## Testing
- Unit tests for RenewalService business rules
- Integration tests for notification workflow
- System tests for user interface interactions

## Breaking Changes
- None

## Related Issues
- Closes #123: Implement lease renewal automation
- Addresses #456: Improve tenant communication workflow
```

#### **10.5 Git Workflow Process**

##### **10.5.1 Feature Development Workflow (TDD + DDD)**

```bash
# 1. Start new feature (domain-focused)
git checkout develop
git pull origin develop
git checkout -b feature/rental-payment-tracking

# 2. TDD Cycle Implementation
# Red Phase: Write failing test
git add test/models/payment_test.rb
git commit -m "test(payment): add failing test for payment validation"

# Green Phase: Make test pass
git add app/models/payment.rb
git commit -m "feat(payment): implement basic payment validation"

# Refactor Phase: Improve code quality
git add app/models/payment.rb
git commit -m "refactor(payment): extract validation logic to concerns"

# 3. Domain Service Implementation
git add app/services/payment_processing_service.rb
git add test/services/payment_processing_service_test.rb
git commit -m "feat(payment): implement payment processing domain service

## Domain Context
- Encapsulates payment processing business rules
- Handles multiple payment methods and validation
- Integrates with rental lifecycle management

## Implementation
- PaymentProcessingService with method-specific strategies
- Comprehensive error handling and edge cases
- Proper separation from controller logic"

# 4. Integration and System Tests
git add test/system/payment_workflow_test.rb
git commit -m "test(payment): add end-to-end payment workflow tests"

# 5. Documentation
git add README.md docs/payment_domain.md
git commit -m "docs(payment): document payment domain model and workflows"
```

##### **10.5.2 Code Review and Pull Request Process**

```bash
# 1. Pre-submission checklist
./bin/rails test                    # All tests pass
./bin/rails test:system            # System tests pass
bundle exec rubocop               # Code style compliance
bundle audit                      # Security vulnerability check

# 2. Push feature branch
git push origin feature/rental-payment-tracking

# 3. Create Pull Request with domain-focused template
```

**Pull Request Template:**
```markdown
## Domain Impact Assessment
- **Business Capability**: Payment processing and tracking
- **Domain Models Affected**: Payment, Rental, Tenant
- **Business Rules Implemented**: 
  - Late payment fee calculation
  - Payment method validation
  - Rental status updates

## Implementation Approach
- [ ] Test-driven development approach followed
- [ ] Domain logic properly encapsulated in models/services
- [ ] Controllers remain thin with proper delegation
- [ ] Database constraints match business rules
- [ ] Error handling covers edge cases

## Separation of Concerns Checklist
- [ ] Business logic in models/services, not controllers
- [ ] UI logic separated from domain logic
- [ ] Database queries optimized and properly scoped
- [ ] Hotwire/Stimulus properly separated from CSS/HTML
- [ ] TailwindCSS used instead of custom CSS where possible

## Testing Coverage
- [ ] Unit tests for all domain logic
- [ ] Integration tests for service interactions
- [ ] System tests for user workflows
- [ ] Edge cases and error conditions tested

## Security Considerations
- [ ] Input validation and sanitization
- [ ] Proper authorization checks
- [ ] SQL injection prevention
- [ ] CSRF protection maintained

## Performance Impact
- [ ] Database queries optimized
- [ ] N+1 query prevention
- [ ] Appropriate indexing added
- [ ] Caching strategy considered

## Breaking Changes
- [ ] None / List any breaking changes

## Domain Documentation
- [ ] Business rules documented
- [ ] API changes documented
- [ ] Migration guides provided if needed
```

#### **10.6 Git Hooks for Quality Assurance**

##### **10.6.1 Pre-commit Hook**
```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "Running pre-commit quality checks..."

# 1. Run RuboCop for style compliance
echo "Checking code style with RuboCop..."
bundle exec rubocop --auto-correct
if [ $? -ne 0 ]; then
  echo "RuboCop failed. Please fix style issues."
  exit 1
fi

# 2. Run fast unit tests
echo "Running unit tests..."
./bin/rails test:models test:controllers
if [ $? -ne 0 ]; then
  echo "Unit tests failed. Please fix failing tests."
  exit 1
fi

# 3. Check for domain model consistency
echo "Validating domain model consistency..."
./bin/rails runner "
  # Check for models without proper validations
  models_without_validations = ApplicationRecord.descendants.select do |model|
    model.validators.empty? && model.table_exists?
  end
  
  unless models_without_validations.empty?
    puts 'Warning: Models without validations:'
    models_without_validations.each { |m| puts '  - ' + m.name }
  end
"

# 4. Security vulnerability check
echo "Checking for security vulnerabilities..."
bundle audit
if [ $? -ne 0 ]; then
  echo "Security vulnerabilities found. Please review."
  exit 1
fi

echo "Pre-commit checks passed ✓"
```

##### **10.6.2 Pre-push Hook**
```bash
#!/bin/sh
# .git/hooks/pre-push

echo "Running comprehensive test suite before push..."

# 1. Full test suite
./bin/rails test
if [ $? -ne 0 ]; then
  echo "Test suite failed. Push aborted."
  exit 1
fi

# 2. System tests
./bin/rails test:system
if [ $? -ne 0 ]; then
  echo "System tests failed. Push aborted."
  exit 1
fi

echo "All tests passed. Push allowed ✓"
```

#### **10.7 Release Management and Deployment Strategy**

##### **10.7.1 Release Branch Workflow**
```bash
# 1. Create release branch from develop
git checkout develop
git pull origin develop
git checkout -b release/v2.1.0

# 2. Version bump and changelog
# Update VERSION file and CHANGELOG.md
git add VERSION CHANGELOG.md
git commit -m "chore(release): bump version to 2.1.0

## Release Highlights
- Enhanced rental payment processing
- Improved tenant notification system
- Performance optimizations for large datasets

## Domain Improvements
- Simplified lease renewal workflow
- Better error handling in payment processing
- Enhanced reporting capabilities"

# 3. Final testing and bug fixes
# Only bug fixes allowed in release branch

# 4. Merge to main and tag
git checkout main
git merge release/v2.1.0
git tag -a v2.1.0 -m "Release version 2.1.0"

# 5. Merge back to develop
git checkout develop
git merge release/v2.1.0

# 6. Clean up
git branch -d release/v2.1.0
```

##### **10.7.2 Hotfix Workflow**
```bash
# 1. Create hotfix from main
git checkout main
git pull origin main
git checkout -b hotfix/payment-calculation-fix

# 2. Implement fix with tests
git add test/models/payment_test.rb
git commit -m "test(payment): add test for leap year calculation bug"

git add app/models/payment.rb
git commit -m "fix(payment): correct monthly calculation for leap years

## Issue
- Payment calculations incorrect for February in leap years
- Affects monthly rent proration logic

## Solution
- Updated date calculation to handle leap year edge case
- Added comprehensive test coverage for date boundary conditions

## Impact
- Fixes calculation errors for 2024 leap year
- Prevents future date-related calculation issues"

# 3. Merge to main and develop
git checkout main
git merge hotfix/payment-calculation-fix
git tag -a v2.1.1 -m "Hotfix version 2.1.1"

git checkout develop
git merge hotfix/payment-calculation-fix

git branch -d hotfix/payment-calculation-fix
```

#### **10.8 Code Review Guidelines (Domain-Focused)**

##### **10.8.1 Review Checklist**
```markdown
## Domain Accuracy Review
- [ ] Business rules correctly implemented
- [ ] Domain model relationships accurate
- [ ] Validation rules match business requirements
- [ ] Edge cases properly handled

## Code Quality Review
- [ ] Test-driven development approach evident
- [ ] Proper separation of concerns maintained
- [ ] Controllers remain thin
- [ ] Services encapsulate business logic appropriately
- [ ] Database queries optimized

## Technical Review
- [ ] Rails conventions followed
- [ ] Security best practices applied
- [ ] Performance considerations addressed
- [ ] Error handling comprehensive

## Integration Review
- [ ] Hotwire integration clean and separate
- [ ] TailwindCSS used appropriately
- [ ] JavaScript concerns properly separated
- [ ] CSS only used where TailwindCSS insufficient
```

##### **10.8.2 Review Process**
```bash
# 1. Automated checks must pass
# CI/CD pipeline runs:
# - Full test suite
# - Code style checks
# - Security scans
# - Coverage reports

# 2. Domain expert review
# - Business logic accuracy
# - Domain model correctness
# - User experience validation

# 3. Technical review
# - Code quality and maintainability
# - Performance and security
# - Integration and deployment readiness

# 4. Final approval and merge
git checkout develop
git merge feature/rental-payment-tracking
git push origin develop
```

#### **10.9 Git Configuration for Team Consistency**

```bash
# .gitconfig team settings
[core]
    autocrlf = input
    editor = code --wait

[pull]
    rebase = true

[push]
    default = current

[branch]
    autosetupmerge = always
    autosetuprebase = always

[alias]
    # Domain-focused aliases
    feature = "!f() { git checkout develop && git pull && git checkout -b feature/$1; }; f"
    domain-commit = "!f() { git add . && git commit -m \"feat($1): $2\"; }; f"
    test-commit = "!f() { git add test/ && git commit -m \"test($1): $2\"; }; f"
    
    # Quality checks
    check = "!git diff --check && bundle exec rubocop && ./bin/rails test"
    review-ready = "!git check && git push origin HEAD"
    
    # Release management
    start-release = "!f() { git checkout develop && git pull && git checkout -b release/$1; }; f"
    finish-release = "!f() { git checkout main && git merge release/$1 && git tag $1 && git checkout develop && git merge release/$1; }; f"
```

### **10.10 AI Agent and Collaboration Rules**

- **Domain Understanding:** AI agents must understand the rental domain before generating code
- **TDD Compliance:** All AI-generated code must include comprehensive tests
- **Git Workflow:** AI agents must follow the established Git workflow and commit message standards
- **Separation of Concerns:** Maintain clear boundaries between controllers, models, services, and views
- **Rails Conventions:** Strictly follow Rails naming and structural conventions
- **Documentation:** Comment complex domain logic and business rules
- **Code Review:** All AI contributions require human review focusing on domain accuracy
- **Incremental Development:** Build features incrementally with working tests at each step
- **Git Hygiene:** Commit frequently with descriptive messages that tell the domain story

---

### **11. Project Planning and Task Management**

#### **11.1 Systematic Problem Decomposition**

```markdown
## Feature Planning Template

### 1. Domain Analysis
- **Business Capability**: [What business problem does this solve?]
- **Domain Entities**: [Which domain models are involved?]
- **Business Rules**: [What constraints and logic apply?]
- **User Stories**: [From domain expert perspective]

### 2. Technical Decomposition
- **Epic**: Major domain capability (e.g., "Rental Lifecycle Management")
- **Features**: Discrete business functions (e.g., "Lease Creation", "Payment Processing")
- **Tasks**: Technical implementation steps (e.g., "Create Payment model", "Add validation tests")
- **Subtasks**: Atomic development units (e.g., "Write failing test", "Implement validation")

### 3. Implementation Strategy
- **TDD Phases**: Red → Green → Refactor cycles
- **Domain Layers**: Model → Service → Controller → View
- **Integration Points**: External services, APIs, third-party gems
- **Testing Strategy**: Unit → Integration → System tests

### 4. Definition of Done
- [ ] All tests pass (unit, integration, system)
- [ ] Code review completed
- [ ] Domain logic properly encapsulated
- [ ] Documentation updated
- [ ] Performance benchmarks met
- [ ] Security considerations addressed
```

#### **11.2 Epic and Feature Breakdown Example**

```markdown
## Epic: Rental Property Management System

### Feature 1: Property Onboarding
**Domain Context**: Landlords need to register properties for rental

**Tasks**:
1. **Property Domain Model** (2 days)
   - [ ] Write failing tests for Property validations
   - [ ] Implement Property model with business rules
   - [ ] Add property type enumeration
   - [ ] Create database constraints

2. **Property Registration Service** (1 day)
   - [ ] Write PropertyRegistrationService tests
   - [ ] Implement service with validation logic
   - [ ] Add address validation and geocoding
   - [ ] Handle duplicate property detection

3. **Property Management UI** (3 days)
   - [ ] Create property listing interface
   - [ ] Build property creation form
   - [ ] Implement Hotwire-powered updates
   - [ ] Add image upload functionality

### Feature 2: Tenant Screening Process
**Domain Context**: Systematic tenant evaluation and approval

**Tasks**:
1. **Screening Domain Logic** (3 days)
2. **Application Processing Workflow** (2 days)
3. **Approval/Rejection System** (2 days)
```

#### **11.3 Task Tracking and Progress Management**

```bash
# Git branch naming reflects task hierarchy
feature/property-onboarding                    # Epic branch
  ├── feature/property-domain-model            # Feature implementation
  ├── feature/property-registration-service    # Service layer
  └── feature/property-management-ui           # UI components

# Commit progression shows TDD cycle
feat(property): add failing test for property validation
feat(property): implement basic property model
test(property): add comprehensive validation tests
refactor(property): extract validation concerns
docs(property): document property domain rules
```

#### **11.4 Learning and Knowledge Transfer**

```markdown
## Analogy-Based Learning Documentation

### New Concept: Rails Active Record Callbacks
**Familiar Analogy**: Event listeners in JavaScript

**Mapping**:
- `before_save` → `addEventListener('beforeSave')`
- `after_create` → `addEventListener('afterCreate')`
- Callback chain → Event propagation

**Implementation Example**:
```ruby
class Rental < ApplicationRecord
  # Like addEventListener('beforeSave', validateDates)
  before_save :calculate_total_amount
  
  # Like addEventListener('afterCreate', sendNotification)
  after_create :schedule_expiry_notification
end
```

### New Concept: Domain-Driven Design Value Objects
**Familiar Analogy**: Immutable data structures in functional programming

**Mapping**:
- Value Object → Immutable struct/record
- No identity → No mutable state
- Equality by value → Structural equality
```

### **12. File Organization and Naming**

```
app/
├── controllers/
│   ├── application_controller.rb
│   ├── rentals_controller.rb
│   └── concerns/
│       └── authorizable.rb
├── models/
│   ├── rental.rb
│   ├── property.rb
│   ├── tenant.rb
│   └── concerns/
│       └── rentable.rb
├── services/
│   ├── rental_creation_service.rb
│   ├── rental_search_service.rb
│   └── notification_service.rb
├── jobs/
│   └── rental_notification_job.rb
├── views/
│   ├── rentals/
│   │   ├── index.html.erb
│   │   ├── show.html.erb
│   │   ├── _rental_card.html.erb
│   │   └── _form.html.erb
│   └── shared/
│       └── _navigation.html.erb
└── javascript/
    └── controllers/
        └── rental_form_controller.js
```

---

> **Philosophy:** "Write code that tells a story about the rental business domain, not the technical implementation. Every commit should advance the domain understanding, and every pull request should enhance the business capability."

## **Development Principles Summary**

### **Domain-Driven Development**
- Understand the business domain before writing code
- Model real-world rental relationships and constraints
- Use ubiquitous language in code, tests, and documentation
- Separate domain logic from technical infrastructure

### **Test-Driven Quality**
- Write failing tests first (Red phase)
- Implement minimal code to pass (Green phase)
- Refactor for quality and maintainability (Refactor phase)
- Maintain comprehensive test coverage at all levels

### **Systematic Collaboration**
- Break complex features into manageable, testable tasks
- Use Git workflow to track domain evolution
- Conduct thorough code reviews focusing on domain accuracy
- Document learning and decisions for future reference

### **Clean Architecture**
- Maintain strict separation of concerns
- Keep controllers thin and focused on HTTP concerns
- Encapsulate business logic in models and services
- Separate UI concerns (HTML, CSS, JavaScript) appropriately

This enhanced guide ensures robust, maintainable code that accurately reflects the rental business domain while leveraging Rails' built-in capabilities, maintaining proper separation of concerns, and supporting effective team collaboration through structured Git workflows.