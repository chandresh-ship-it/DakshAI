<script setup>
import { cn } from '../utils/cn';

const props = defineProps({
  type: { type: String, default: 'text' },
  placeholder: { type: String, default: '' },
  disabled: { type: Boolean, default: false },
  id: { type: String, default: undefined },
  className: { type: String, default: '' },
});

const model = defineModel({ type: [String, Number], default: '' });
</script>

<template>
  <input
    :id="id"
    v-model="model"
    :type="type"
    :placeholder="placeholder"
    :disabled="disabled"
    :class="
      cn(
        // Escape global `_base.scss` field-base/h-10 (unlayered beats utilities).
        'reset-base flex h-9 w-full rounded-md border border-n-weak bg-n-background px-3 py-1 text-sm text-n-slate-12 shadow-xs transition-colors',
        'placeholder:text-n-slate-11',
        'focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-n-brand',
        'disabled:cursor-not-allowed disabled:opacity-50',
        props.className
      )
    "
  />
</template>
