# Ofie Design System

A comprehensive design system for the Ofie property rental platform, ensuring consistent user experience across all pages and components.

## Overview

The Ofie design system is built on the principles of:
- **Glass Morphism**: Translucent elements with backdrop blur effects
- **Accessibility**: Clear visual hierarchy for users with varying literacy levels
- **Consistency**: Unified color schemes, typography, and interaction patterns
- **Responsiveness**: Mobile-first design that scales beautifully

## Core Design Elements

### 1. Glass Morphism Effects

All cards and major components use glass morphism for a modern, sophisticated look:

```css
.glass-card {
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(16px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 1.5rem; /* 24px */
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
}
```

### 2. Color System

#### Primary Colors
- **Blue**: `#3b82f6` to `#6366f1` (Primary actions, navigation)
- **Indigo**: `#4f46e5` to `#7c3aed` (Secondary actions)

#### Status Colors
- **Success**: `#10b981` to `#059669` (Green gradient)
- **Warning**: `#f59e0b` to `#ea580c` (Amber to orange)
- **Error**: `#ef4444` to `#ec4899` (Red to pink)
- **Info**: `#3b82f6` to `#6366f1` (Blue gradient)

#### Neutral Colors
- **Text Primary**: `#1f2937` (Gray-800)
- **Text Secondary**: `#6b7280` (Gray-500)
- **Background**: `#f8fafc` to `#e0e7ff` (Slate to blue gradient)

### 3. Typography

#### Font Family
- Primary: Inter (loaded via `inter-font` stylesheet)
- Fallback: system fonts

#### Font Weights
- **Regular**: 400 (body text)
- **Medium**: 500 (labels, secondary headings)
- **Semibold**: 600 (buttons, important text)
- **Bold**: 700 (primary headings, form labels)

#### Font Sizes
- **Heading 1**: `text-4xl md:text-5xl` (36px/48px)
- **Heading 2**: `text-3xl` (30px)
- **Heading 3**: `text-2xl` (24px)
- **Body**: `text-base` (16px)
- **Small**: `text-sm` (14px)

### 4. Spacing System

Based on Tailwind's spacing scale:
- **xs**: `0.5rem` (8px)
- **sm**: `1rem` (16px)
- **md**: `1.5rem` (24px)
- **lg**: `2rem` (32px)
- **xl**: `3rem` (48px)

### 5. Border Radius

- **Small**: `rounded-lg` (8px) - inputs, small buttons
- **Medium**: `rounded-xl` (12px) - icons, badges
- **Large**: `rounded-2xl` (16px) - buttons, form elements
- **Extra Large**: `rounded-3xl` (24px) - cards, modals

## Component Library

### Buttons

#### Primary Button
```erb
<button class="group inline-flex items-center justify-center px-6 py-4 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white rounded-2xl font-bold transition-all duration-300 shadow-lg hover:shadow-xl transform hover:-translate-y-0.5">
  Submit
</button>
```

#### Secondary Button
```erb
<button class="group inline-flex items-center justify-center px-6 py-3 border-2 border-gray-200 text-gray-700 bg-white/80 backdrop-blur-sm hover:bg-white hover:border-gray-300 rounded-2xl font-semibold transition-all duration-300 transform hover:-translate-y-0.5 hover:shadow-lg">
  Cancel
</button>
```

### Form Elements

#### Text Input
```erb
<input class="w-full px-4 py-3 bg-white border-2 border-gray-200 rounded-2xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300 font-medium placeholder-gray-400 hover:border-gray-300" />
```

#### Select Dropdown
```erb
<select class="w-full px-4 py-3 bg-white border-2 border-gray-200 rounded-2xl focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all duration-300 font-medium hover:border-gray-300">
  <option>Select option</option>
</select>
```

### Cards

#### Glass Card
```erb
<div class="bg-white/80 backdrop-blur-xl rounded-3xl shadow-xl shadow-gray-200/50 border border-white/20 p-8 hover:shadow-2xl hover:-translate-y-1 transition-all duration-300">
  <!-- Card content -->
</div>
```

### Icons

#### Icon Container
```erb
<div class="w-10 h-10 bg-gradient-to-r from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center shadow-lg shadow-blue-500/25">
  <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    <!-- SVG path -->
  </svg>
</div>
```

## Layout Patterns

### Background Pattern
```erb
<div class="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50 relative overflow-hidden">
  <!-- Background Pattern -->
  <div class="absolute inset-0 bg-grid-slate-100/50 [mask-image:linear-gradient(0deg,transparent,black)] pointer-events-none"></div>
  <div class="absolute top-0 right-0 w-96 h-96 bg-gradient-to-l from-purple-300/20 to-pink-300/20 rounded-full blur-3xl"></div>
  <div class="absolute bottom-0 left-0 w-96 h-96 bg-gradient-to-r from-blue-300/20 to-cyan-300/20 rounded-full blur-3xl"></div>
  
  <div class="relative z-10">
    <!-- Content -->
  </div>
</div>
```

## Accessibility Guidelines

### 1. Visual Hierarchy
- Use consistent heading levels (h1, h2, h3)
- Maintain proper contrast ratios (minimum 4.5:1)
- Include icons alongside text for better comprehension

### 2. Interactive Elements
- Minimum touch target size: 44px × 44px
- Clear focus states with visible outlines
- Hover effects that don't rely solely on color

### 3. Form Accessibility
- Always include labels with form inputs
- Use descriptive placeholder text
- Provide clear error messages
- Group related form elements

### 4. Color Usage
- Never rely solely on color to convey information
- Use icons and text alongside color coding
- Ensure sufficient contrast for all text

## Animation Guidelines

### Micro-interactions
- **Duration**: 200-300ms for most interactions
- **Easing**: `cubic-bezier(0.4, 0, 0.2, 1)` for smooth transitions
- **Hover Effects**: Subtle transforms (`translateY(-2px)`)
- **Focus States**: Ring effects with brand colors

### Page Transitions
- **Slide Up**: For modal appearances
- **Fade In**: For content loading
- **Scale In**: For popup elements

## Responsive Design

### Breakpoints
- **Mobile**: `< 640px`
- **Tablet**: `640px - 1024px`
- **Desktop**: `> 1024px`

### Grid Systems
- **Mobile**: Single column layouts
- **Tablet**: 2-column grids
- **Desktop**: 3-4 column grids

## Implementation Guidelines

### 1. CSS Organization
- Use the `design_system.css` file for core styles
- Follow BEM methodology for custom components
- Leverage Tailwind utilities for rapid development

### 2. Component Reusability
- Create partial templates for common components
- Use the `_design_system_components.html.erb` partial library
- Maintain consistent naming conventions

### 3. Performance
- Use CSS custom properties for theme values
- Minimize custom CSS in favor of utility classes
- Optimize images and use appropriate formats

## Browser Support

- **Modern Browsers**: Full support (Chrome 90+, Firefox 88+, Safari 14+)
- **Backdrop Filter**: Graceful degradation for older browsers
- **CSS Grid**: Flexbox fallbacks where needed

## Future Enhancements

1. **Dark Mode**: Implement dark theme variants
2. **High Contrast**: Enhanced accessibility mode
3. **Animation Preferences**: Respect `prefers-reduced-motion`
4. **Custom Themes**: Allow property managers to customize colors
5. **Component Documentation**: Interactive style guide

## Usage Examples

See the following files for implementation examples:
- `app/views/dashboard/index.html.erb` - Dashboard layout
- `app/views/properties/index.html.erb` - Property listings
- `app/views/auth/login_form.html.erb` - Form styling
- `app/views/maintenance_requests/new.html.erb` - Complex forms
- `app/views/shared/_flash_messages.html.erb` - Status messages
