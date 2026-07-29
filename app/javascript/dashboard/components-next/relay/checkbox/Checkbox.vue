<script setup>
import { computed } from 'vue';
import { cn } from '../utils/cn';

const props = defineProps({
  disabled: { type: Boolean, default: false },
  indeterminate: { type: Boolean, default: false },
});

const modelValue = defineModel({
  type: [Boolean, String],
  default: false,
});

const isIndeterminate = computed(
  () => props.indeterminate || modelValue.value === 'indeterminate'
);
const isChecked = computed(
  () => modelValue.value === true || isIndeterminate.value
);

const toggle = () => {
  if (isIndeterminate.value) {
    modelValue.value = true;
    return;
  }
  modelValue.value = !modelValue.value;
};
</script>

<template>
  <button
    type="button"
    role="checkbox"
    :aria-checked="isIndeterminate ? 'mixed' : isChecked"
    :disabled="disabled"
    :class="
      cn(
        'peer size-4 shrink-0 rounded-sm border border-n-weak shadow-sm transition-colors',
        'focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-n-brand',
        'disabled:cursor-not-allowed disabled:opacity-50',
        isChecked
          ? 'border-n-brand bg-n-brand text-white'
          : 'bg-n-background text-transparent'
      )
    "
    @click="toggle"
  >
    <span
      v-if="isIndeterminate"
      class="i-lucide-minus flex size-full items-center justify-center text-[10px]"
    />
    <span
      v-else-if="isChecked"
      class="i-lucide-check flex size-full items-center justify-center text-[10px]"
    />
  </button>
</template>
