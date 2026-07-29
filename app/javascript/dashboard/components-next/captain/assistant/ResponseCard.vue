<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayButton, RelayCheckbox } from 'dashboard/components-next/relay';
import Policy from 'dashboard/components/policy.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  question: {
    type: String,
    required: true,
  },
  answer: {
    type: String,
    required: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    default: 'approved',
  },
  documentable: {
    type: Object,
    default: null,
  },
  assistant: {
    type: Object,
    default: () => ({}),
  },
  updatedAt: {
    type: Number,
    required: true,
  },
  createdAt: {
    type: Number,
    required: true,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
  selectable: {
    type: Boolean,
    default: false,
  },
  showMenu: {
    type: Boolean,
    default: true,
  },
  showActions: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['action', 'navigate', 'select', 'hover']);

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const modelValue = computed({
  get: () => props.isSelected,
  set: () => emit('select', props.id),
});

const statusAction = computed(() => {
  if (props.status === 'pending') {
    return [
      {
        label: t('CAPTAIN.RESPONSES.OPTIONS.APPROVE'),
        value: 'approve',
        action: 'approve',
        icon: 'i-lucide-circle-check-big',
      },
    ];
  }
  return [];
});

const menuItems = computed(() => [
  ...statusAction.value,
  {
    label: t('CAPTAIN.RESPONSES.OPTIONS.EDIT_RESPONSE'),
    value: 'edit',
    action: 'edit',
    icon: 'i-lucide-pencil-line',
  },
  {
    label: t('CAPTAIN.RESPONSES.OPTIONS.DELETE_RESPONSE'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash',
  },
]);

const timestamp = computed(() =>
  dynamicTime(props.updatedAt || props.createdAt)
);

const handleAssistantAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};

const handleDocumentableClick = () => {
  emit('navigate', {
    id: props.documentable.id,
    type: props.documentable.type,
  });
};
</script>

<template>
  <CardLayout
    selectable
    class="relative transition-colors"
    :class="{
      'rounded-md': compact,
      'outline-n-brand/50 bg-n-brand/5': isSelected,
    }"
    @mouseenter="emit('hover', true)"
    @mouseleave="emit('hover', false)"
  >
    <div v-show="selectable" class="absolute top-7 ltr:left-3 rtl:right-3">
      <RelayCheckbox v-model="modelValue" />
    </div>
    <div class="relative flex w-full justify-between gap-1">
      <span class="line-clamp-1 text-[15px] font-medium text-n-slate-12">
        {{ question }}
      </span>
      <div v-if="!compact && showMenu" class="flex items-center gap-2">
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
            class="mt-1 ltr:right-0 rtl:right-0 top-full"
            @action="handleAssistantAction($event)"
          />
        </Policy>
      </div>
    </div>
    <span class="line-clamp-5 text-sm text-n-slate-11">
      {{ answer }}
    </span>
    <div
      v-if="!compact"
      class="flex flex-col-reverse items-start justify-between gap-3 md:flex-row"
    >
      <Policy v-if="showActions" :permissions="['administrator']">
        <div class="flex w-full items-center gap-2 sm:gap-5">
          <RelayButton
            v-if="status === 'pending'"
            variant="link"
            size="sm"
            class="hover:!no-underline"
            @click="
              handleAssistantAction({ action: 'approve', value: 'approve' })
            "
          >
            <span class="i-lucide-circle-check-big size-4" />
            {{ $t('CAPTAIN.RESPONSES.OPTIONS.APPROVE') }}
          </RelayButton>
          <RelayButton
            variant="link"
            size="sm"
            class="text-n-slate-11 hover:!no-underline"
            @click="
              handleAssistantAction({
                action: 'edit',
                value: 'edit',
              })
            "
          >
            <span class="i-lucide-pencil-line size-4" />
            {{ $t('CAPTAIN.RESPONSES.OPTIONS.EDIT_RESPONSE') }}
          </RelayButton>
          <RelayButton
            variant="link"
            size="sm"
            class="text-n-ruby-11 hover:!no-underline"
            @click="
              handleAssistantAction({ action: 'delete', value: 'delete' })
            "
          >
            <span class="i-lucide-trash size-4" />
            {{ $t('CAPTAIN.RESPONSES.OPTIONS.DELETE_RESPONSE') }}
          </RelayButton>
        </div>
      </Policy>
      <div
        class="flex items-center gap-3"
        :class="{ 'w-full justify-between': !showActions }"
      >
        <div class="inline-flex min-w-0 items-center gap-3">
          <span
            v-if="status === 'approved'"
            class="inline-flex shrink-0 items-center gap-1 truncate text-sm text-n-slate-11"
          >
            <Icon icon="i-woot-captain" class="size-3.5" />
            {{ assistant?.name || '' }}
          </span>
          <div
            v-if="documentable"
            class="grid min-w-0 grid-cols-[auto_1fr] items-center gap-1 text-sm text-n-slate-11"
          >
            <Icon
              v-if="documentable.type === 'Captain::Document'"
              icon="i-ph-files-light"
              class="size-3.5"
            />
            <Icon
              v-else-if="documentable.type === 'User'"
              icon="i-ph-user-circle-plus"
              class="size-3.5"
            />
            <Icon
              v-else-if="documentable.type === 'Conversation'"
              icon="i-ph-chat-circle-dots"
              class="size-3.5"
            />
            <span
              v-if="documentable.type === 'Captain::Document'"
              class="truncate"
              :title="documentable.name"
            >
              {{ documentable.name }}
            </span>
            <span
              v-else-if="documentable.type === 'User'"
              class="truncate"
              :title="documentable.available_name"
            >
              {{ documentable.available_name }}
            </span>
            <span
              v-else-if="documentable.type === 'Conversation'"
              class="cursor-pointer truncate hover:underline"
              role="button"
              @click="handleDocumentableClick"
            >
              {{
                t(`CAPTAIN.RESPONSES.DOCUMENTABLE.CONVERSATION`, {
                  id: documentable.display_id,
                })
              }}
            </span>
          </div>
        </div>
        <div
          class="inline-flex shrink-0 items-center gap-1 text-sm text-n-slate-11 line-clamp-1"
        >
          <Icon icon="i-ph-calendar-dot" class="size-3.5" />
          {{ timestamp }}
        </div>
      </div>
    </div>
  </CardLayout>
</template>
