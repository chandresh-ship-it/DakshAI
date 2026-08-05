<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useFunctionGetter } from 'dashboard/composables/store';
import { RelayButton } from 'dashboard/components-next/relay';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  contact: {
    type: Object,
    default: () => ({}),
  },
});

const { t } = useI18n();
const { captainTasksEnabled, summarizeConversation } = useCaptain();
const conversationIdRef = computed(() => props.conversationId);
const conversationLabels = useFunctionGetter(
  'conversationLabels/getConversationLabels',
  conversationIdRef
);

const isGenerating = ref(false);
const summaryText = ref('');
const lastUpdatedAt = ref(null);
const errorMessage = ref('');

const labelTakeaways = computed(() => {
  const labels = conversationLabels.value || [];
  return labels.slice(0, 4).map(title => title);
});

const contactAttributeTakeaways = computed(() => {
  const attrs = props.contact?.custom_attributes || {};
  return Object.entries(attrs)
    .filter(([, value]) => value != null && String(value).trim() !== '')
    .slice(0, 4)
    .map(([key, value]) => `${key}: ${value}`);
});

const summaryBullets = computed(() => {
  if (summaryText.value) {
    return summaryText.value
      .split(/\n+/)
      .map(line => line.replace(/^[-•*]\s*/, '').trim())
      .filter(Boolean)
      .slice(0, 6);
  }
  if (labelTakeaways.value.length) return labelTakeaways.value;
  if (contactAttributeTakeaways.value.length) {
    return contactAttributeTakeaways.value;
  }
  return [];
});

const nextBestAction = computed(() => {
  const labels = labelTakeaways.value.map(l => l.toLowerCase());
  if (labels.some(l => l.includes('demo') || l.includes('call'))) {
    return t('CONVERSATION.AI_SUMMARY.ACTIONS.SCHEDULE_DEMO');
  }
  if (labels.some(l => l.includes('follow'))) {
    return t('CONVERSATION.AI_SUMMARY.ACTIONS.FOLLOW_UP');
  }
  if (summaryBullets.value.length) {
    return t('CONVERSATION.AI_SUMMARY.ACTIONS.REVIEW_SUMMARY');
  }
  return t('CONVERSATION.AI_SUMMARY.ACTIONS.GENERATE_FIRST');
});

const lastUpdatedLabel = computed(() => {
  if (!lastUpdatedAt.value) {
    return t('CONVERSATION.AI_SUMMARY.NOT_GENERATED');
  }
  return t('CONVERSATION.AI_SUMMARY.LAST_UPDATED', {
    time: lastUpdatedAt.value.toLocaleString(),
  });
});

const generateSummary = async () => {
  if (!captainTasksEnabled.value || isGenerating.value) return;
  isGenerating.value = true;
  errorMessage.value = '';
  try {
    const result = await summarizeConversation();
    if (result?.message) {
      summaryText.value = result.message;
      lastUpdatedAt.value = new Date();
    } else if (result?.errorType) {
      errorMessage.value = t('CONVERSATION.AI_SUMMARY.ERROR');
    }
  } catch {
    errorMessage.value = t('CONVERSATION.AI_SUMMARY.ERROR');
  } finally {
    isGenerating.value = false;
  }
};

watch(
  () => props.conversationId,
  () => {
    summaryText.value = '';
    lastUpdatedAt.value = null;
    errorMessage.value = '';
  }
);
</script>

<template>
  <div class="px-6 py-2">
    <div
      class="bg-card border border-border rounded-xl p-5 shadow-sm flex flex-col gap-4"
    >
      <div
        class="inline-flex items-center gap-1.5 px-2.5 py-1 bg-primary/10 text-primary rounded-full w-fit"
      >
        <span class="i-lucide-sparkles size-3.5" />
        <span class="text-xs font-semibold uppercase tracking-wider">{{
          t('CONVERSATION.AI_SUMMARY.TITLE')
        }}</span>
      </div>

      <p v-if="summaryText" class="text-sm text-foreground/90 leading-relaxed">
        {{ summaryText }}
      </p>
      <p v-else class="text-[13px] text-muted-foreground">
        {{ t('CONVERSATION.AI_SUMMARY.EMPTY') }}
      </p>

      <p v-if="errorMessage" class="text-[12px] text-destructive">
        {{ errorMessage }}
      </p>

      <RelayButton
        class="w-full gap-2 rounded-full mt-2"
        :disabled="!captainTasksEnabled || isGenerating"
        @click="generateSummary"
      >
        <span
          class="size-4"
          :class="
            isGenerating
              ? 'i-lucide-loader-2 animate-spin'
              : 'i-lucide-sparkles'
          "
        />
        {{
          isGenerating
            ? t('CONVERSATION.AI_SUMMARY.GENERATING')
            : t('CONVERSATION.AI_SUMMARY.GENERATE')
        }}
      </RelayButton>
    </div>
  </div>
</template>
