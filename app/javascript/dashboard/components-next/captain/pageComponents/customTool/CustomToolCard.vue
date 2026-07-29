<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayBadge, RelayButton } from 'dashboard/components-next/relay';
import Policy from 'dashboard/components/policy.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  endpointUrl: {
    type: String,
    default: '',
  },
  httpMethod: {
    type: String,
    default: 'GET',
  },
  authType: {
    type: String,
    default: 'none',
  },
  updatedAt: {
    type: Number,
    required: true,
  },
  createdAt: {
    type: Number,
    required: true,
  },
});

const emit = defineEmits(['action']);

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const menuItems = computed(() => [
  {
    label: t('CAPTAIN.CUSTOM_TOOLS.OPTIONS.EDIT_TOOL'),
    value: 'edit',
    action: 'edit',
    icon: 'i-lucide-pencil-line',
  },
  {
    label: t('CAPTAIN.CUSTOM_TOOLS.OPTIONS.DELETE_TOOL'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash',
  },
]);

const timestamp = computed(() =>
  dynamicTime(props.updatedAt || props.createdAt)
);

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};

const authTypeLabel = computed(() => {
  return t(
    `CAPTAIN.CUSTOM_TOOLS.FORM.AUTH_TYPES.${props.authType.toUpperCase()}`
  );
});
</script>

<template>
  <CardLayout class="relative">
    <div class="relative flex w-full justify-between gap-1">
      <div class="flex min-w-0 items-center gap-2.5">
        <RelayBadge
          variant="secondary"
          class="shrink-0 border-n-brand/20 bg-n-brand/10 font-semibold uppercase text-n-brand"
        >
          {{ httpMethod }}
        </RelayBadge>
        <span class="line-clamp-1 text-[15px] font-medium text-n-slate-12">
          {{ title }}
        </span>
      </div>
      <div class="flex items-center gap-2">
        <Policy
          v-on-clickaway="() => toggleDropdown(false)"
          :permissions="['administrator']"
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
            class="top-full mt-1 ltr:right-0 rtl:right-0"
            @action="handleAction($event)"
          />
        </Policy>
      </div>
    </div>
    <div class="flex w-full min-w-0 items-center justify-between gap-4">
      <div class="flex min-w-0 flex-1 flex-col gap-1">
        <span v-if="description" class="truncate text-sm text-n-slate-11">
          {{ description }}
        </span>
        <code
          v-if="endpointUrl"
          class="inline-block truncate rounded-md bg-n-alpha-2 px-2 py-0.5 font-mono text-xs text-n-slate-11"
        >
          {{ endpointUrl }}
        </code>
      </div>
      <div class="flex shrink-0 items-center gap-3">
        <span
          v-if="authType !== 'none'"
          class="inline-flex items-center gap-1 text-sm text-n-slate-11"
        >
          <i class="i-lucide-lock text-base" />
          {{ authTypeLabel }}
        </span>
        <span class="line-clamp-1 text-sm text-n-slate-11">
          {{ timestamp }}
        </span>
      </div>
    </div>
  </CardLayout>
</template>
