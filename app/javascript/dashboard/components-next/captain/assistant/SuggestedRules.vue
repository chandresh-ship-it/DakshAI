<script setup>
import { useI18n } from 'vue-i18n';
import { RelayButton } from 'dashboard/components-next/relay';

defineProps({
  title: {
    type: String,
    default: '',
  },
  items: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['add', 'close']);

const { t } = useI18n();

const onAddClick = () => {
  emit('add');
};

const onClickClose = () => {
  emit('close');
};
</script>

<template>
  <div
    class="flex w-full flex-col items-start overflow-hidden rounded-xl border border-dashed border-n-strong"
  >
    <div class="flex w-full items-center justify-between gap-3 px-4 pb-1 pt-4">
      <div class="flex items-center gap-3">
        <h5 class="text-sm font-medium text-n-slate-11">{{ title }}</h5>
        <span class="h-3 w-px bg-n-weak" />
        <RelayButton
          variant="link"
          size="sm"
          class="flex-shrink-0 !text-sm text-n-slate-11"
          @click="onAddClick"
        >
          {{ t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.SUGGESTED.ADD') }}
        </RelayButton>
      </div>
      <RelayButton
        variant="ghost"
        size="icon"
        class="size-6 flex-shrink-0 text-n-slate-11"
        @click="onClickClose"
      >
        <span class="i-lucide-x size-3.5" />
      </RelayButton>
    </div>
    <div
      class="flex w-full flex-col items-start divide-y divide-dashed divide-n-strong"
    >
      <div v-for="item in items" :key="item.content" class="w-full px-4 py-4">
        <slot :item="item" />
      </div>
    </div>
  </div>
</template>
