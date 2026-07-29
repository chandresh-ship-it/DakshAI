<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { usePolicy } from 'dashboard/composables/usePolicy';
import {
  isSafeHttpLink,
  formatDocumentLink,
  getDocumentDisplayPath,
} from 'shared/helpers/documentHelper';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayButton, RelayCheckbox } from 'dashboard/components-next/relay';
import DocumentSyncStatus from 'dashboard/components-next/captain/assistant/DocumentSyncStatus.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  name: {
    type: String,
    default: '',
  },
  assistant: {
    type: Object,
    default: () => ({}),
  },
  externalLink: {
    type: String,
    required: true,
  },
  pdfDocument: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Number,
    required: true,
  },
  status: {
    type: String,
    default: null,
  },
  syncStatus: {
    type: String,
    default: null,
  },
  lastSyncedAt: {
    type: Number,
    default: null,
  },
  lastSyncErrorCode: {
    type: String,
    default: null,
  },
  syncInProgress: {
    type: Boolean,
    default: false,
  },
  syncStaleAfterHours: {
    type: Number,
    default: null,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
  selectable: {
    type: Boolean,
    default: false,
  },
  showSelectionControl: {
    type: Boolean,
    default: false,
  },
  showMenu: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['action', 'select', 'hover']);
const { checkPermissions } = usePolicy();

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();
const modelValue = computed({
  get: () => props.isSelected,
  set: () => emit('select', props.id),
});

const isPdf = computed(() => props.pdfDocument);
const hasSafeLink = computed(() => isSafeHttpLink(props.externalLink));
const canManage = computed(() => checkPermissions(['administrator']));
const isAvailable = computed(() => props.status === 'available');
const canSync = computed(
  () => canManage.value && !isPdf.value && isAvailable.value
);
const isSyncing = computed(() => props.syncStatus === 'syncing');
const isFailed = computed(() => props.syncStatus === 'failed');
const isRetryableSync = computed(
  () => isFailed.value || (isSyncing.value && !props.syncInProgress)
);
const showSyncStatus = computed(() => !isPdf.value);

const menuItems = computed(() => {
  const allOptions = [
    {
      label: t('CAPTAIN.DOCUMENTS.OPTIONS.VIEW_RELATED_RESPONSES'),
      value: 'viewRelatedQuestions',
      action: 'viewRelatedQuestions',
      icon: 'i-ph-tree-view-duotone',
    },
  ];

  if (canSync.value) {
    allOptions.push({
      label: isRetryableSync.value
        ? t('CAPTAIN.DOCUMENTS.OPTIONS.RETRY_SYNC')
        : t('CAPTAIN.DOCUMENTS.OPTIONS.SYNC_NOW'),
      value: 'sync',
      action: 'sync',
      icon: 'i-lucide-refresh-cw',
    });
  }

  if (canManage.value) {
    allOptions.push({
      label: t('CAPTAIN.DOCUMENTS.OPTIONS.DELETE_DOCUMENT'),
      value: 'delete',
      action: 'delete',
      icon: 'i-lucide-trash',
    });
  }

  return allOptions;
});

const createdAtLabel = computed(() => dynamicTime(props.createdAt));

const displayLink = computed(() =>
  isPdf.value
    ? formatDocumentLink(props.externalLink)
    : getDocumentDisplayPath(props.externalLink)
);
const linkIcon = computed(() =>
  isPdf.value ? 'i-ph-file-pdf' : 'i-ph-link-simple'
);

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};

const handleRetry = () => {
  emit('action', { action: 'sync', id: props.id });
};
</script>

<template>
  <CardLayout
    :selectable="selectable"
    class="relative transition-colors"
    :class="{ 'outline-n-brand/50 bg-n-brand/5': isSelected }"
    @mouseenter="emit('hover', true)"
    @mouseleave="emit('hover', false)"
  >
    <div
      v-show="showSelectionControl"
      class="absolute top-7 ltr:left-3 rtl:right-3"
    >
      <RelayCheckbox v-model="modelValue" />
    </div>
    <div class="flex w-full justify-between gap-1">
      <span class="line-clamp-1 text-[15px] font-medium text-n-slate-12">
        {{ name }}
      </span>
      <div v-if="showMenu" class="flex items-center gap-2">
        <div
          v-on-clickaway="() => toggleDropdown(false)"
          class="group relative flex items-center opacity-0 transition-opacity group-hover/cardLayout:opacity-100 focus-within:opacity-100"
        >
          <RelayButton
            variant="ghost"
            size="icon"
            class="size-8 rounded-md text-n-slate-11 hover:bg-n-alpha-2"
            @click="toggleDropdown()"
          >
            <span class="i-lucide-ellipsis-vertical size-4" />
          </RelayButton>
          <DropdownMenu
            v-if="showActionsDropdown"
            :menu-items="menuItems"
            class="top-full mt-1 ltr:right-0 rtl:left-0 xl:ltr:right-0 xl:rtl:left-0"
            @action="handleAction($event)"
          />
        </div>
      </div>
    </div>
    <div class="flex w-full items-center justify-between gap-4">
      <span
        class="flex shrink-0 items-center gap-1 truncate text-sm text-n-slate-11"
      >
        <Icon icon="i-woot-captain" />
        {{ assistant?.name || '' }}
      </span>
      <a
        v-if="!isPdf && hasSafeLink"
        :href="externalLink"
        :title="externalLink"
        target="_blank"
        rel="noopener noreferrer"
        class="flex flex-1 items-center justify-start gap-1 truncate text-sm text-n-slate-11 hover:text-n-slate-12 hover:underline"
        @click.stop
      >
        <Icon :icon="linkIcon" class="shrink-0" />
        <span class="truncate">{{ displayLink }}</span>
        <Icon icon="i-lucide-external-link size-3 shrink-0 opacity-70" />
      </a>
      <span
        v-else
        class="flex flex-1 items-center justify-start gap-1 truncate text-sm text-n-slate-11"
      >
        <Icon :icon="linkIcon" class="shrink-0" />
        <span class="truncate">{{ displayLink }}</span>
      </span>
      <DocumentSyncStatus
        v-if="showSyncStatus"
        :status="syncStatus"
        :last-synced-at="lastSyncedAt"
        :error-code="lastSyncErrorCode"
        :sync-in-progress="syncInProgress"
        :stale-after-hours="syncStaleAfterHours"
        :show-retry="canSync && isRetryableSync"
        @retry="handleRetry"
      />
      <div v-else class="shrink-0 text-sm text-n-slate-11 line-clamp-1">
        {{ createdAtLabel }}
      </div>
    </div>
  </CardLayout>
</template>
