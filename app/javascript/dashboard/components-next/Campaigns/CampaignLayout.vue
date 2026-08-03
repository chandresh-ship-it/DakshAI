<script setup>
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { RelayButton } from 'dashboard/components-next/relay';

defineProps({
  headerTitle: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['click', 'close']);
const { t } = useI18n();

const handleButtonClick = () => {
  emit('click');
};

const metrics = [
  {
    title: 'Total Campaigns',
    value: '24',
    trend: '+14.3%',
    trendUp: true,
    icon: 'i-lucide-send',
    color: 'text-primary',
    bg: 'bg-primary/10',
    sparkline: [20, 25, 22, 28, 25, 30, 35],
  },
  {
    title: 'Sent',
    value: '128,645',
    trend: '+18.7%',
    trendUp: true,
    icon: 'i-lucide-mail',
    color: 'text-emerald-600',
    bg: 'bg-emerald-500/10',
    sparkline: [100, 110, 105, 120, 115, 125, 128],
  },
  {
    title: 'Opened',
    value: '42,581',
    trend: '+21.1%',
    trendUp: true,
    icon: 'i-lucide-mail-open',
    color: 'text-sky-600',
    bg: 'bg-sky-500/10',
    sparkline: [30, 35, 33, 38, 36, 40, 42],
  },
  {
    title: 'Clicked',
    value: '8,926',
    trend: '+16.4%',
    trendUp: true,
    icon: 'i-lucide-mouse-pointer-click',
    color: 'text-amber-600',
    bg: 'bg-amber-500/10',
    sparkline: [5, 6, 7, 6, 8, 7, 8],
  },
  {
    title: 'Conversion Rate',
    value: '6.91%',
    trend: '+8.2%',
    trendUp: true,
    icon: 'i-lucide-trending-up',
    color: 'text-indigo-600',
    bg: 'bg-indigo-500/10',
    sparkline: [5.5, 6.0, 5.8, 6.2, 6.5, 6.8, 6.9],
  },
];

const generateSparklinePath = data => {
  if (!data || data.length === 0) return '';
  const max = Math.max(...data);
  const min = Math.min(...data);
  const range = max - min || 1;
  const points = data.map((val, i) => {
    const x = (i / (data.length - 1)) * 100;
    const y = 100 - ((val - min) / range) * 100;
    return `${x},${y}`;
  });
  return `M ${points.join(' L ')}`;
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-background">
    <header
      class="sticky top-0 z-10 px-6 lg:px-10 border-b border-border bg-background/80 backdrop-blur-md"
    >
      <div class="w-full max-w-7xl mx-auto">
        <div class="flex items-center justify-between w-full h-16 gap-2">
          <span class="text-base font-semibold text-foreground">
            {{ headerTitle }}
          </span>
          <div
            v-on-click-outside="[
              () => emit('close'),
              // This will prevent closing the modal when the editor Create link popup is open
              { ignore: ['dialog.ProseMirror-prompt-backdrop'] },
            ]"
            class="relative group/campaign-button"
          >
            <RelayButton
              variant="default"
              size="sm"
              class="group-hover/campaign-button:brightness-110 h-8 gap-2 font-medium"
              @click="handleButtonClick"
            >
              <span class="i-lucide-plus size-4" />
              {{ buttonLabel }}
            </RelayButton>
            <slot name="action" />
          </div>
        </div>
      </div>
    </header>

    <main class="flex-1 px-6 lg:px-10 overflow-y-auto bg-background/50">
      <div class="w-full max-w-7xl mx-auto py-8">
        <!-- Metrics Grid -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4 mb-8">
          <div
            v-for="metric in metrics"
            :key="metric.title"
            class="bg-card border border-border/60 rounded-xl p-5 shadow-xs relative overflow-hidden flex flex-col justify-between"
          >
            <div class="flex items-start justify-between mb-4">
              <div
                class="size-10 rounded-xl flex items-center justify-center shrink-0 border border-border/40"
                :class="[metric.bg, metric.color]"
              >
                <span class="size-5" :class="[metric.icon]" />
              </div>
              <div class="flex-1 ml-4 overflow-hidden">
                <p
                  class="text-[13px] font-medium text-muted-foreground truncate"
                >
                  {{ metric.title }}
                </p>
                <h3 class="text-2xl font-bold text-foreground mt-1">
                  {{ metric.value }}
                </h3>
              </div>
            </div>

            <div class="flex items-end justify-between">
              <div class="flex items-center text-[12px] font-medium">
                <span
                  class="flex items-center"
                  :class="
                    metric.trendUp ? 'text-emerald-500' : 'text-destructive'
                  "
                >
                  <span
                    :class="
                      metric.trendUp
                        ? 'i-lucide-arrow-up-right'
                        : 'i-lucide-arrow-down-right'
                    "
                    class="size-3 mr-0.5"
                  />
                  {{ metric.trend }}
                </span>
                <span class="text-muted-foreground ml-1 font-normal">
                  {{ t('CAMPAIGN.HEADER.VS_LAST_7D') }}
                </span>
              </div>

              <div
                class="w-16 h-8 -mr-1 -mb-1 opacity-80"
                :class="metric.color"
              >
                <svg
                  viewBox="0 -10 100 120"
                  class="w-full h-full overflow-visible"
                  preserveAspectRatio="none"
                >
                  <path
                    :d="generateSparklinePath(metric.sparkline)"
                    fill="none"
                    stroke="currentColor"
                    stroke-width="3"
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    class="vector-effect-non-scaling-stroke drop-shadow-sm"
                  />
                </svg>
              </div>
            </div>
          </div>
        </div>

        <slot name="default" />
      </div>
    </main>
  </section>
</template>
