<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import Avatar from 'next/avatar/Avatar.vue';
import { useInbox } from 'dashboard/composables/useInbox';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
});

const store = useStore();
const { isAWebWidgetInbox } = useInbox();

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
  <div
    ref="conversationHeader"
    class="px-6 py-6 bg-transparent flex flex-col shrink-0 w-full min-w-0"
  >
    <!-- Title Row -->
    <div class="flex items-center gap-3 mb-4 min-w-0">
      <h1 class="text-xl font-bold text-foreground truncate">
        {{ subject }}
      </h1>
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

    <!-- Sender Subheader Row -->
    <div class="flex items-center gap-3 min-w-0">
      <Avatar
        :name="currentContact.name"
        :src="currentContact.thumbnail"
        :size="24"
        :status="currentContact.availability_status"
        hide-offline-status
        rounded-full
      />
      <div class="flex items-center gap-2 min-w-0 text-sm">
        <span class="font-bold text-foreground truncate">
          {{ currentContact.name }}
        </span>
        <span class="text-muted-foreground">&bull;</span>
        <span class="text-muted-foreground truncate">{{ $t('CONVERSATION.HEADER.CONTACT') }}</span>
        <span class="text-muted-foreground">&bull;</span>
        <span class="text-muted-foreground flex items-center gap-1">
          <span class="i-lucide-clock size-3" />
          {{ customerSince }}
        </span>
      </div>
    </div>
  </div>
</template>
