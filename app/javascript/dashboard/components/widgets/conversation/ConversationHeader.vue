<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { useElementSize } from '@vueuse/core';
import { useI18n } from 'vue-i18n';
import BackButton from '../BackButton.vue';
import MoreActions from './MoreActions.vue';
import Avatar from 'next/avatar/Avatar.vue';
import SLACardLabel from './components/SLACardLabel.vue';
import ConversationCallButton from './ConversationCallButton.vue';
import wootConstants from 'dashboard/constants/globals';
import { conversationListPageURL } from 'dashboard/helper/URLHelper';
import { snoozedReopenTime } from 'dashboard/helper/snoozeHelpers';
import { useInbox } from 'dashboard/composables/useInbox';
import { useAlert } from 'dashboard/composables';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useMapGetter } from 'dashboard/composables/store';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
  showBackButton: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const conversationHeader = ref(null);
const { width } = useElementSize(conversationHeader);
const { isAWebWidgetInbox } = useInbox();
const { uiSettings, updateUISettings } = useUISettings();
const accountLabels = useMapGetter('labels/getLabels');

const currentChat = computed(() => store.getters.getSelectedChat);
const accountId = computed(() => store.getters.getCurrentAccountId);

const chatMetadata = computed(() => props.chat.meta);

const backButtonUrl = computed(() => {
  const {
    params: { inbox_id: inboxId, label, teamId, id: customViewId },
    name,
  } = route;

  const conversationTypeMap = {
    conversation_through_mentions: 'mention',
    conversation_through_participating: 'participating',
    conversation_through_unattended: 'unattended',
  };
  return conversationListPageURL({
    accountId: accountId.value,
    inboxId,
    label,
    teamId,
    conversationType: conversationTypeMap[name],
    customViewId,
  });
});

const isHMACVerified = computed(() => {
  if (!isAWebWidgetInbox.value) {
    return true;
  }
  return chatMetadata.value.hmac_verified;
});

const currentContact = computed(() =>
  store.getters['contacts/getContact'](props.chat.meta.sender.id)
);

const isSnoozed = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.SNOOZED
);

const snoozedDisplayText = computed(() => {
  const { snoozed_until: snoozedUntil } = currentChat.value;
  if (snoozedUntil) {
    return `${t('CONVERSATION.HEADER.SNOOZED_UNTIL')} ${snoozedReopenTime(snoozedUntil)}`;
  }
  return t('CONVERSATION.HEADER.SNOOZED_UNTIL_NEXT_REPLY');
});

const inbox = computed(() => {
  const { inbox_id: inboxId } = props.chat;
  return store.getters['inboxes/getInbox'](inboxId);
});

const hasSlaPolicyId = computed(() => props.chat?.sla_policy_id);

const primaryLabel = computed(() => {
  const titles = props.chat.labels || [];
  if (!titles.length) return null;
  return (
    accountLabels.value.find(label => label.title === titles[0]) || {
      title: titles[0],
    }
  );
});

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

const metaLine = computed(() => {
  const parts = [];
  if (inbox.value?.name) parts.push(inbox.value.name);
  if (customerSince.value) {
    parts.push(
      t('CONVERSATION.HEADER.CUSTOMER_SINCE', { date: customerSince.value })
    );
  }
  if (isSnoozed.value) parts.push(snoozedDisplayText.value);
  return parts.join(' • ');
});

const isContactSidebarOpen = computed(
  () => uiSettings.value.is_contact_sidebar_open
);

const copyConversationId = async () => {
  try {
    await copyTextToClipboard(String(props.chat.id));
    useAlert(t('CONVERSATION.HEADER.COPY_ID_SUCCESS'));
  } catch (error) {
    // error
  }
};

const toggleContactSidebar = () => {
  updateUISettings({
    is_contact_sidebar_open: !isContactSidebarOpen.value,
    is_copilot_panel_open: false,
  });
};
</script>

<template>
  <div
    ref="conversationHeader"
    class="h-16 px-6 border-b border-border bg-card flex items-center justify-between shrink-0 w-full min-w-0"
  >
    <div class="flex items-center gap-3 min-w-0">
      <BackButton
        v-if="showBackButton"
        :back-url="backButtonUrl"
        class="shrink-0"
      />
      <Avatar
        :name="currentContact.name"
        :src="currentContact.thumbnail"
        :size="40"
        :status="currentContact.availability_status"
        hide-offline-status
        rounded-full
      />
      <div class="flex flex-col min-w-0">
        <div class="flex items-center gap-2 min-w-0">
          <h2 class="font-semibold text-foreground truncate">
            {{ currentContact.name }}
          </h2>
          <span
            v-if="primaryLabel"
            class="text-[10px] font-medium px-1.5 py-0 rounded-sm shrink-0 bg-primary text-primary-foreground border border-transparent"
          >
            {{ primaryLabel.title }}
          </span>
          <fluent-icon
            v-if="!isHMACVerified"
            v-tooltip="$t('CONVERSATION.UNVERIFIED_SESSION')"
            size="14"
            class="text-amber-500 shrink-0"
            icon="warning"
          />
          <button
            type="button"
            class="text-[11px] font-medium text-muted-foreground hover:text-foreground shrink-0"
            @click="copyConversationId"
          >
            {{ `#${chat.id}` }}
          </button>
        </div>
        <div
          v-if="metaLine"
          class="flex items-center gap-2 text-xs text-muted-foreground mt-0.5 truncate"
        >
          {{ metaLine }}
        </div>
      </div>
    </div>
    <div class="flex items-center gap-1 shrink-0">
      <SLACardLabel
        v-if="hasSlaPolicyId"
        :chat="chat"
        show-extended-info
        :parent-width="width"
        class="hidden md:flex mr-2"
      />
      <ConversationCallButton :inbox="inbox" :chat="currentChat" />
      <MoreActions :conversation-id="currentChat.id" />
      <RelayButton
        variant="ghost"
        size="icon"
        class="h-8 w-8 text-muted-foreground"
        :class="{ 'bg-accent text-accent-foreground': isContactSidebarOpen }"
        :aria-label="$t('CONVERSATION.SIDEBAR.CONTACT')"
        @click="toggleContactSidebar"
      >
        <span class="i-lucide-panel-right size-4" />
      </RelayButton>
    </div>
  </div>
</template>
