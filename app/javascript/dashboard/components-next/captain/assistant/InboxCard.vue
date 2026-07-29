<script setup>
import { computed } from 'vue';
import { useToggle } from '@vueuse/core';
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import Policy from 'dashboard/components/policy.vue';
import { INBOX_TYPES, getInboxIconByType } from 'dashboard/helper/inbox';

const props = defineProps({
  id: {
    type: Number,
    required: true,
  },
  inbox: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['action']);

const { t } = useI18n();

const [showActionsDropdown, toggleDropdown] = useToggle();

const inboxName = computed(() => {
  const inbox = props.inbox;
  if (!inbox?.name) {
    return '';
  }

  const isTwilioChannel = inbox.channel_type === INBOX_TYPES.TWILIO;
  const isWhatsAppChannel = inbox.channel_type === INBOX_TYPES.WHATSAPP;
  const isEmailChannel = inbox.channel_type === INBOX_TYPES.EMAIL;

  if (isTwilioChannel || isWhatsAppChannel) {
    const identifier = inbox.messaging_service_sid || inbox.phone_number;
    return identifier ? `${inbox.name} (${identifier})` : inbox.name;
  }

  if (isEmailChannel && inbox.email) {
    return `${inbox.name} (${inbox.email})`;
  }

  return inbox.name;
});

const menuItems = computed(() => [
  {
    label: t('CAPTAIN.INBOXES.OPTIONS.DISCONNECT'),
    value: 'delete',
    action: 'delete',
    icon: 'i-lucide-trash',
  },
]);

const icon = computed(() => {
  const { medium, channel_type: type } = props.inbox;
  return getInboxIconByType(type, medium, 'outline');
});

const handleAction = ({ action, value }) => {
  toggleDropdown(false);
  emit('action', { action, value, id: props.id });
};
</script>

<template>
  <CardLayout>
    <div class="flex w-full justify-between gap-1">
      <span
        class="flex items-center gap-2 text-[15px] font-medium text-n-slate-12 line-clamp-1"
      >
        <span :class="icon" />
        {{ inboxName }}
      </span>
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
            class="top-full mt-1 ltr:right-0 rtl:left-0"
            @action="handleAction($event)"
          />
        </Policy>
      </div>
    </div>
  </CardLayout>
</template>
