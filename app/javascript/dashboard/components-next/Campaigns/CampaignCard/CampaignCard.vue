<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { getInboxIconByType } from 'dashboard/helper/inbox';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import { RelayButton, RelayBadge } from 'dashboard/components-next/relay';
import LiveChatCampaignDetails from './LiveChatCampaignDetails.vue';
import SMSCampaignDetails from './SMSCampaignDetails.vue';

const props = defineProps({
  title: {
    type: String,
    default: '',
  },
  message: {
    type: String,
    default: '',
  },
  isLiveChatType: {
    type: Boolean,
    default: false,
  },
  isEnabled: {
    type: Boolean,
    default: false,
  },
  status: {
    type: String,
    default: '',
  },
  sender: {
    type: Object,
    default: null,
  },
  inbox: {
    type: Object,
    default: null,
  },
  scheduledAt: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['edit', 'delete']);

const { t } = useI18n();

const STATUS_COMPLETED = 'completed';
const STATUS_PROCESSING = 'processing';

const { formatMessage } = useMessageFormatter();

const isActive = computed(() =>
  props.isLiveChatType ? props.isEnabled : props.status !== STATUS_COMPLETED
);

const badgeVariant = computed(() => {
  return isActive.value ? 'default' : 'secondary';
});

const campaignStatus = computed(() => {
  if (props.isLiveChatType) {
    return props.isEnabled
      ? t('CAMPAIGN.LIVE_CHAT.CARD.STATUS.ENABLED')
      : t('CAMPAIGN.LIVE_CHAT.CARD.STATUS.DISABLED');
  }

  if (props.status === STATUS_COMPLETED) {
    return t('CAMPAIGN.SMS.CARD.STATUS.COMPLETED');
  }

  if (props.status === STATUS_PROCESSING) {
    return t('CAMPAIGN.SMS.CARD.STATUS.PROCESSING');
  }

  return t('CAMPAIGN.SMS.CARD.STATUS.SCHEDULED');
});

const inboxName = computed(() => props.inbox?.name || '');

const inboxIcon = computed(() => {
  if (!props.inbox) return '';
  const { medium, channel_type: type } = props.inbox;
  return getInboxIconByType(type, medium);
});
</script>

<template>
  <CardLayout layout="row" class="hover:border-border/80 transition-colors">
    <div class="flex flex-col items-start justify-between flex-1 min-w-0 gap-2">
      <div class="flex items-center gap-3 w-fit">
        <span class="text-base font-semibold text-foreground line-clamp-1">
          {{ title }}
        </span>
        <RelayBadge :variant="badgeVariant" class="rounded px-2 font-medium">
          {{ campaignStatus }}
        </RelayBadge>
      </div>
      <div
        v-dompurify-html="formatMessage(message, false, false, false)"
        class="text-[13.5px] text-muted-foreground line-clamp-1 [&>p]:mb-0 h-6"
      />
      <div
        class="flex items-center w-full h-6 gap-2 overflow-hidden text-xs text-muted-foreground"
      >
        <LiveChatCampaignDetails
          v-if="isLiveChatType"
          :sender="sender"
          :inbox-name="inboxName"
          :inbox-icon="inboxIcon"
        />
        <SMSCampaignDetails
          v-else
          :inbox-name="inboxName"
          :inbox-icon="inboxIcon"
          :scheduled-at="scheduledAt"
        />
      </div>
    </div>
    <div class="flex items-center justify-end w-20 gap-2">
      <RelayButton
        v-if="isLiveChatType"
        variant="outline"
        size="sm"
        class="h-8 w-8 p-0"
        :title="t('CAMPAIGN.LIVE_CHAT.EDIT.TITLE')"
        @click="emit('edit')"
      >
        <span class="i-lucide-sliders-horizontal size-4" />
      </RelayButton>
      <RelayButton
        variant="outline"
        size="sm"
        class="h-8 w-8 p-0 text-destructive hover:bg-destructive/10 hover:text-destructive hover:border-destructive/30"
        :title="t('CAMPAIGN.CONFIRM_DELETE.CONFIRM')"
        @click="emit('delete')"
      >
        <span class="i-lucide-trash size-4" />
      </RelayButton>
    </div>
  </CardLayout>
</template>
