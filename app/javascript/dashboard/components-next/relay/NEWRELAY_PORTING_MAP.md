# NewRelay-UI → Chatwoot porting map

Single source of truth for applying the **NewRelay-UI** design to this codebase.
Read this instead of re-reading every component. Pairs with [TOKENS.md](./TOKENS.md)
(token table) and [DESIGN.md](./DESIGN.md) (layout rules).

Reference project: `/Users/deependrasankhala/Documents/chandresh/NewRelay-UI`
(dev server: `http://localhost:5174`). Its tokens live in `src/style.css`; ours are a
**direct 1:1 port** in `app/javascript/dashboard/assets/scss/_relay-theme.scss`.

Last synced with NewRelay-UI `main`: **2026-08-10** (commit `ba1cbcf`). §2 UI components
unchanged; §3 gained auth, help-center, and extra settings mappings.

---

## 0. The golden rule — tokens are identical

NewRelay and Chatwoot Relay use the **same shadcn semantic tokens with the same hex values**.
When porting a NewRelay component, **keep its Tailwind classes as-is** (`bg-card`,
`text-foreground`, `text-muted-foreground`, `bg-primary`, `border-border`, `bg-muted`,
`bg-accent`, `text-primary`, `rounded-xl`, `shadow-sm`…). Do **not** translate them to
`n-*` legacy classes. Never hardcode hex.

| Thing | Value (light / dark) |
| --- | --- |
| Primary / brand | `#4f46e5` / `#6f71fb` (indigo) — class `bg-primary` / `text-primary` |
| Font (sans) | **Geist** — `font-sans` (already the default body font) |
| Font (mono) | **Geist Mono** — `font-mono` |
| Base radius | `0.75rem` → `rounded-lg`; cards use `rounded-xl` |
| Success / warning | `#00884b` / `#dca600` → `text-success` / `text-warning` |

---

## 1. Whole-project changes (font, background, brand color, radius)

Everything is token-driven, so a global restyle is **one file**:
`app/javascript/dashboard/assets/scss/_relay-theme.scss` (mirror of NewRelay `src/style.css`).

- **Change brand color everywhere** → edit `--primary` (and `--ring`, `--sidebar-primary`) in the `:root` and `.dark` blocks.
- **Change page background** → `--background`; card surface → `--card`; sidebar → `--sidebar`.
- **Change font** → `--font-sans` / `--font-mono` (fonts are declared in `fonts.css` equivalents).
- **Change corner roundness globally** → `--radius`.

Edit both the light (`:root`) and dark (`.dark`) values. No component edits needed —
every `bg-primary` / `text-foreground` / `rounded-lg` updates automatically.

---

## 2. Component equivalence (NewRelay `src/components/ui/*` → Chatwoot Relay)

Import Chatwoot components from `dashboard/components-next/relay`.

| NewRelay `ui/` | Chatwoot Relay | Notes |
| --- | --- | --- |
| `Button` | `RelayButton` | variants: `default`/`outline`/`ghost`; `size="icon"` |
| `Badge` | `RelayBadge` | |
| `Input` | `RelayInput` | prop `class-name` for input classes |
| `Label` | `RelayLabel` | |
| `Switch` | `RelaySwitch` | |
| `Checkbox` | `RelayCheckbox` | |
| `Tabs`/`TabsList`/`TabsTrigger`/`TabsContent` | `RelayTabs`/`RelayTabsList`/`RelayTabsTrigger`/`RelayTabsContent` | active state uses `aria-selected:` (not reka's `data-[state=active]:`) |
| `DropdownMenu*` (reka-ui) | `dashboard/components-next/dropdown-menu/DropdownMenu.vue` | different API: `:menu-items="[{label,value,action,icon}]"` + `@action` |
| `GlobalToast` | `useAlert` composable (`dashboard/composables`) | Chatwoot has no toast component — call `useAlert(msg)` |
| `KpiCard` | *no component* — use the **stat-card recipe** (§4) | |
| `DateRangePicker` | existing report date pickers (`HeatmapDateRangeSelector`, `OverviewReportFilters`) | |

Legacy `woot-*` / `WootButton` / `WootModal` are being phased out — never add new usages.

---

## 3. Page index (NewRelay view → Chatwoot location)

Look at the NewRelay view file for the exact markup, then edit the matching Chatwoot file.

NewRelay-UI grows fast — this table lists the stable, built-out mappings.
For anything not listed, run `find …/NewRelay-UI/src/views -name '*.vue'` and open
the matching view; the section recipes (§4) still apply.

| NewRelay `src/views/…` | Chatwoot location |
| --- | --- |
| `reports/ReportsView.vue` | `routes/dashboard/settings/reports/` — Overview=`LiveReports.vue`, wrapper=`components/ReportsWrapper.vue`, tables=`components/SummaryReports.vue`, cards=`components/overview/MetricCard.vue` + `components/overview/{Agent,Team}Table.vue`, heatmap=`components/heatmaps/BaseHeatmap.vue`, CSAT=`CsatResponses.vue`+`components/Csat*` |
| `conversations/ConversationsView.vue` | `routes/dashboard/conversation/`; list header + Mine/Unassigned/All tabs = `components/ChatList.vue`; rows = `components-next/Conversation/ConversationCard/` |
| `inbox/InboxView.vue` | `routes/dashboard/inbox/`; inbox rows = `components-next/Inbox/InboxCard.vue` |
| `companies/CompaniesView.vue` / `contacts/ContactsView.vue` | `routes/dashboard/companies/` / `routes/dashboard/contacts/` |
| `campaigns/{LiveChat,SMS,WhatsApp}CampaignsView.vue` | `routes/dashboard/campaigns/` |
| `settings/SettingsView.vue` + `settings/components/*` (AgentAssignment, Bots, **CannedResponses / Quick Replies**, CustomAttributes, **Macros**, **Sla**, Workflows, …) | `routes/dashboard/settings/` — Quick Replies / Canned Responses = `routes/dashboard/settings/canned/` (`Index.vue`, `AddCanned.vue`, `EditCanned.vue`), Macros = `macros/`, SLA = `sla/` |
| `settings/ProfileSettingsView.vue`, `settings/ProfileMfaView.vue` (+ `components/ProfileSettings.vue`, `ProfileMfa.vue`) | `routes/dashboard/settings/profile/` |
| `auth/{Login,Register,ForgotPassword,SsoLogin,Onboarding2View}.vue` | Chatwoot auth = `app/javascript/v3/views/auth/` (signup, password, reset, confirmation, verify-email); login/SSO screens live there too |
| `support/SupportView.vue` + `support/components/*` (Articles, ArticlesList, Categories, Locales, ArticleEditor, Settings, KeyboardShortcuts) | Help Center = `routes/dashboard/helpcenter/` |
| `captain/CaptainAiView.vue`, `copilot/CopilotView.vue` | Captain = `routes/dashboard/captain/` (enterprise); Copilot = conversation-side panel |
| `analytics/DashboardsView`, `RevenueAnalyticsView`, `CampaignAnalyticsView`; `tasks/`, `calendar/`, `ecommerce/*`; `reputation/`, `reviews/`, `deals/`, `funnels/`, `pipelines/`, `opportunities/`, `project-management/`, `surveys/`, `forms/`, `listings/` | **not built in Chatwoot** — sidebar shows the analytics ones disabled "Coming soon"; the rest have no Chatwoot equivalent |
| sidebar/layout | `components-next/sidebar/Sidebar.vue` (leaf styling = `SidebarGroupLeaf.vue`). NewRelay `AppSidebar.vue` now carries an **online-status pill** (agent presence) and a **Relay AI floating button**; `AppHeader.vue` holds the top-bar search/profile |

**Sidebar is now data-driven** in NewRelay: menu items live in `src/config/navigation.ts`
(consumed by `components/layout/AppSidebar.vue`). To mirror menu structure/labels, read
`navigation.ts` — don't scrape the markup.

---

## 4. Section recipes (exact class strings, verified against the reference)

Copy these; they are the NewRelay canonical markup.

### Page shell (report/settings-style page)
```html
<div class="px-8 pt-6">
  <h1 class="text-xl font-semibold tracking-tight text-foreground mb-1">Title</h1>
  <p class="text-sm text-muted-foreground mb-4">Subtitle.</p>
  <!-- tab bar -->
  <div class="flex items-center gap-6 text-[14px] border-b border-border/60 overflow-x-auto">
    <a class="pb-3 font-medium whitespace-nowrap border-b-2 -mb-px border-primary text-primary">Active</a>
    <a class="pb-3 font-medium whitespace-nowrap border-b-2 -mb-px border-transparent text-muted-foreground hover:text-foreground">Other</a>
  </div>
</div>
<div class="px-8 pt-6 pb-12 flex flex-col gap-6"><!-- sections --></div>
```

### Live badge (emerald pill)
```html
<div class="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-emerald-500/10 text-emerald-600 text-[12px] font-medium border border-emerald-500/20">
  <span class="size-1.5 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]"></span> Live
</div>
```

### Stat / KPI card (icon-left)
```html
<div class="group flex flex-col justify-between bg-card border border-border/60 rounded-xl shadow-sm p-5 transition-colors hover:border-primary/20">
  <div>
    <div class="flex items-center gap-2 mb-4">
      <span class="size-6 rounded-md bg-primary/10 text-primary grid place-content-center shrink-0">
        <span class="i-lucide-message-circle size-3.5"></span>
      </span>
      <h3 class="text-[13px] font-medium text-muted-foreground group-hover:text-foreground">Open</h3>
    </div>
    <div class="mb-1"><span class="text-[28px] leading-none font-semibold text-foreground tracking-tight">95</span></div>
    <div class="flex items-center gap-1.5 text-[12px]">
      <span class="font-medium text-emerald-500">14.3%</span>
      <span class="text-muted-foreground">vs last 7 days</span>
    </div>
  </div>
</div>
```

### Section card (heatmap / chart wrapper)
```html
<div class="p-6 rounded-xl border border-border bg-card shadow-sm flex flex-col gap-4">
  <div class="flex items-center justify-between">
    <div class="flex items-center gap-3"><h3 class="text-base font-medium text-foreground tracking-tight">Title</h3><!--Live--></div>
    <div class="flex items-center gap-2"><!-- dropdown buttons + download --></div>
  </div>
  <!-- body -->
</div>
```

### Dropdown / filter button (bordered)
```html
<button class="inline-flex items-center gap-2 h-8 px-3 text-[14px] rounded-md bg-card hover:bg-muted font-medium border border-border/80 shadow-sm text-foreground">
  <span class="i-lucide-calendar size-3.5 opacity-70"></span> Last 7 days
  <span class="i-lucide-chevron-down size-3.5 opacity-50"></span>
</button>
```

### Table card
```html
<div class="rounded-xl border border-border bg-card shadow-sm overflow-hidden flex flex-col">
  <div class="p-6 pb-4 flex items-center gap-3"><h3 class="text-base font-medium text-foreground tracking-tight">Title</h3><!--Live--></div>
  <div class="w-full overflow-x-auto">
    <table class="w-full text-left text-[14px]">
      <thead class="text-muted-foreground font-medium bg-muted/20">
        <tr><th class="px-6 py-4 font-medium">Agent</th><th class="px-6 py-4 font-medium">Open</th></tr>
      </thead>
      <tbody class="divide-y divide-border">
        <tr><td class="px-6 py-4 text-foreground">…</td></tr>
      </tbody>
    </table>
  </div>
</div>
```

### Heatmap cell intensity (via class binding)
Empty `bg-muted/50 dark:bg-muted/30`; ramp `bg-primary/20 → /35 → /50 → /65 → /80 → bg-primary`
(green variant swaps `primary` for `emerald-500`). Cell box: `h-8 rounded-[8px]` (or `w-[36px] h-[22px]`).

---

## 5. Porting workflow (follow every time)

1. Open the matching **NewRelay view** (§3) and/or read its rendered DOM at `localhost:5174`.
2. For each section, copy the canonical classes (§4 or the view file). Tokens are identical — keep them.
3. Swap NewRelay `ui/*` components for the **Relay equivalent** (§2).
4. Keep all Chatwoot **data logic / store dispatches / i18n**; only change markup + classes.
5. No bare strings — add i18n keys (frontend → `i18n/locale/en/*.json`).
6. Where Chatwoot has no data for a NewRelay element (e.g. trend %), mark it `NiN` (`REPORT.DATA_PENDING`) so it's visibly pending, don't fabricate.
7. Verify against `localhost:5174` after the dev server is healthy — never claim "matches" unrendered.
