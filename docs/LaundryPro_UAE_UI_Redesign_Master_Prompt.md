# LaundryPro UAE — Complete UI/UX Re-Architecture & Responsive Implementation Master Prompt

> **Purpose:** Use this prompt with an AI coding agent that has access to the complete LaundryPro UAE source repository, existing application, supplied logo, current UI screenshots, and `LaundryPro_UAE_Design.md`.
>
> **Execution mode:** Repository-aware product discovery, full UI/UX redesign, architecture planning, implementation, testing, and evidence-based verification. Do not stop at a conceptual design or generic recommendations.

---

## 0. Mission statement — complete redesign, not cosmetic polishing

You are acting as a world-class product design director, senior Flutter desktop architect, enterprise UX engineer, responsive layout specialist, accessibility reviewer, QA lead, and laundry-business domain analyst.

The current LaundryPro UAE interface has a serious expectation gap. The existing screen structure, visual hierarchy, spacing, navigation, responsiveness, typography, and content organization are substantially below the expected product quality. The current implementation is not an acceptable foundation for incremental styling adjustments. **Assume that a complete UI/UX redesign and a deliberate restructuring of the presentation layer are required.**

Do not merely change colours, increase corner radii, replace icons, add shadows, or imitate a dashboard screenshot. Diagnose the actual application, redesign its information architecture and screen composition, build a consistent reusable design system, and implement a genuinely responsive interface across every existing module.

The target is a premium, reliable, efficient, offline-first Windows standalone laundry-business operating application—not a generic web-admin template placed inside a desktop window.

### Product identity

- Product: **LaundryPro UAE**
- Product descriptor: **Business OS**
- Brand tagline: **Laundry operations, in control.**
- Product category: complete laundry operations CMS/CRM/POS/ERP-style standalone application.
- Primary platform: Windows desktop, with a resizable and responsive Flutter desktop interface.
- Business context: laundry and dry-cleaning operations, potentially across branches and terminals.
- Functional scope may include dashboard, orders, POS, production, advanced cycles, customers, vendors, services/catalogue, inventory, pickups/delivery, staff, payroll, bookkeeping, reports, branch/terminal setup, users/roles, and system settings. Treat the actual repository and approved requirements as the source of truth; do not invent modules that do not exist.
- Localization: English LTR and Arabic RTL must be first-class. Keep the localization system extensible for future languages.
- Default currency configuration: AED, subject to the product's actual business configuration. Currency values and formats must never be embedded as display literals in widgets.
- Deployment intent: standalone/local-first. Respect the existing local database and offline operating model. Do not introduce cloud/API dependencies merely to make the UI work.

### Required reference inputs

Inspect and use all available source material:

1. The complete current source-code repository, not only screenshots or selected widgets.
2. `LaundryPro_UAE_Design.md` as the initial brand and visual-direction reference.
3. The supplied LaundryPro droplet emblem/logo.
4. Current screenshots or running application of every accessible screen and state.
5. Existing route definitions, models, database schema, repositories, business rules, permission rules, configuration, and localization files.
6. Any existing functional requirements, use cases, workflows, or acceptance criteria in the project.

The supplied design document is a **design baseline, not an immutable implementation specification**. Preserve the intended premium navy/teal/aqua identity and the approved logo character, but challenge any fixed layout dimensions or examples that conflict with true responsiveness, accessibility, actual data, or the current project architecture. Values shown in a design table are starting proposals only; centralize them as design tokens/configuration and adapt them based on available space.

---

## 1. Non-negotiable outcomes

The completed work must satisfy all of the following:

1. A complete, coherent redesign of the entire application UI, not only the dashboard.
2. A reusable design system shared by all modules.
3. Real responsive reflow when the application window is resized; not simple proportional shrinking.
4. No scattered hardcoded UI text, business numbers, fake records, workflow stages, currency labels, dimensions, spacing values, or magic values.
5. A centralized localization system with complete English and Arabic coverage and real RTL layout behavior.
6. Dynamic, data-driven dashboards and operational screens connected to existing business data and correctly defined calculations.
7. Consistent loading, empty, partial-failure, offline, permission-denied, validation, success, and destructive-action states.
8. Preservation of existing business functionality, data integrity, calculations, permissions, and local persistence.
9. A maintainable component architecture with clear separation between presentation, application state, domain logic, and data access.
10. Evidence-based verification: tests, responsive viewport checks, localization checks, and before/after screenshots.

**Do not declare the redesign complete because one screenshot looks attractive.** It is complete only when the real screens, real data, real user workflows, window resizing, RTL, and failure states have been verified.

---

## 2. Hard rules: no hardcoding, no magic values, no fake data

This section is mandatory and overrides any shortcut that would make implementation faster but less maintainable.

### 2.1 UI text must be resource-driven

- Do not write user-facing labels, button captions, headings, navigation names, field hints, validation text, status names, tooltips, dialog copy, empty-state messages, error messages, notification copy, accessibility labels, or user-facing date descriptions directly inside page/widget source files.
- Define stable localization keys in the project's localization resources. Use the framework's established localization mechanism where possible (for example, ARB-generated localization if that is already the project convention).
- Provide complete English and Arabic translations for every new or modified key.
- Do not use a raw translation key as a visible fallback. Use a configured fallback language and log missing keys in development/test builds.
- Do not construct sentences by concatenating translated fragments where grammar can differ. Use parameterized localized messages with named placeholders and plural forms.
- Avoid hardcoded labels in navigation arrays, table columns, menu definitions, status chips, and form schemas. Their labels must resolve through localization keys.
- Do not embed UI copy in database queries, repositories, domain entities, or business services. Keep presentation wording in localization resources.
- Any user-configurable template or business label must come from a configuration or data source with validation and safe fallback behavior.

### 2.2 Business values must come from real sources

- Do not hardcode customer names, order references, amounts, revenue, percentages, item counts, inventory counts, user names, branch names, terminal names, or timestamps as production UI data.
- No sample dashboard values may leak into the real application or seed production state.
- Bind all dashboard metrics, charts, order queues, recent records, inventory indicators, and payroll/bookkeeping summaries to their authorized data sources.
- Define financial and operational calculations once in the appropriate domain/application layer. Do not recalculate the same financial truth independently inside multiple widgets.
- Distinguish `null`/unknown/not-yet-loaded/not-applicable from a true numeric zero.
- If a metric cannot be computed, show a localized unavailable state rather than inventing `0`, `0%`, or a trend.
- A percentage change must have a valid comparison period and denominator. Otherwise omit it or display the localized unavailable state.
- Keep raw numeric/date/time values separate from formatted display strings.

### 2.3 Configuration and design tokens must own all adjustable values

- No scattered magic numbers for margins, padding, gaps, dimensions, card radii, font sizes, icon sizes, chart heights, animation durations, sidebar widths, row heights, breakpoints, or control sizes.
- Define semantic design tokens in one centralized theme/design-system layer, grouped by purpose and named by meaning.
- Keep responsive breakpoint policy in one responsive configuration or layout policy layer. Widgets must consume the policy rather than define their own unrelated thresholds.
- The actual layout must respond to available constraints, not assume a fixed monitor size. Use `LayoutBuilder`, `MediaQuery` where appropriate, constraints, and reusable adaptive layout decisions.
- Use named constants for values that are genuinely invariant at the application level. Use editable business/tenant/branch configuration for values that administrators are meant to change.
- Store configurable workflow stages, menu availability, quick actions, supported payment methods, date/time preferences, currency, units, and feature availability in the relevant configuration/domain sources.
- Do not create a giant generic configuration file containing unrelated settings. Separate design tokens, localization, application preferences, business configuration, and domain configuration according to responsibility.
- Avoid hardcoded left/right positioning. Use directional layout primitives and semantic start/end alignment.
- Do not create a second competing set of tokens inside individual screens.

### 2.4 Data-driven navigation and workflow

- Navigation items must be derived from the actual registered modules, feature flags, role permissions, and product configuration.
- Workflow stage labels, sequence, allowed transitions, stage colors, and visibility must come from the configured workflow/domain source. Do not assume all laundries use the same number of stages.
- Quick actions must be role- and capability-aware. Do not display dead, disabled, or misleading actions.
- Service, item, unit, conversion, payment, tax, payroll, and inventory terminology must follow the actual domain model.
- Never invent fields or workflows to fit a visual mockup. Inspect the code and requirements first; document gaps for product-owner approval.

### 2.5 Allowed constants versus prohibited hardcoding

A production application will naturally contain technical constants, but those must be centralized, named, justified, and testable. The prohibition is against unexplained values scattered through widgets or values that should be data/configuration-driven. For example:

- Acceptable: a centralized `AppSpacingTokens.cardGap` used by all screens.
- Not acceptable: unrelated literal padding values repeated in dozens of widgets.
- Acceptable: an adaptive breakpoint policy that is centrally defined and tested.
- Not acceptable: different arbitrary width checks written independently by each page.
- Acceptable: a localization key resolved through the active locale.
- Not acceptable: an English string literal used directly as a button label.
- Acceptable: a real AED amount formatted by a shared currency formatter using active business settings.
- Not acceptable: a hardcoded `AED 0.00` display presented as business data.

Create automated checks, code review rules, or targeted searches to identify violations. Report any justified exceptions explicitly.

---

## 3. Stage zero — repository discovery and current-state audit

Do not begin by replacing files blindly. First map the application as it actually exists.

### 3.1 Inspect the project

Identify and document:

- Flutter/Dart and platform versions used by the repository.
- Existing application entry points and window configuration.
- Current routing/navigation approach.
- State-management approach and dependency boundaries.
- Database technology, connection lifecycle, repositories/DAOs, and transaction boundaries.
- Existing models/entities, services, view models/controllers, and feature modules.
- Current localization setup and language persistence.
- Existing theme, shared widgets, icon assets, fonts, charts, tables, and form controls.
- Existing role/permission model and feature licensing/visibility logic.
- Printer/scanner integration and local database health reporting.
- Tests, analysis rules, build configuration, and any existing UI automation.

Do not introduce a new state-management library, router, component package, or architectural pattern without first checking what is already used and whether it is adequate. Prefer strengthening the existing architecture over adding unnecessary dependencies.

### 3.2 Inventory every screen and route

Produce a screen inventory containing:

- Route/module identifier.
- User-facing localized title key.
- Business purpose and primary user task.
- Entry points and navigation context.
- Existing data source and write operations.
- User roles/permissions required.
- Current responsive behavior and observed defects.
- Loading, empty, error, and permission states available/missing.
- Reusable components currently used.
- Redesign priority and dependencies.

Include all existing screens, nested pages, dialogs, drawers, POS flows, settings pages, and relevant operational overlays. Do not audit only the main dashboard.

### 3.3 Capture and classify existing defects

Inspect the running application or screenshots at multiple window sizes. Categorize issues under:

- Information architecture and navigation.
- Layout hierarchy and content density.
- Horizontal/vertical overflow and clipping.
- Fixed-size assumptions.
- Inconsistent spacing and typography.
- Misaligned controls and tables.
- Excessive or wasted whitespace.
- Poor menu grouping and icon/label treatment.
- Inconsistent component behavior.
- LTR/RTL defects.
- Accessibility and keyboard interaction.
- Loading and failure-state defects.
- Fake/static content or incorrect data presentation.
- Unclear or duplicated actions.
- Performance/rebuild issues.

For each defect, explain the user impact, root cause, severity, affected screens, and recommended structural correction. Do not use subjective statements such as “make it modern” without a concrete implementation consequence.

### 3.4 Establish a baseline

Create a baseline pack before major changes:

- Screen/route inventory.
- Current screenshot set for representative screens and states.
- Responsive behavior matrix.
- Reusable component inventory.
- Hardcoded text/value findings.
- Technical dependency map.
- Known business rules that must not change.
- Current tests and build status.

If the application cannot be run, state the blocker precisely and continue with source inspection. Do not pretend a visual audit was performed when screenshots could not be captured.

---

## 4. Product UX strategy and information architecture

Redesign the application as one coherent Business OS with consistent navigation, terminology, and interaction rules.

### 4.1 UX objectives

Prioritize these outcomes:

- A counter operator can create and complete an order quickly with keyboard-first support.
- A production operator can see what work is waiting, what is in progress, what is blocked, and what is overdue.
- A manager can understand branch performance and exceptions without manually opening many reports.
- A cashier can see the amount due, payment status, balance, and print status without ambiguity.
- An administrator can configure branches, terminals, roles, workflows, localization, and peripherals without confusing global and local settings.
- A user can continue supported local operations when internet access is unavailable, according to the actual offline capability of the product.

### 4.2 Navigation architecture

Design a high-quality desktop navigation rail/sidebar with:

- A properly proportioned brand lockup using the supplied emblem.
- Clearly differentiated navigation groups.
- Readable item labels and consistent iconography.
- An unmistakable active route state.
- Predictable expanded and compact modes.
- Tooltips and accessible names in compact mode.
- Role/feature-aware visibility.
- Search or command navigation if appropriate to the existing product scale.
- A bottom account/operator area with profile and safe session actions.

Use actual module names from the project, and map all current modules to the redesigned information architecture before changing or removing any route. Preserve discoverability of less frequently used operations without crowding primary navigation.

### 4.3 Global application shell

Design one reusable shell for all feature pages. It should contain:

- Native/appropriately integrated Windows titlebar and application identity.
- Adaptive primary navigation.
- Workspace header with breadcrumb/context.
- Context-aware global search where supported.
- Branch selector and terminal selector where these are real domain concepts.
- Language control.
- Notifications only if supported by real application functionality.
- User/profile menu and role context.
- Main page outlet with independent content scrolling.
- Persistent system status area for verified local database and peripheral states.

Avoid competing header bars, giant empty title regions, a second dark strip with redundant page titles, and status indicators that imply services the application does not use. The shell must not rebuild unnecessarily when only one page-level metric changes.

---

## 5. Responsive layout architecture — adapt, do not shrink

Responsive behavior is a core architecture requirement, not a finishing step.

### 5.1 Use constraint-driven composition

- Make layout decisions from the available width/height of the actual content region.
- Do not assume the app always opens maximized or that the user has a particular monitor.
- Do not set page-wide fixed widths that leave unused space on wide displays or cause overflow on narrow windows.
- Do not use a single fixed dashboard grid for every size.
- Use reusable adaptive components and centralized breakpoint policy.
- Prefer flexible constraints, `Expanded`, `Flexible`, `Wrap`, adaptive grids, and deliberate scrolling over manually calculated screen coordinates.
- Avoid deeply nested scrollables. Each region must have a clear scroll owner.
- Do not assign fixed heights to text-bearing content where translated text or scaling can make it clip. Use intrinsic/flexible sizing or well-defined minimum constraints.
- Keep critical POS totals and primary action visible during order entry using a deliberate responsive strategy.

### 5.2 Define layout modes centrally

Define named layout modes such as wide desktop, standard desktop, compact desktop, narrow window, tablet-like width, and mobile-like width where relevant. The numeric thresholds must live in one responsive policy and be chosen from real screen testing—not scattered through widgets or treated as universal assumptions.

For each mode, document and implement:

- Sidebar: expanded, compact, drawer, or overlay.
- Header: full global search, compact search, or context action.
- Main content maximum width policy and horizontal gutters.
- Dashboard KPI column count and card minimum readable width.
- Analytics panel arrangement.
- Table strategy: full table, horizontal scroll, priority columns, or responsive row cards.
- Dialog versus full-page/drawer behavior.
- POS panel placement and sticky totals strategy.
- Typography and touch-target adjustments.
- Overflow and scrolling rules.

### 5.3 Window resize requirements

The user must be able to resize the Windows application freely within the supported minimum window constraints. On every resize:

- Components reflow without sudden overlap or clipping.
- Cards rewrap predictably.
- Sidebar changes mode without corrupting navigation state.
- Tables preserve essential information and give clear overflow affordances.
- Dialogs remain within visible bounds.
- Search and topbar controls never collide.
- Footer/status content does not cover the page.
- Keyboard focus and selected records remain stable.

### 5.4 Responsive acceptance cases

Create an explicit test matrix of realistic Windows window sizes and display-scaling conditions, plus compact/tablet-like sizes where supported. Store test viewport definitions centrally in test fixtures. Test both LTR and RTL, short and long translations, long names, large numeric values, and empty/loading/error states. Record screenshots and any deviations.

---

## 6. Brand and visual design system

Use `LaundryPro_UAE_Design.md` as the initial reference for identity and direction.

### 6.1 Brand character

The product should feel:

- Premium, calm, efficient, and trustworthy.
- Clearly connected to the supplied water/droplet/cleaning emblem.
- Enterprise-capable without looking like a generic banking dashboard.
- Practical for long daily counter and production sessions.
- Visually distinctive through navy foundations, teal/aqua accents, and restrained warm highlights.

Retain the existing emblem's droplet/ring/sparkle identity. Do not stretch, redraw inconsistently, add decorative effects on top of it, or replace it with generic laundry clip art. Use approved vector/raster logo assets appropriately; use a simplified small-size variant if the detailed artwork is illegible at tiny sizes.

### 6.2 Theme tokens

Create a centralized semantic token system for:

- Brand colours and neutral surfaces.
- Text roles and disabled/inverse colours.
- Semantic success/info/warning/danger states.
- Border and divider levels.
- Spacing scale and content gutters.
- Radius scale.
- Elevation/shadow levels.
- Typography family, sizes, weights, line heights, and tabular numerals.
- Icon dimensions/strokes.
- Control heights and minimum target sizes.
- Responsive layout policy.
- Motion durations and easing.
- Chart palette and data visualization rules.

The proposed navy/teal/aqua/gold and neutral palette in the design document may be retained as the baseline, but validate accessible contrast in the actual UI. Do not use colour alone to communicate status. Avoid excessive shadows, gradients, giant rounded pills, arbitrary coloured icon boxes, or decorative chart effects that reduce legibility.

### 6.3 Typography

Use a locally bundled, licence-verified English font family such as the approved Inter direction and a properly supported Arabic family such as Noto Sans Arabic, subject to repository and licence review. Do not depend on an online font service at runtime. Typography tokens must support Arabic shaping, language-specific line-height, tabular financial numerals, text scaling, ellipsis, and multi-line translated labels.

### 6.4 Visual consistency

Use a controlled icon family and consistent icon stroke/size roles. Use sentence case for visible text. Keep cards, toolbars, forms, tables, navigation, chips, menus, and dialogs visually related. Do not design every module independently. Avoid both excessive blank space and cramped high-density layouts; choose density according to the task and available space.

---

## 7. Dashboard — redesign requirements

The dashboard must be a useful live branch overview, not a collection of decorative static cards.

### 7.1 Dashboard questions

A user should be able to understand, quickly:

- Today's or selected-period sales/revenue according to a defined business metric.
- Orders created, active, due, or otherwise relevant to the selected period—use precise labels rather than an ambiguous “Orders”.
- Current production workload and configured workflow-stage distribution.
- Orders ready for collection/delivery.
- Revenue or order trends for the selected period.
- Recent orders that require attention.
- Operational exceptions, low stock, overdue work, or pending tasks where these are supported by real data.
- Local database and peripheral readiness.

### 7.2 Dashboard composition

Create an adaptive layout with a compact page-context header, date range/filter controls, a role-aware primary action, KPI cards, analytics, operational pipeline, recent activity/orders, and configurable quick actions. The exact number and order of panels must adapt to screen size and user role. Do not force a four-card row or any fixed panel count if content width cannot support it.

### 7.3 Dynamic metrics

For each metric, document:

- Stable metric identifier.
- Localized label key.
- Domain definition/formula.
- Data source/repository.
- Branch/terminal scope.
- Date range and timezone interpretation.
- Permission requirements.
- Empty/unknown/error treatment.
- Click-through destination and applied filters.

Use consistent domain calculations. Reconcile KPI values with their underlying list/report. Do not show trends without valid comparison data.

### 7.4 Pipeline and chart

- Production stages must be generated from configured workflow definitions.
- Stage counts and percentages must use a documented denominator.
- Colours and stage names must remain consistent across dashboard, order detail, and production queues.
- Charts must show date range, units, tooltips/exact values, and a readable no-data state.
- Use accessible textual summaries or companion data tables when chart-only presentation would hide important information.
- Do not fake values to make an empty dashboard look populated.

### 7.5 Dashboard interactions

- KPI cards open meaningful filtered views where permitted.
- Recent order rows open the correct order detail.
- Quick actions open real supported workflows.
- Date-range selection updates all dependent panels consistently.
- Partial data failure affects only the relevant panel where possible.
- Retry does not duplicate orders, payments, or other transactions.

---

## 8. Module-by-module redesign mandate

Apply the shared shell and design system consistently to every existing module. Use the repository inventory to confirm exact module scope and actual domain rules.

### 8.1 Orders / Live Orders

Create a searchable and filterable operational workspace with clear order reference, customer, service/item summary, due information, workflow state, payment state, total/balance, and detail/action access. Make filters collapsible/adaptive where needed. Preserve clear ordering and sorting semantics. Avoid a dense table that becomes unusable on narrow windows.

### 8.2 POS / counter sales

Design for high-frequency use:

- Fast customer search/selection and customer creation where permitted.
- Clear service/item selection based on the actual catalogue model.
- Correct unit/quantity/weight and conversion behavior from the domain model.
- Order line items with readable quantities, rates, adjustments, and totals.
- Due date/time and special instructions.
- Discounts, taxes, deposits, payments, and balances only as supported by actual business rules.
- A prominent, trustworthy financial summary.
- Explicit save/complete/print outcomes.
- Keyboard-first navigation and scanner input support.
- Touch-friendly controls where relevant.
- Duplicate-submission protection.

Saving an order and printing a receipt are distinct outcomes. A printer failure must not silently undo a successfully saved order or cause an accidental duplicate order.

### 8.3 Production / Advanced Cycles

Represent configured stages and permitted transitions clearly. Use queues/boards or grouped tables only when they improve the real workflow. Show due time, priority, item/service summary, blocking reason, and stage transition. Overdue and blocked work must be understandable without colour alone. Audit significant stage changes according to existing application rules.

### 8.4 Customers

Support efficient search, profile inspection, contact details, preferences, order history, account balance/credit information where permitted, and clear create/edit workflows. Respect privacy and role-based masking.

### 8.5 Vendors

Use a consistent supplier profile, purchase/transaction history, contact, outstanding balance, and related inventory/accounting activity where supported. Avoid duplicating vendor financial calculations in multiple screens.

### 8.6 Services / Catalogue

Present service, garment/item, add-on, pricing, units, and active/inactive state in a coherent model. Expose relevant unit/conversion behavior transparently. Do not create duplicate conversion concepts in the UI when the domain has a single authoritative conversion rule. Use effective-date and price version behavior only if actually supported.

### 8.7 Inventory Management

Make on-hand quantity, unit, low-stock thresholds, receipts, purchases, issues, consumption, transfers, returns, and adjustments understandable. All stock values and thresholds must come from real data/configuration. Require reasons and permissions for sensitive adjustments as dictated by domain rules.

### 8.8 Pickups and Delivery

If present, support assignment, task status, customer/address context, planned timing, exceptions, and delivery confirmation using real supported fields. Do not imply route optimization or live tracking unless the product actually supports it.

### 8.9 Staff and Payroll

Provide employee lists, role, employment status, attendance/shift information, payroll periods and calculation detail according to actual features. Protect confidential salary/personal data with permissions. Distinguish draft, calculated, approved, and paid states only where supported by the payroll domain.

### 8.10 Bookkeeping and Finance

Keep sales, receipts, expenses, receivables, payables, cash movement, balances, and ledgers understandable. Financial figures must be sourced and reconciled. Clearly distinguish posted/finalized records from drafts and adjustments. Never let UI convenience silently change accounting behavior.

### 8.11 Reports

Provide report-specific filter context, meaningful summaries, readable tables/charts, export/print functions only where supported, and consistent number/date formatting. Do not make chart colour the sole carrier of meaning.

### 8.12 Settings / Administration

Separate business-wide, branch-level, terminal-level, and user-level configuration. Clearly identify the scope and operational impact of each setting. Keep roles, permissions, localization, currency, workflow configuration, device settings, database maintenance, and preferences organized in understandable groups.

For all modules above: preserve real existing capability, do not invent functions, and document any missing requirement or ambiguous business rule instead of silently guessing.

---

## 9. Component library and code architecture

Build a reusable component system that supports the whole application without turning every page into a configurable mega-widget.

### 9.1 Shared components to evaluate/build

Create or refactor shared components for:

- Application shell and adaptive navigation.
- Workspace header and breadcrumbs.
- Search controls and filter bars.
- Page headings and action groups.
- Primary/secondary/tertiary/destructive buttons.
- KPI/metric cards.
- Cards and section panels.
- Data tables, responsive record lists, pagination, and sorting.
- Status chips and workflow indicators.
- Form fields, searchable selectors, validation, and helper text.
- Dialogs, drawers, confirmation flows, menus, and toasts.
- Empty, loading, error, offline, and permission states.
- Chart containers and accessible summaries.
- Persistent database/peripheral status area.

Reuse existing proven components where sound. Do not create near-duplicate components with slightly different margins or colors.

### 9.2 Separation of responsibilities

Keep these boundaries clear:

- **Presentation:** layout, visual components, navigation presentation, format application, interaction feedback.
- **Application/state layer:** screen state, user intents, orchestration, loading/error handling, filters, selected records.
- **Domain layer:** business rules, calculations, workflow policies, validations, permission decisions where appropriate.
- **Data layer:** repositories, database queries, persistence, mapping, transaction handling.
- **Configuration/localization:** theme tokens, responsive policy, localized resources, branch/terminal/business settings.

Widgets should not execute raw SQL, contain financial formulas, infer workflow state, or own persistence logic. Do not pass raw database maps through the presentation tree. Use typed models/view models appropriate to the existing architecture.

### 9.3 Keep state management deliberate

Use the project's current state-management approach unless the audit demonstrates a material deficiency. Avoid unnecessary global state. Keep local interaction state local and shared business state in the correct application layer. Handle cancellation, repeated taps, race conditions, stale responses, route changes, and disposal safely.

### 9.4 Feature organization

Organize by feature/domain with shared design-system infrastructure rather than placing every screen into one enormous folder. Do not reorganize the entire repository for cosmetic reasons. Provide a clear mapping of old files to new locations and avoid duplicate legacy screens remaining accidentally routable.

### 9.5 Performance

- Avoid rebuilding the full app shell for a local card update.
- Use lazy list/table rendering for long data sets.
- Apply pagination/filtering at the appropriate layer.
- Bound chart data and use efficient rendering.
- Load assets/fonts locally and avoid layout shifts.
- Avoid excessive shadow/blur/animation effects.
- Keep interaction responsive during database operations.
- Profile representative screens on the minimum supported hardware and Windows display scaling.

---

## 10. Offline-first, database, and device-status integrity

The product is intended to operate as a standalone desktop application. The redesign must reflect the actual architecture.

- Do not change database schema or business logic merely to satisfy a UI component unless a separately reviewed migration is necessary.
- Do not add external APIs, cloud requirements, telemetry, remote fonts, or internet-dependent UI assets as a shortcut.
- Use the existing local database/repository pathways and respect transaction boundaries.
- Distinguish local database availability from internet availability.
- Report database state only after checking the actual data-layer connection/health result.
- Report printer/scanner readiness only from real device detection/integration status.
- Distinguish “order saved” from “receipt printed”; distinguish “payment recorded” from “payment gateway confirmed” where applicable.
- Preserve unsaved form input on recoverable failure wherever safe.
- Provide safe retry behavior that does not duplicate financial or operational transactions.
- Do not claim queued sync, backup, cloud status, or automatic recovery unless implemented.
- Keep diagnostics appropriate to the user role; never expose SQL statements, stack traces, local file paths, or sensitive information to ordinary operators.

---

## 11. Localization, RTL, and content expansion testing

Treat language direction and text expansion as layout concerns across every feature.

### 11.1 Localization implementation

- Every visible UI string comes from a localization resource.
- Supply complete English and Arabic resources for every affected screen.
- Use named interpolation arguments and correct plural rules.
- Use locale-aware currency, quantity, date, time, and percentage formatters.
- Support business terminology review in Arabic; do not rely only on machine translation for operational terms.
- Bundle all required fonts locally with licence compliance.

### 11.2 RTL implementation

- Apply directionality at the appropriate application/page boundary.
- Use directional padding, alignment, borders, and layout logic.
- Mirror navigation and reading order deliberately.
- Do not mirror logos, product imagery, barcodes, or icons where mirroring changes meaning.
- Preserve readable formatting for order IDs, phone numbers, email addresses, technical codes, and mixed Arabic/Latin content using appropriate bidi isolation.
- Ensure dialogs, menus, tables, search fields, charts, and POS layouts behave correctly in RTL.

### 11.3 Long text and scaling

Test long translations, larger accessibility text scales, narrow window width, and real business names. Do not fix expansion problems by clipping important content or making all text tiny. Use wrapping, adaptive controls, tooltips for secondary metadata, and alternate layouts.

---

## 12. Interaction patterns and user feedback

Every interactive element must have a defined behavior and visual state:

- Default.
- Hover where applicable.
- Pressed.
- Keyboard focus.
- Disabled.
- Loading/in progress.
- Success.
- Failure.
- Permission denied where relevant.

Provide visible focus indicators and meaningful accessible names for icon-only controls. Ensure keyboard navigation covers all critical workflows. Use confirmation patterns for destructive, financial, inventory, and payroll actions in accordance with the actual permissions and domain rules.

Do not use a transient toast as the only record of a critical failure. Do not show buttons that do nothing. Do not use decorative status indicators that are disconnected from real system state. Do not present a clickable card unless it has a real, predictable action.

---

## 13. Accessibility and usability standards

Verify, at minimum:

- Readable contrast for all normal text and essential icons.
- Status meaning is not conveyed only by colour.
- Keyboard access to all major operations.
- Visible, logical focus order.
- Meaningful labels/tooltips for icon-only actions.
- Useful text sizing at Windows display scaling settings.
- No clipped fields, chips, table rows, Arabic glyphs, or dialogs.
- Practical targets for mouse and supported touch interaction.
- Reduced or nonessential motion is not required to understand state.
- Error messages explain what happened and the next safe action.

Treat accessibility as part of the component contract, not a final cosmetic audit.

---

## 14. Implementation plan and execution gates

Produce and follow a practical implementation sequence. Do not attempt a risky all-at-once rewrite without checkpoints.

### Phase A — Discovery and baseline

Deliver: repository map, screen inventory, architecture map, current-state screenshots, defect register, existing business behavior map, localization audit, hardcoding audit, risk register, and current test/build baseline.

**Gate:** every current route and core workflow is accounted for. Unknowns and dependencies are documented.

### Phase B — UX architecture and design system

Deliver: revised information architecture, shell specifications, navigation map, responsive behavior matrix, design token map, localization key strategy, component catalogue, screen layout wireframes/specifications, and architecture decisions.

**Gate:** each module has an approved layout strategy; no screen depends on bespoke, untracked styling.

### Phase C — Foundation implementation

Implement: central tokens, theme, typography, local fonts, localization resources, directionality, shared controls, responsive policy, common states, application shell, navigation, and status area.

**Gate:** shell works at target window modes in both LTR and RTL, with no obvious overflow or clipping.

### Phase D — Dashboard and shared data patterns

Implement: live KPI definitions, adaptive cards/grid, chart/pipeline components, recent orders, quick actions, filters, error boundaries, and data-source integration.

**Gate:** values reconcile with source records and empty/loading/failure states work.

### Phase E — Feature-by-feature rollout

Refactor modules in a dependency-aware sequence, normally prioritizing POS/order workflow and production operations, followed by customer/catalogue/inventory and administrative/finance modules according to repository dependencies. Use the same shared shell and components.

**Gate:** each module passes functional regression, responsive, localization, permission and data-integrity checks before moving on.

### Phase F — Full responsive and RTL hardening

Run the complete viewport matrix, long-content cases, scaling checks, LTR/RTL checks, keyboard pass, and peripheral-state tests. Resolve all critical/high severity defects.

**Gate:** no P0/P1 UI defects, no known data-integrity regressions, and no unexplained overflow in supported layouts.

### Phase G — Stabilization and handover

Deliver final screenshots, test results, code quality results, updated documentation, migration notes, known limitations, and a rollback/recovery plan for the UI rollout.

**Gate:** build and automated checks pass; unresolved issues are disclosed, not hidden.

---

## 15. Required deliverables from the AI coding agent

Produce these deliverables in the repository or agreed output location.

### 15.1 Planning/documentation deliverables

1. **Current UI/UX audit:** screen-by-screen defects with severity, cause, impact, and resolution.
2. **Complete redesign specification:** target information architecture, page composition, interactions, and shared system.
3. **Responsive implementation plan:** layout modes, adaptation rules, overflow policy, and viewport test matrix.
4. **Design-system specification:** semantic tokens, typography, iconography, component standards, and theme rules.
5. **Localization/RTL specification:** resource key convention, Arabic coverage, bidi behavior, and test cases.
6. **Architecture implementation map:** actual repository paths, classes/components to retain/refactor/create/remove, dependencies, and migration order.
7. **Screen acceptance matrix:** expected behavior and test evidence for every existing route.
8. **Risk and dependency register:** unresolved business rules, technical risks, and safe mitigation.

### 15.2 Implementation deliverables

1. Fully redesigned shared application shell.
2. Centralized theme/design token system.
3. Centralized responsive layout policy.
4. Complete localization resource updates for English and Arabic.
5. Reusable controls, cards, tables, status components, dialogs, and common UI states.
6. Rebuilt dashboard connected to actual data.
7. Redesigned all existing application modules according to the inventory.
8. Reliable LTR/RTL layout and locale-aware formatters.
9. Real local database/peripheral status presentation.
10. Automated tests and maintained developer documentation.

### 15.3 Evidence deliverables

- Before/after screenshots for all high-priority screens.
- Screenshots at representative wide, standard, compact, and narrow window sizes.
- English LTR and Arabic RTL screenshots.
- Screenshots of loading, empty, error, no-permission, and populated states where applicable.
- Test command output and pass/fail summary.
- Build result for the supported Windows target.
- List of remaining defects and known limitations.

Do not fabricate screenshots or test results. State which scenarios were actually executed and which remain unverified.

---

## 16. Test strategy and quality gates

### 16.1 Automated tests

Add or update tests for:

- Token/theme availability and semantic consistency.
- Localization key coverage and missing translation detection.
- Formatting of currency, numbers, dates, times, percentages, and quantities.
- Responsive mode selection and adaptive component behavior.
- Navigation visibility under different role/feature configurations.
- KPI definitions and date-range behavior at the application/domain layer.
- Empty/null/zero/loading/error distinction.
- Workflow stage rendering from configuration.
- Safe retry and duplicate-submission prevention.
- RTL direction and logical alignment where testable.
- Regression of critical POS/order flows.

### 16.2 Widget/integration tests

Cover representative screens and critical interactions:

- Application shell and navigation.
- Dashboard filter changes and KPI navigation.
- New order/POS entry, save, payment, and print-failure handling.
- Production stage transition.
- Customer search/detail.
- Inventory movement or adjustment where supported.
- Language switch and RTL behavior.
- Permission-restricted actions.
- Database unavailable and peripheral unavailable states.

### 16.3 Visual regression

Establish stable screenshot tests or documented manual screenshot comparisons for the supported viewport matrix. Avoid brittle pixel tests where fonts/platform rendering differ; compare layout bounds, clipping, alignment, and key component states. Record intentional differences.

### 16.4 Quality gates

Before declaring done:

- Run formatter and static analysis.
- Run relevant unit, widget, and integration tests.
- Build the supported Windows application target.
- Verify startup and core flows against a test/local database.
- Check for overflow/clipping warnings.
- Search for remaining hardcoded UI copy and scattered magic layout values.
- Confirm no unintended dependency or backend/database changes.
- Confirm no production fake/sample dashboard values.
- Provide an explicit pass/fail/blocked report.

---

## 17. Risk control and preservation rules

- Do not remove an existing route, control, workflow, or permission check until its usage and dependencies are understood.
- Do not rename database fields or alter schema as part of visual refactoring unless separately justified and migrated.
- Do not change business formulas while moving UI code.
- Do not silently change the meaning of order, payment, inventory, payroll, or accounting states.
- Do not delete legacy files until route and dependency references are verified.
- Do not add unapproved network/cloud dependencies.
- Do not turn configuration into uncontrolled free text where validation is necessary.
- Do not hide an unavailable feature behind a decorative button.
- Do not replace a real business flow with a mock interaction.
- Keep changes incremental enough to review, test, and recover.

When a business rule is ambiguous, trace it through existing code and data first. If it remains unresolved, document the exact decision required and isolate the UI behavior so it can be adjusted without a broad rewrite. Do not ask the user to repeat information already present in the repository or supplied documents.

---

## 18. Required response format from the coding agent

Work in this order and report results clearly:

### Part 1 — Findings

Summarize the actual repository architecture, all discovered screens, current UI defects, responsive failures, existing hardcoding, localization gaps, and business rules that must be preserved. Cite actual source paths and class/widget names from the repository.

### Part 2 — Redesign blueprint

Provide the new navigation and screen architecture, shell layout, adaptive behavior matrix, design tokens, component inventory, localization strategy, and module-specific layout decisions. Explain how the new approach resolves each major observed defect.

### Part 3 — Implementation roadmap

Break the work into phases, actual files, dependencies, expected outputs, test coverage, risks, and completion gates. Do not estimate effort with false precision before repository discovery.

### Part 4 — Implementation

Make the actual source changes in dependency order. Do not stop after writing a plan unless access or a genuine technical blocker prevents implementation. Keep the code aligned with the existing project stack and patterns.

### Part 5 — Verification

Report analyzer/build/test results, responsive checks, localization checks, data integrity checks, screenshot evidence, and remaining known issues. Separate “implemented”, “tested”, “visually inspected”, and “not verified”.

### Part 6 — Handover

List changed files, newly introduced tokens/components/resources, configuration decisions, any migration requirement, and exact next actions for unresolved items.

---

## 19. Definition of done

The redesign is acceptable only when all applicable conditions are true:

- [ ] Every existing screen and route has been inventoried and assigned a redesign outcome.
- [ ] The overall UI has been structurally redesigned, not merely recoloured.
- [ ] Navigation and shell are consistent across modules.
- [ ] Responsive layouts genuinely reflow at supported window sizes.
- [ ] No known text clipping, overlap, inaccessible controls, or accidental horizontal overflow remains in supported modes.
- [ ] UI text is resource-driven and English/Arabic coverage is complete for modified screens.
- [ ] RTL is functionally correct, including mixed-direction content.
- [ ] Design values are centralized; no unexplained magic layout values are scattered through page widgets.
- [ ] Business values come from real data/configuration; no mock dashboard metrics leak into production.
- [ ] Workflow stages, menu visibility, and quick actions follow actual configuration and permissions.
- [ ] KPI and financial calculations reconcile to source records.
- [ ] Loading, empty, error, offline, permission, and success states are deliberate and correct.
- [ ] POS and other high-frequency workflows remain efficient and keyboard accessible.
- [ ] Printer/scanner/database statuses reflect actual state.
- [ ] Existing business logic, data integrity, and core workflows have not regressed.
- [ ] Automated tests, static analysis, and Windows build have been run and results recorded.
- [ ] Representative screenshots document the actual implemented application at multiple sizes and in both languages.
- [ ] Remaining limitations and unverified scenarios are explicitly disclosed.

---

## 20. Final instruction — think like a product owner, architect, and operator

Do not optimize for the easiest code change or the fastest screenshot. Optimize for the quality of the complete operating experience.

Challenge the current layout wherever the evidence shows that its structure is weak. Design for the real work performed by laundry owners, counter staff, production operators, cashiers, managers, and administrators. Respect the standalone/offline-first product model. Keep the supplied LaundryPro identity recognizable. Make the UI responsive by design, not by afterthought. Make every label, value, state, and layout rule traceable to localization, data, domain configuration, or centralized design tokens.

**The expected result is a coherent, production-grade LaundryPro UAE Business OS interface that feels intentionally designed across the whole application—not a dashboard mockup surrounded by old screens.**

Begin with repository discovery and a complete screen audit. Then deliver the redesign blueprint and execute it in controlled, testable phases.
