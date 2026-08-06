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
      class="bg-card border border-border/40 rounded-[16px] p-5 shadow-xs flex flex-col gap-4"
    >
      <!-- Header -->
      <div class="flex flex-col gap-1">
        <div class="flex items-center gap-2 text-primary">
          <span class="i-lucide-bot size-5" />
          <h3 class="text-base font-semibold text-foreground tracking-tight">
            {{ t('CONVERSATION.AI_SUMMARY.TITLE') }}
          </h3>
        </div>
        <p class="text-[13px] text-muted-foreground">
          {{ lastUpdatedLabel }}
        </p>
      </div>

      <!-- Bullets / Content -->
      <div v-if="summaryBullets.length" class="pl-4">
        <ul class="list-disc text-[13.5px] text-muted-foreground space-y-2">
          <li
            v-for="(bullet, index) in summaryBullets"
            :key="index"
            class="pl-1"
          >
            <span class="text-foreground/90">{{ bullet }}</span>
          </li>
        </ul>
      </div>
      <div
        v-else-if="summaryText"
        class="text-[13.5px] text-foreground/90 leading-relaxed"
      >
        {{ summaryText }}
      </div>
      <p v-else class="text-[13px] text-muted-foreground">
        {{ t('CONVERSATION.AI_SUMMARY.EMPTY') }}
      </p>

      <p v-if="errorMessage" class="text-[12px] text-destructive">
        {{ errorMessage }}
      </p>

      <!-- Next Best Action Card -->
      <div
        v-if="summaryBullets.length || summaryText"
        class="flex flex-col gap-3 mt-1 bg-black/20 dark:bg-black/40 border border-border/20 rounded-xl p-4"
      >
        <div class="flex items-center gap-2.5">
          <div
            class="flex items-center justify-center size-6 rounded-full bg-primary/15 text-primary"
          >
            <span class="i-lucide-lightbulb size-3.5" />
          </div>
          <span
            class="text-[13px] font-semibold text-primary uppercase tracking-wide"
          >
            {{ t('CONVERSATION.AI_SUMMARY.ACTIONS.TITLE', 'Next Best Action') }}
          </span>
        </div>
        <div
          class="flex items-center justify-between gap-4 cursor-pointer hover:opacity-80 transition-opacity"
        >
          <span class="text-sm font-medium text-foreground">
            {{ nextBestAction }}
          </span>
          <span
            class="i-lucide-chevron-right size-4 text-muted-foreground shrink-0"
          />
        </div>
      </div>

      <!-- Generate Button -->
      <button
        type="button"
        class="flex items-center justify-center gap-2 w-full h-10 mt-1 rounded-full border border-primary/30 bg-primary/10 hover:bg-primary/20 text-primary transition-colors text-sm font-semibold"
        :disabled="!captainTasksEnabled || isGenerating"
        @click="generateSummary"
      >
        <span
          class="size-4"
          :class="
            isGenerating
              ? 'i-lucide-loader-2 animate-spin'
              : 'i-lucide-refresh-cw'
          "
        />
        {{
          isGenerating
            ? t('CONVERSATION.AI_SUMMARY.GENERATING')
            : t('CONVERSATION.AI_SUMMARY.GENERATE', 'Generate New Summary')
        }}
      </button>
    </div>
  </div>
</template>
