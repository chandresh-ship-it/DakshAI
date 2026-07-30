<script setup>
import { h, ref, computed, onMounted, watch } from 'vue';
import { provideSidebarContext, useSidebarResize } from './provider';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useSidebarKeyboardShortcuts } from './useSidebarKeyboardShortcuts';
import { vOnClickOutside } from '@vueuse/components';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useWindowSize, useEventListener } from '@vueuse/core';

import Auth from 'dashboard/api/auth';
import ChannelLeaf from './ChannelLeaf.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';
import SidebarAccountSwitcher from './SidebarAccountSwitcher.vue';
import SidebarChangelogCard from './SidebarChangelogCard.vue';
import SidebarChangelogButton from './SidebarChangelogButton.vue';
import SidebarGroup from './SidebarGroup.vue';
import { SETTINGS_ROUTE_NAMES } from 'dashboard/routes/dashboard/settings/settings.navigation';

const props = defineProps({
  isMobileSidebarOpen: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'closeKeyShortcutModal',
  'openKeyShortcutModal',
  'showCreateAccountModal',
  'closeMobileSidebar',
]);

const { accountScopedRoute, isOnChatwootCloud } = useAccount();
const store = useStore();
const { t } = useI18n();

const isACustomBrandedInstance = useMapGetter(
  'globalConfig/isACustomBrandedInstance'
);
const globalConfig = useMapGetter('globalConfig/get');
const isRTL = useMapGetter('accounts/isRTL');
const brandInitial = computed(() => {
  const name = globalConfig.value?.installationName || 'N';
  return name.charAt(0).toUpperCase();
});
const brandSubtitle = computed(() => t('SIDEBAR.ENTERPRISE_EDITION'));

const { width: windowWidth } = useWindowSize();
const isMobile = computed(() => windowWidth.value < 768);

const accountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const hasConversationUnreadCounts = computed(() => {
  return isFeatureEnabledonAccount.value(
    accountId.value,
    FEATURE_FLAGS.CONVERSATION_UNREAD_COUNTS
  );
});

const fetchConversationUnreadCounts = ([currentAccountId, isEnabled]) => {
  if (!currentAccountId) return;

  if (!isEnabled) {
    store.dispatch('conversationUnreadCounts/clear');
    return;
  }

  store.dispatch('conversationUnreadCounts/get');
};

const toggleShortcutModalFn = show => {
  if (show) {
    emit('openKeyShortcutModal');
  } else {
    emit('closeKeyShortcutModal');
  }
};

useSidebarKeyboardShortcuts(toggleShortcutModalFn);

const expandedItem = ref(null);

const setExpandedItem = name => {
  expandedItem.value = expandedItem.value === name ? null : name;
};

const {
  sidebarWidth,
  isCollapsed,
  setSidebarWidth,
  saveWidth,
  snapToCollapsed,
  snapToExpanded,
  COLLAPSED_THRESHOLD,
} = useSidebarResize();

// On mobile, sidebar is always expanded (flyout mode)
const isEffectivelyCollapsed = computed(
  () => !isMobile.value && isCollapsed.value
);

// Resize handle logic
const isResizing = ref(false);
const startX = ref(0);
const startWidth = ref(0);

provideSidebarContext({
  expandedItem,
  setExpandedItem,
  isCollapsed: isEffectivelyCollapsed,
  sidebarWidth,
  isResizing,
});

// Get clientX from mouse or touch event
const getClientX = event =>
  event.touches ? event.touches[0].clientX : event.clientX;

const onResizeStart = event => {
  isResizing.value = true;
  startX.value = getClientX(event);
  startWidth.value = sidebarWidth.value;
  Object.assign(document.body.style, {
    cursor: 'col-resize',
    userSelect: 'none',
  });
  // Prevent default to avoid scrolling on touch
  event.preventDefault();
};

const onResizeMove = event => {
  if (!isResizing.value) return;

  const delta = isRTL.value
    ? startX.value - getClientX(event)
    : getClientX(event) - startX.value;
  setSidebarWidth(startWidth.value + delta);
};

const onResizeEnd = () => {
  if (!isResizing.value) return;

  isResizing.value = false;
  Object.assign(document.body.style, { cursor: '', userSelect: '' });

  // Snap to collapsed state if below threshold
  if (sidebarWidth.value < COLLAPSED_THRESHOLD) {
    snapToCollapsed();
  } else {
    saveWidth();
  }
};

const onResizeHandleDoubleClick = () => {
  if (isCollapsed.value) snapToExpanded();
  else snapToCollapsed();
};

const toggleSidebarCollapse = () => {
  if (isCollapsed.value) snapToExpanded();
  else snapToCollapsed();
};

defineExpose({ toggleSidebarCollapse });

// Support both mouse and touch events
useEventListener(document, 'mousemove', onResizeMove);
useEventListener(document, 'mouseup', onResizeEnd);
useEventListener(document, 'touchmove', onResizeMove, { passive: false });
useEventListener(document, 'touchend', onResizeEnd);

const inboxes = useMapGetter('inboxes/getInboxes');
const labels = useMapGetter('labels/getLabelsOnSidebar');
const getInboxUnreadCount = useMapGetter(
  'conversationUnreadCounts/getInboxUnreadCount'
);
const getLabelUnreadCount = useMapGetter(
  'conversationUnreadCounts/getLabelUnreadCount'
);
const getTeamUnreadCount = useMapGetter(
  'conversationUnreadCounts/getTeamUnreadCount'
);
const teams = useMapGetter('teams/getMyTeams');
const contactCustomViews = useMapGetter('customViews/getContactCustomViews');
const conversationCustomViews = useMapGetter(
  'customViews/getConversationCustomViews'
);
const inboxNotificationCount = useMapGetter('notifications/getUnreadCount');

onMounted(() => {
  store.dispatch('labels/get');
  store.dispatch('inboxes/get');
  store.dispatch('notifications/unReadCount');
  store.dispatch('teams/get');
  store.dispatch('attributes/get');
  store.dispatch('customViews/get', 'conversation');
  store.dispatch('customViews/get', 'contact');
});

watch([accountId, hasConversationUnreadCounts], fetchConversationUnreadCounts, {
  immediate: true,
});

const normalizeUnreadCount = count => {
  const unreadCount = Number(count);
  return Number.isFinite(unreadCount) && unreadCount > 0 ? unreadCount : 0;
};

const sortByUnreadCount = (items, labelKey, unreadCountKey) =>
  items.slice().sort((a, b) => {
    const unreadCountDiff =
      normalizeUnreadCount(unreadCountKey(b)) -
      normalizeUnreadCount(unreadCountKey(a));

    if (unreadCountDiff !== 0) return unreadCountDiff;

    return labelKey(a).localeCompare(labelKey(b));
  });

const sortedTeams = computed(() =>
  sortByUnreadCount(
    teams.value,
    team => team.name,
    team => getTeamUnreadCount.value(team.id)
  )
);

const sortedInboxes = computed(() =>
  sortByUnreadCount(
    inboxes.value,
    inbox => inbox.name,
    inbox => getInboxUnreadCount.value(inbox.id)
  )
);

const sortedLabels = computed(() =>
  sortByUnreadCount(
    labels.value,
    label => label.title,
    label => getLabelUnreadCount.value(label.id)
  )
);

const closeMobileSidebar = () => {
  if (!props.isMobileSidebarOpen) return;
  emit('closeMobileSidebar');
};

const newReportRoutes = () => [
  {
    name: 'Reports Agent',
    label: t('SIDEBAR.REPORTS_AGENT'),
    to: accountScopedRoute('agent_reports_index'),
    activeOn: ['agent_reports_show'],
  },
  {
    name: 'Reports Label',
    label: t('SIDEBAR.REPORTS_LABEL'),
    to: accountScopedRoute('label_reports_index'),
  },
  {
    name: 'Reports Inbox',
    label: t('SIDEBAR.REPORTS_INBOX'),
    to: accountScopedRoute('inbox_reports_index'),
    activeOn: ['inbox_reports_show'],
  },
  {
    name: 'Reports Team',
    label: t('SIDEBAR.REPORTS_TEAM'),
    to: accountScopedRoute('team_reports_index'),
    activeOn: ['team_reports_show'],
  },
];

const reportRoutes = computed(() => newReportRoutes());

const primaryMenuItems = computed(() => {
  return [
    {
      name: 'Customer Engagement',
      label: t('SIDEBAR.CUSTOMER_ENGAGEMENT'),
      icon: 'i-lucide-message-circle',
      children: [
        {
          name: 'Inbox',
          label: t('SIDEBAR.INBOX'),
          to: accountScopedRoute('inbox_view'),
          activeOn: ['inbox_view', 'inbox_view_conversation'],
          badgeCount: inboxNotificationCount.value,
        },
        {
          name: 'All',
          label: t('SIDEBAR.CONVERSATIONS'),
          activeOn: ['inbox_conversation'],
          to: accountScopedRoute('home'),
        },
        {
          name: 'Mentions',
          label: t('SIDEBAR.MENTIONED_CONVERSATIONS'),
          activeOn: ['conversation_through_mentions'],
          to: accountScopedRoute('conversation_mentions'),
        },
        {
          name: 'Participating',
          label: t('SIDEBAR.PARTICIPATING_CONVERSATIONS'),
          activeOn: ['conversation_through_participating'],
          to: accountScopedRoute('conversation_participating'),
        },
        {
          name: 'Unattended',
          activeOn: ['conversation_through_unattended'],
          label: t('SIDEBAR.UNATTENDED_CONVERSATIONS'),
          to: accountScopedRoute('conversation_unattended'),
        },
        {
          name: 'Folders',
          label: t('SIDEBAR.CUSTOM_VIEWS_FOLDER'),
          icon: 'i-lucide-folder',
          activeOn: ['conversations_through_folders'],
          children: conversationCustomViews.value.map(view => ({
            name: `${view.name}-${view.id}`,
            label: view.name,
            to: accountScopedRoute('folder_conversations', { id: view.id }),
          })),
        },
        {
          name: 'Teams',
          label: t('SIDEBAR.TEAMS'),
          icon: 'i-lucide-users',
          activeOn: ['conversations_through_team'],
          children: sortedTeams.value.map(team => ({
            name: `${team.name}-${team.id}`,
            label: team.name,
            badgeCount: getTeamUnreadCount.value(team.id),
            to: accountScopedRoute('team_conversations', { teamId: team.id }),
          })),
        },
        {
          name: 'Channels',
          label: t('SIDEBAR.CHANNELS'),
          icon: 'i-lucide-mailbox',
          activeOn: ['conversation_through_inbox'],
          children: sortedInboxes.value.map(inbox => ({
            name: `${inbox.name}-${inbox.id}`,
            label: inbox.name,
            badgeCount: getInboxUnreadCount.value(inbox.id),
            icon: h(ChannelIcon, { inbox, class: 'size-[16px]' }),
            to: accountScopedRoute('inbox_dashboard', { inbox_id: inbox.id }),
            component: leafProps =>
              h(ChannelLeaf, {
                label: leafProps.label,
                active: leafProps.active,
                inbox,
                badgeCount: leafProps.badgeCount,
              }),
          })),
        },
        {
          name: 'Labels',
          label: t('SIDEBAR.LABELS'),
          icon: 'i-lucide-tag',
          activeOn: ['conversations_through_label'],
          children: sortedLabels.value.map(label => ({
            name: `${label.title}-${label.id}`,
            label: label.title,
            badgeCount: getLabelUnreadCount.value(label.id),
            icon: h('span', {
              class: `size-[8px] rounded-sm`,
              style: { backgroundColor: label.color },
            }),
            to: accountScopedRoute('label_conversations', {
              label: label.title,
            }),
          })),
        },
      ],
    },
    {
      name: 'CRM & Sales',
      label: t('SIDEBAR.CRM_AND_SALES'),
      icon: 'i-lucide-users',
      children: [
        {
          name: 'All Contacts',
          label: t('SIDEBAR.CONTACTS'),
          to: accountScopedRoute(
            'contacts_dashboard_index',
            {},
            { page: 1, search: undefined }
          ),
          activeOn: ['contacts_dashboard_index', 'contacts_edit'],
        },
        {
          name: 'Active',
          label: t('SIDEBAR.ACTIVE'),
          to: accountScopedRoute('contacts_dashboard_active'),
          activeOn: ['contacts_dashboard_active'],
        },
        {
          name: 'Companies',
          label: t('SIDEBAR.COMPANIES'),
          to: accountScopedRoute('contacts_dashboard_companies'),
          activeOn: ['contacts_dashboard_companies'],
        },
        {
          name: 'Segments',
          icon: 'i-lucide-group',
          label: t('SIDEBAR.CUSTOM_VIEWS_SEGMENTS'),
          children: contactCustomViews.value.map(view => ({
            name: `${view.name}-${view.id}`,
            label: view.name,
            to: accountScopedRoute(
              'contacts_dashboard_segments_index',
              { segmentId: view.id },
              { page: 1 }
            ),
            activeOn: [
              'contacts_dashboard_segments_index',
              'contacts_edit_segment',
            ],
          })),
        },
        {
          name: 'Tagged With',
          icon: 'i-lucide-tag',
          label: t('SIDEBAR.TAGGED_WITH'),
          children: labels.value.map(label => ({
            name: `${label.title}-${label.id}`,
            label: label.title,
            icon: h('span', {
              class: `size-[8px] rounded-sm`,
              style: { backgroundColor: label.color },
            }),
            to: accountScopedRoute(
              'contacts_dashboard_labels_index',
              { label: label.title },
              { page: 1, search: undefined }
            ),
            activeOn: [
              'contacts_dashboard_labels_index',
              'contacts_edit_label',
            ],
          })),
        },
      ],
    },
    {
      name: 'Marketing',
      label: t('SIDEBAR.MARKETING'),
      icon: 'i-lucide-megaphone',
      children: [
        {
          name: 'Live chat',
          label: t('SIDEBAR.LIVE_CHAT'),
          to: accountScopedRoute('campaigns_livechat_index'),
        },
        {
          name: 'SMS',
          label: t('SIDEBAR.SMS'),
          to: accountScopedRoute('campaigns_sms_index'),
        },
        {
          name: 'WhatsApp',
          label: t('SIDEBAR.WHATSAPP'),
          to: accountScopedRoute('campaigns_whatsapp_index'),
        },
      ],
    },
    {
      name: 'Captain',
      icon: 'i-lucide-brain-circuit',
      label: t('SIDEBAR.CAPTAIN'),
      activeOn: ['captain_assistants_create_index'],
      children: [
        {
          name: 'FAQs',
          label: t('SIDEBAR.CAPTAIN_RESPONSES'),
          activeOn: [
            'captain_assistants_responses_index',
            'captain_assistants_responses_pending',
          ],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_responses_index',
          }),
        },
        {
          name: 'Documents',
          label: t('SIDEBAR.CAPTAIN_DOCUMENTS'),
          activeOn: ['captain_assistants_documents_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_documents_index',
          }),
        },
        {
          name: 'Scenarios',
          label: t('SIDEBAR.CAPTAIN_SCENARIOS'),
          activeOn: ['captain_assistants_scenarios_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_scenarios_index',
          }),
        },
        {
          name: 'Playground',
          label: t('SIDEBAR.CAPTAIN_PLAYGROUND'),
          activeOn: ['captain_assistants_playground_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_playground_index',
          }),
        },
        {
          name: 'Inboxes',
          label: t('SIDEBAR.CAPTAIN_INBOXES'),
          activeOn: ['captain_assistants_inboxes_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_inboxes_index',
          }),
        },
        {
          name: 'Tools',
          label: t('SIDEBAR.CAPTAIN_TOOLS'),
          activeOn: ['captain_tools_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_tools_index',
          }),
        },
        {
          name: 'Settings',
          label: t('SIDEBAR.CAPTAIN_SETTINGS'),
          activeOn: [
            'captain_assistants_settings_index',
            'captain_assistants_guidelines_index',
            'captain_assistants_guardrails_index',
          ],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_settings_index',
          }),
        },
      ],
    },
    {
      name: 'Reputation',
      icon: 'i-lucide-star',
      label: t('SIDEBAR.REPUTATION'),
      children: [
        {
          name: 'Reputation Overview',
          label: t('SIDEBAR.REPUTATION_OVERVIEW'),
          to: accountScopedRoute('reputation_overview'),
          activeOn: ['reputation_overview'],
        },
        {
          name: 'Reputation Reviews',
          label: t('SIDEBAR.REPUTATION_REVIEWS'),
          to: accountScopedRoute('reputation_reviews'),
          activeOn: ['reputation_reviews'],
        },
        {
          name: 'Reputation Video',
          label: t('SIDEBAR.REPUTATION_VIDEO'),
          to: accountScopedRoute('reputation_video_testimonials'),
          activeOn: ['reputation_video_testimonials'],
        },
        {
          name: 'Reputation Listings',
          label: t('SIDEBAR.REPUTATION_LISTINGS'),
          to: accountScopedRoute('reputation_widgets'),
          activeOn: ['reputation_widgets'],
        },
        {
          name: 'Reputation Feedback',
          label: t('SIDEBAR.REPUTATION_FEEDBACK'),
          to: accountScopedRoute('reputation_requests'),
          activeOn: ['reputation_requests'],
        },
        {
          name: 'Reputation Settings',
          label: t('SIDEBAR.REPUTATION_SETTINGS'),
          to: accountScopedRoute('reputation_settings'),
          activeOn: ['reputation_settings'],
        },
      ],
    },
    {
      name: 'Analytics',
      label: t('SIDEBAR.ANALYTICS'),
      icon: 'i-lucide-chart-bar',
      children: [
        {
          name: 'Report Overview',
          label: t('SIDEBAR.REPORTS_OVERVIEW'),
          to: accountScopedRoute('account_overview_reports'),
        },
        {
          name: 'Report Conversation',
          label: t('SIDEBAR.REPORTS_CONVERSATION'),
          to: accountScopedRoute('conversation_reports'),
        },
        ...reportRoutes.value,
        {
          name: 'Reports CSAT',
          label: t('SIDEBAR.CSAT'),
          to: accountScopedRoute('csat_reports'),
        },
        {
          name: 'Reports SLA',
          label: t('SIDEBAR.REPORTS_SLA'),
          to: accountScopedRoute('sla_reports'),
        },
        {
          name: 'Reports Bot',
          label: t('SIDEBAR.REPORTS_BOT'),
          to: accountScopedRoute('bot_reports'),
        },
      ],
    },
  ];
});

const administrationMenuItems = computed(() => [
  {
    name: 'Portals',
    label: t('SIDEBAR.KNOWLEDGE_BASE'),
    icon: 'i-lucide-help-circle',
    children: [
      {
        name: 'Articles',
        label: t('SIDEBAR.HELP_CENTER.ARTICLES'),
        activeOn: [
          'portals_articles_index',
          'portals_articles_new',
          'portals_articles_edit',
        ],
        to: accountScopedRoute('portals_index', {
          navigationPath: 'portals_articles_index',
        }),
      },
      {
        name: 'Categories',
        label: t('SIDEBAR.HELP_CENTER.CATEGORIES'),
        activeOn: [
          'portals_categories_index',
          'portals_categories_articles_index',
          'portals_categories_articles_edit',
        ],
        to: accountScopedRoute('portals_index', {
          navigationPath: 'portals_categories_index',
        }),
      },
      {
        name: 'Locales',
        label: t('SIDEBAR.HELP_CENTER.LOCALES'),
        activeOn: ['portals_locales_index'],
        to: accountScopedRoute('portals_index', {
          navigationPath: 'portals_locales_index',
        }),
      },
      {
        name: 'Settings',
        label: t('SIDEBAR.HELP_CENTER.SETTINGS'),
        activeOn: ['portals_settings_index'],
        to: accountScopedRoute('portals_index', {
          navigationPath: 'portals_settings_index',
        }),
      },
    ],
  },
]);

const navSections = computed(() => [
  { items: primaryMenuItems.value },
  {
    label: t('SIDEBAR.ADMINISTRATION'),
    items: administrationMenuItems.value,
  },
]);

const settingsMenuItem = computed(() => ({
  name: 'Settings',
  label: t('SIDEBAR.SETTINGS'),
  icon: 'i-lucide-settings',
  to: accountScopedRoute('settings_home'),
  activeOn: [
    ...SETTINGS_ROUTE_NAMES,
    'settings_home',
    'captain_settings_index',
  ],
}));

const logoutMenuItem = computed(() => ({
  name: 'Logout',
  label: t('SIDEBAR_ITEMS.LOGOUT'),
  icon: 'i-lucide-power',
  click: Auth.logout,
}));
</script>

<template>
  <aside
    v-on-click-outside="[
      closeMobileSidebar,
      {
        ignore: [
          '#mobile-sidebar-launcher',
          '[data-popover-content]',
          '[data-popover-backdrop]',
        ],
      },
    ]"
    class="group bg-sidebar text-sidebar-foreground flex h-full flex-col border-sidebar-border fixed top-0 z-40 w-60 pb-px text-sm ltr:left-0 ltr:border-r rtl:right-0 rtl:border-l md:relative md:w-auto md:flex-shrink-0 md:ltr:translate-x-0 md:rtl:translate-x-0"
    :class="[
      {
        'shadow-lg md:shadow-none': isMobileSidebarOpen,
        'ltr:-translate-x-full rtl:translate-x-full': !isMobileSidebarOpen,
        'transition-transform duration-200 ease-linear md:transition-[width]':
          !isResizing,
      },
    ]"
    :data-collapsed="isEffectivelyCollapsed ? 'true' : 'false'"
    :style="isMobile ? undefined : { width: `${sidebarWidth}px` }"
  >
    <!-- Header / brand -->
    <div
      class="flex flex-col gap-2 p-2 pb-6"
      :class="{ 'items-center': isEffectivelyCollapsed }"
    >
      <div
        class="flex h-12 w-full min-w-0 items-center gap-2 overflow-hidden rounded-md p-2 text-left text-sm transition-[width,height,padding]"
        :class="{
          'justify-center p-1.5': isEffectivelyCollapsed,
        }"
      >
        <template v-if="isEffectivelyCollapsed">
          <SidebarAccountSwitcher
            is-collapsed
            @show-create-account-modal="emit('showCreateAccountModal')"
          />
        </template>
        <template v-else>
          <div
            class="flex size-8 shrink-0 items-center justify-center rounded-lg bg-sidebar-primary text-sm font-bold text-sidebar-primary-foreground"
          >
            {{ brandInitial }}
          </div>
          <div class="grid min-w-0 flex-1 text-left text-sm leading-tight">
            <SidebarAccountSwitcher
              class="min-w-0"
              @show-create-account-modal="emit('showCreateAccountModal')"
            />
            <span
              class="truncate px-2 text-xs font-normal text-muted-foreground/60"
            >
              {{ brandSubtitle }}
            </span>
          </div>
        </template>
      </div>
    </div>

    <!-- Content -->
    <nav class="flex min-h-0 flex-1 flex-col overflow-y-auto no-scrollbar">
      <div
        v-for="(section, index) in navSections"
        :key="section.label || 'main'"
        class="relative flex w-full min-w-0 flex-col p-2 pt-0"
        :class="{ 'mt-1': index > 0 }"
      >
        <p
          v-if="section.label && !isEffectivelyCollapsed"
          class="mb-2 px-2 text-xs font-medium text-muted-foreground"
        >
          {{ section.label }}
        </p>
        <ul
          class="m-0 flex w-full min-w-0 list-none flex-col gap-3"
          :class="{ 'items-center': isEffectivelyCollapsed }"
        >
          <SidebarGroup
            v-for="item in section.items"
            :key="item.name"
            v-bind="item"
          />
        </ul>
      </div>
    </nav>

    <!-- Footer -->
    <div class="relative mt-auto flex flex-col gap-2 p-2">
      <div
        class="pointer-events-none absolute inset-x-0 -top-8 h-8 bg-gradient-to-t from-sidebar to-transparent"
      />
      <SidebarChangelogCard
        v-if="
          isOnChatwootCloud &&
          !isACustomBrandedInstance &&
          !isEffectivelyCollapsed
        "
      />
      <SidebarChangelogButton
        v-if="
          isOnChatwootCloud &&
          !isACustomBrandedInstance &&
          isEffectivelyCollapsed
        "
      />
      <ul
        class="m-0 flex w-full min-w-0 list-none flex-col gap-1"
        :class="{ 'items-center': isEffectivelyCollapsed }"
      >
        <SidebarGroup v-bind="settingsMenuItem" />
        <SidebarGroup v-bind="logoutMenuItem" />
      </ul>
    </div>

    <!-- Resize Handle (desktop only) -->
    <div
      class="absolute top-0 z-40 hidden h-full w-1 cursor-col-resize group md:block ltr:right-0 rtl:left-0"
      @mousedown="onResizeStart"
      @touchstart="onResizeStart"
      @dblclick="onResizeHandleDoubleClick"
    >
      <div
        class="absolute top-0 h-full w-px bg-transparent transition-colors group-hover:bg-sidebar-primary ltr:right-0 rtl:left-0"
        :class="{ 'bg-sidebar-primary': isResizing }"
      />
    </div>
  </aside>
</template>
