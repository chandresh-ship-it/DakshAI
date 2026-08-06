<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import Avatar from 'next/avatar/Avatar.vue';
import { useInbox } from 'dashboard/composables/useInbox';
import { useUISettings } from 'dashboard/composables/useUISettings';
import MoreActions from './MoreActions.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
});

const store = useStore();
const { isAWebWidgetInbox } = useInbox();
const { uiSettings, updateUISettings } = useUISettings();

const toggleSidebar = () => {
  updateUISettings({
    is_contact_sidebar_open: !uiSettings.value.is_contact_sidebar_open,
  });
};

const chatMetadata = computed(() => props.chat.meta);

const isHMACVerified = computed(() => {
  if (!isAWebWidgetInbox.value) {
    return true;
  }
  return chatMetadata.value.hmac_verified;
});

const currentContact = computed(() =>
  store.getters['contacts/getContact'](props.chat.meta.sender.id)
);

const customerSince = computed(() => {
  const createdAt = currentContact.value?.created_at;
  if (!createdAt) return '';
  const date = new Date(createdAt * 1000);
  return date.toLocaleDateString(undefined, {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
});

const subject = computed(() => {
  const attrs = props.chat.additional_attributes || {};
  return attrs.mailSubject || `Conversation #${props.chat.id}`;
});
</script>

<template>
  <div class="h-16 px-6 border-b border-border bg-card flex items-center justify-between shrink-0">
    <div class="flex items-center gap-3 min-w-0">
      <Avatar
        :name="currentContact.name"
        :src="currentContact.thumbnail"
        :size="40"
        :status="currentContact.availability_status"
        hide-offline-status
        rounded-full
        class="border border-border/50 shrink-0"
      />
      <div class="flex flex-col min-w-0">
        <div class="flex items-center gap-2">
          <span class="font-semibold text-foreground hover:text-primary transition-colors cursor-pointer text-base truncate">
            {{ currentContact.name }}
          </span>
          <span
            v-if="isHMACVerified"
            class="inline-flex items-center gap-1 text-[11px] font-medium px-2 py-0.5 rounded-full bg-primary/10 text-primary border border-primary/20 shrink-0"
          >
            <span class="i-lucide-check-circle size-3" />
            {{ $t('VERIFIED') }}
          </span>
          <fluent-icon
            v-else
            v-tooltip="$t('CONVERSATION.UNVERIFIED_SESSION')"
            size="14"
            class="text-amber-500 shrink-0"
            icon="warning"
          />
        </div>
        <div class="flex items-center gap-2 text-[13px] text-muted-foreground mt-0.5">
          <span class="truncate">{{ subject }}</span>
          <span v-if="subject" class="text-muted-foreground">&bull;</span>
          <span class="truncate">Customer Since {{ customerSince }}</span>
        </div>
      </div>
    </div>
    
    <div class="flex items-center gap-1 shrink-0">
      <MoreActions />
      <RelayButton
        variant="ghost"
        size="icon"
        class="text-muted-foreground shrink-0 focus-visible:ring-0"
        @click="toggleSidebar"
      >
        <span class="i-lucide-panel-right size-4" />
      </RelayButton>
    </div>
  </div>
</template>
