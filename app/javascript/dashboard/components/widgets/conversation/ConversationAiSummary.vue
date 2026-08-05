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
  <div class="px-4 pt-1 pb-2">
    <div
      class="bg-card border border-border/60 rounded-xl p-4 shadow-sm flex flex-col gap-4"
    >
      <div class="flex flex-col gap-1">
        <h3
          class="font-medium text-foreground text-[14px] flex items-center gap-2"
        >
          <span class="i-lucide-sparkles size-4 text-primary shrink-0" />
          <span>{{ t('CONVERSATION.AI_SUMMARY.TITLE') }}</span>
        </h3>
        <span class="text-[11px] text-muted-foreground">
          {{ lastUpdatedLabel }}
        </span>
      </div>

      <ul v-if="summaryBullets.length" class="flex flex-col gap-2.5">
        <li
          v-for="(item, index) in summaryBullets"
          :key="`${index}-${item}`"
          class="flex items-start gap-3 text-[13px] text-foreground/80 leading-snug"
        >
          <span
            class="size-1.5 rounded-full bg-foreground/30 mt-1.5 shrink-0"
          />
          <span>{{ item }}</span>
        </li>
      </ul>
      <p v-else class="text-[13px] text-muted-foreground">
        {{ t('CONVERSATION.AI_SUMMARY.EMPTY') }}
      </p>

      <p v-if="errorMessage" class="text-[12px] text-destructive">
        {{ errorMessage }}
      </p>

      <div
        class="flex flex-col gap-1.5 border border-primary/20 bg-primary/5 rounded-xl overflow-hidden p-0.5"
      >
        <div
          class="flex items-center gap-3 p-2.5 cursor-pointer hover:bg-primary/5 transition-colors rounded-lg"
        >
          <div
            class="size-7 rounded-full bg-primary/10 flex items-center justify-center shrink-0"
          >
            <span class="i-lucide-lightbulb size-4 text-primary" />
          </div>
          <div class="flex flex-col flex-1 min-w-0">
            <span class="text-[13px] font-medium text-primary">
              {{ t('CONVERSATION.AI_SUMMARY.NEXT_BEST_ACTION') }}
            </span>
            <span class="text-[13px] text-foreground truncate mt-0.5">
              {{ nextBestAction }}
            </span>
          </div>
          <span class="i-lucide-chevron-right size-4 text-muted-foreground" />
        </div>

        <div class="px-2 pb-2">
          <RelayButton
            variant="outline"
            class="w-full gap-2 text-[13px] font-medium text-primary border-primary/20 hover:bg-primary/5 hover:text-primary bg-background"
            :disabled="!captainTasksEnabled || isGenerating"
            @click="generateSummary"
          >
            <span
              class="size-3.5"
              :class="
                isGenerating
                  ? 'i-lucide-loader-2 animate-spin'
                  : 'i-lucide-refresh-cw'
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
    </div>
  </div>
</template>
