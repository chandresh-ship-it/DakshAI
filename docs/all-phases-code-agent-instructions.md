# 🤖 CODE AGENT INSTRUCTIONS — Full Build (Phases 1–5)

> Paste the relevant phase section into Claude Code / Antigravity as task context when you start that phase. Tech stack: Rails + Chatwoot fork, Vue frontend, Stripe Connect. All new backend code lives in `enterprise/` unless stated otherwise. Work through phases in order — later phases assume earlier schema exists.

---

# PHASE 1 — Foundation & Hierarchy

**Scope:** account hierarchy schema, capability gating, Super Admin hierarchy view (read-only). **Not in scope:** billing/payment logic (Phase 3).

## Step 0 — Before writing any code
1. Inspect the existing `accounts` table schema and paste it into context — confirm exact current columns before adding new ones.
2. Search the codebase for any existing feature-flag mechanism on `Account`. **Do not build a new `Capabilities` table if one already exists** — extend it instead. Report findings before proceeding.

## Step 1 — Schema migration: account hierarchy
```ruby
class AddHierarchyToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :parent_id, :bigint, null: true
    add_column :accounts, :is_reseller, :boolean, null: false, default: false
    add_index :accounts, :parent_id
    add_foreign_key :accounts, :accounts, column: :parent_id
  end
end
```

Model (`app/models/account.rb` or the enterprise override):
```ruby
belongs_to :parent, class_name: 'Account', optional: true
has_many :children, class_name: 'Account', foreign_key: :parent_id, dependent: :nullify

validate :parent_must_be_a_reseller
validate :no_self_parenting
validate :only_two_levels_deep

private

def parent_must_be_a_reseller
  return if parent.blank?
  errors.add(:parent_id, 'must reference an account with is_reseller = true') unless parent.is_reseller?
end

def no_self_parenting
  errors.add(:parent_id, 'cannot be its own parent') if parent_id.present? && parent_id == id
end

def only_two_levels_deep
  return if parent.blank?
  errors.add(:parent_id, 'cannot set a parent that itself has a parent (max 2 tiers)') if parent.parent_id.present?
end
```

**Do NOT:**
- Allow arbitrary nesting depth — strictly 2 tiers (T2 → T3).
- Infer `is_reseller` from `parent_id.nil?` — they're independent flags.

**Acceptance criteria:**
- [ ] `Account.new(parent: non_reseller_account)` fails validation.
- [ ] Self-parenting rejected.
- [ ] Three-tier chain rejected.

## Step 2 — Capability gating
If no existing mechanism found in Step 0:
```ruby
class CreateAccountCapabilities < ActiveRecord::Migration[7.0]
  def change
    create_table :account_capabilities do |t|
      t.references :account, null: false, foreign_key: true
      t.string :capability_key, null: false
      t.boolean :enabled, null: false, default: false
      t.timestamps
    end
    add_index :account_capabilities, [:account_id, :capability_key], unique: true
  end
end
```
Capability keys (fixed allowlist, not free-text): `white_labeling`, `custom_domain`, `reseller_dashboard`, `api_access`.

```ruby
CAPABILITY_KEYS = %w[white_labeling custom_domain reseller_dashboard api_access].freeze
validates :capability_key, inclusion: { in: CAPABILITY_KEYS }
```

```ruby
# on Account
def capability_enabled?(key)
  account_capabilities.exists?(capability_key: key, enabled: true)
end
```

**Do NOT:** gate features with scattered `if account.is_reseller?` checks — always go through `capability_enabled?`.

## Step 3 — Super Admin: Account Hierarchy view (read-only)
- `enterprise/app/controllers/super_admin/account_hierarchy_controller.rb`
- Controller: `@resellers = Account.where(is_reseller: true).includes(:children)`
- View: list resellers, expand to show T3 children. **No link/unlink or migration UI yet** — that's Phase 5.

**Acceptance criteria:**
- [ ] Super Admin sees reseller list with expandable children.
- [ ] Empty states handled (zero resellers, reseller with zero children).

---

# PHASE 2 — Reseller (T2) Infrastructure

**Scope:** branding storage, self-service onboarding/KYC, custom domain routing. Depends on Phase 1's `is_reseller` + capability gate (`white_labeling`, `custom_domain`).

## Step 0 — Before writing any code
Confirm where Chatwoot currently reads branding (logo, colors, `brand_name`) from — likely global ENV vars or a config initializer. Identify every call site before moving this to a per-account model, so nothing is missed.

## Step 1 — Move branding into Account records
```ruby
class AddBrandingToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :brand_name, :string
    add_column :accounts, :brand_logo_url, :string
    add_column :accounts, :brand_primary_color, :string
    add_column :accounts, :brand_secondary_color, :string
  end
end
```
Replace every ENV-based branding read found in Step 0 with `current_account.brand_name || DEFAULT_BRAND_NAME` (fallback to platform default when a T2 hasn't customized yet — never show a blank/broken UI).

**Do NOT:** delete the ENV fallback entirely — accounts with `white_labeling` disabled should still render platform-default branding, not empty strings.

## Step 2 — Self-service onboarding (KYC) for T2 payment accounts
This is the Connect account creation flow specced in the Subscription Feature Bible (Section 8/13) — build it here as part of T2 onboarding:
- `enterprise/app/services/enterprise/billing/connect_onboarding_service.rb` — creates a Stripe Express connected account for the account, generates an onboarding link.
- `enterprise/app/controllers/enterprise/api/v1/connected_accounts_controller.rb` — `POST` to kick off onboarding, `GET /status` to poll.
- Store result in `connected_accounts` table (see Phase 3 — create this migration now if Phase 3 hasn't started yet, since onboarding needs it):
```ruby
class CreateConnectedAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :connected_accounts do |t|
      t.references :account, null: false, foreign_key: true
      t.string :stripe_account_id, null: false
      t.string :country, null: false
      t.string :charge_routing, null: false   # 'destination' or 'separate_charge_transfer'
      t.string :onboarding_status, null: false, default: 'onboarding_incomplete'
      t.boolean :charges_enabled, default: false
      t.boolean :payouts_enabled, default: false
      t.timestamps
    end
  end
end
```
Set `charge_routing` at creation time based on the account's country — **India connected accounts get `separate_charge_transfer`, everyone else gets `destination`** (see Phase 3 for why).

**Do NOT:** let a T2 account without a `connected_account.charges_enabled = true` publish any pricing panel (Phase 3) or accept T3 payments — gate this explicitly.

## Step 3 — Custom domain routing (CNAME)
- Add `custom_domain` column to `accounts` (string, unique index).
- Middleware/controller concern to resolve `Account` by request host when `custom_domain` is set and matches, falling back to the default subdomain routing otherwise.
- Document (don't just assume) what SSL provisioning path is used for custom domains — Chatwoot forks vary here (Cloudflare for SaaS, Let's Encrypt via a cert-manager sidecar, etc.). Confirm before building, do not guess.

**Do NOT:** allow two accounts to claim the same `custom_domain` — enforce a DB-level unique index, not just application-level validation.

**Acceptance criteria (Phase 2 overall):**
- [x] T2 branding renders correctly with and without `white_labeling` enabled.
- [x] T2 can complete Stripe Express onboarding and reach `charges_enabled = true`.
- [x] Custom domain resolves to the correct account; duplicate domain claims rejected at the DB layer.

---

# PHASE 3 — Transactional Core (Payment Manager)

**Scope:** the billing engine itself — this phase is specced in full detail in the separate Subscription & Billing Feature Bible (v3.1). Summary of what the code agent needs to build, for continuity with this PDE plan:

## Step 1 — Two distinct billing relationships
- **Case 1 (Platform subscription, T1 → T2):** plain Stripe subscription, Super Admin sets price. No Connect split.
- **Case 2 (Marketplace subscription, T2 → T3):** T2 sets their own price via a self-serve panel; commission is computed and added on top, never deducted.

## Step 2 — Data model
```ruby
# plans / plan_prices — Case 1 pricing, Super Admin owned (standard)

# marketplace_plan_prices — Case 2 pricing, agency owned
create_table :marketplace_plan_prices do |t|
  t.references :account, null: false, foreign_key: true   # the T2 client_id
  t.string :currency, null: false
  t.decimal :agency_price, null: false
  t.decimal :commission_percent, null: false
  t.decimal :platform_fee_amount, null: false   # computed: agency_price * commission_percent
  t.decimal :total_amount, null: false           # computed: agency_price + platform_fee_amount
  t.string :stripe_price_id
  t.boolean :active, default: true
  t.timestamps
end

create_table :commission_rules do |t|
  t.references :account, null: false, foreign_key: true
  t.decimal :commission_percent, null: false, default: 30.0
  t.datetime :effective_from, null: false
  t.references :created_by_user
  t.timestamps
end
```

Add to `subscriptions`:
```ruby
add_column :subscriptions, :relationship_type, :string, null: false   # 'platform' or 'marketplace'
add_reference :subscriptions, :connected_account, foreign_key: true, null: true
add_column :subscriptions, :application_fee_amount, :decimal
```

## Step 3 — Commission formula (critical — do not get this wrong)
```
platform_fee_amount = agency_price * (commission_percent / 100.0)
total_amount = agency_price + platform_fee_amount
```
Then at Stripe checkout time, pass `application_fee_amount` (the fixed computed dollar value) — **never use Stripe's `application_fee_percent` parameter for this**, since that parameter computes percent-of-total, which would shortchange the agency relative to what they set.

## Step 4 — Country-aware charge routing
```ruby
class Billing::Tier3CheckoutService
  def call
    case connected_account.charge_routing
    when 'destination'
      # single API call: charge with transfer_data[destination] + application_fee_amount
    when 'separate_charge_transfer'
      # charge lands on platform account first, then a separate Transfer
      # moves (total_amount - platform_fee_amount) to the connected account
    end
  end
end
```

## Step 5 — T2 self-serve pricing panel
- `enterprise/app/controllers/enterprise/api/v1/tier2/pricing_panel_controller.rb`
- Slider/input UI (already prototyped) writing to `marketplace_plan_prices`.
- Live preview must show: agency price → platform fee → total client price, with copy making clear the fee is additive, not deducted.

**Do NOT:**
- Conflate Case 1 and Case 2 subscriptions in the same code path.
- Let a plan price change retroactively rewrite historical `application_fee_amount` values.
- Skip idempotency keys on the checkout endpoint (double-click protection).

**Acceptance criteria:** see the Subscription Feature Bible v3.1, Section 10, for the full checklist — reuse that as this phase's definition of done.

---

# PHASE 4 — Reliability & Orphaned Tenant Logic

**Scope:** webhook idempotency, T2→T1 rescue/promotion, grace periods on payment failure.

## Step 1 — Idempotent webhooks
```ruby
create_table :processed_webhook_events do |t|
  t.string :stripe_event_id, null: false
  t.string :event_type, null: false
  t.datetime :processed_at, null: false
end
add_index :processed_webhook_events, :stripe_event_id, unique: true
```
Webhook controller/job must check-and-insert this row **before** doing any side-effecting work, inside the same transaction as the side effect where possible, so a crash mid-processing doesn't leave a half-applied duplicate-prone state.

## Step 2 — Orphaned tenant rescue hook
When a T2 (`is_reseller` account) is deleted or suspended, its T3 children must not simply lose service. Build:
```ruby
class Billing::TenantRescueService
  def call(orphaned_t3_account)
    # 1. Detach: orphaned_t3_account.update!(parent_id: nil)
    # 2. Decide new billing relationship: promote to a direct 'platform' subscription,
    #    at a price to be determined by Super Admin policy (flag for manual review,
    #    do not auto-charge an assumed price)
    # 3. Notify the T3 account holder of the change before any billing change takes effect
  end
end
```

**Do NOT:** auto-charge the promoted T3 account any price without either an explicit default platform plan or Super Admin confirmation — silently picking a number here is a billing-trust incident waiting to happen.

## Step 3 — Grace periods
```ruby
add_column :subscriptions, :grace_period_ends_at, :datetime
```
On a T2 payment failure that would otherwise cascade to suspending T3 service, set `grace_period_ends_at = Time.current + 7.days` on affected T3 subscriptions instead of immediate suspension. A scheduled job checks and suspends only once the grace period has actually elapsed and the underlying T2 issue remains unresolved.

**Acceptance criteria:**
- [ ] Replaying an identical webhook event twice produces no duplicate side effects.
- [ ] Deleting/suspending a T2 account triggers the rescue flow for every T3 child, not a silent cascade suspension.
- [ ] A T3 client's service survives 7 days past a T2 payment failure before any suspension occurs.

---

# PHASE 5 — Chatwoot Super Admin & Governance

**Scope:** the mutation and audit tooling that Phase 1's read-only hierarchy view deliberately deferred.

## Step 1 — Reseller Management dashboard
- Extend the Phase 1 `account_hierarchy_controller` from read-only to support:
  - Toggling `is_reseller` on any account (with a confirmation step — this changes what validations apply to its children).
  - Manually linking/unlinking a T3 account to/from a T2 parent (reuses the Phase 1 model validations, so an invalid link is rejected at the model layer automatically).

## Step 2 — Financial Ledger Audit
- Global view aggregating `invoices` + `subscriptions.application_fee_amount` across all `connected_accounts` — total commission earned, filterable by date range and by T2 account.
- **"Stuck Payouts" view:** connected accounts where `payouts_enabled = false` or `onboarding_status = 'restricted'`, surfaced with the specific missing requirement pulled from Stripe's account object, not just a generic "blocked" label — Super Admin needs to know what to tell the agency to fix.

## Step 3 — Tenant Migration UI
- "Migrate Tenant" action: reassign a T3 account's `parent_id` from one T2 to another.
- Must carry over: active `marketplace_plan_prices` subscription state (or explicitly flag it for repricing under the new T2 — do not silently keep charging the old T2's price under a new parent without confirmation), full subscription/invoice history (never delete, only re-parent).

**Do NOT:** allow a tenant migration to silently drop billing history — this is an audit trail, treat deletion of `subscriptions`/`invoices` rows as forbidden in this flow entirely.

## Step 4 — Global Resource Quotas
- Add per-reseller limits (message volume, agent seats, contact count) enforced against shared Sidekiq/Redis capacity.
- Implementation: extend the Phase 1 `account_capabilities` pattern with a companion `account_limits` table (numeric caps) rather than overloading the boolean capability table with numeric values.
```ruby
create_table :account_limits do |t|
  t.references :account, null: false, foreign_key: true
  t.string :limit_key, null: false     # e.g. 'monthly_messages', 'agent_seats', 'contacts'
  t.integer :limit_value, null: false
  t.timestamps
end
add_index :account_limits, [:account_id, :limit_key], unique: true
```

**Acceptance criteria:**
- [ ] Super Admin can toggle `is_reseller` and manually re-parent a T3 account.
- [ ] Financial ledger view shows accurate aggregate commission, filterable.
- [ ] Stuck Payouts view surfaces the specific Stripe requirement blocking each account.
- [ ] Tenant migration preserves full billing history under the new parent.
- [ ] Per-reseller resource limits are enforced and visible to Super Admin.

---

## Build order summary

1. Phase 1 — hierarchy schema + capability gating + read-only Super Admin view
2. Phase 2 — branding, Connect onboarding, custom domains
3. Phase 3 — full billing engine (Case 1 + Case 2, commission formula, pricing panel)
4. Phase 4 — webhook idempotency, orphaned tenant rescue, grace periods
5. Phase 5 — mutation/audit tooling in Super Admin

Each phase should ship with its own test coverage and be reviewed before starting the next — Phase 3 in particular touches real money and should not proceed until Phases 1–2's account/hierarchy model is stable.
