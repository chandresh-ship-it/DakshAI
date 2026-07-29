<script setup>
import { computed } from 'vue';
import { cn } from '../utils/cn';

const props = defineProps({
  variant: {
    type: String,
    default: 'default',
    validator: value =>
      ['default', 'secondary', 'destructive', 'outline'].includes(value),
  },
});

const base =
  'inline-flex items-center rounded-md border px-2 py-0.5 text-xs font-medium transition-colors focus:outline-none focus:ring-1 focus:ring-n-brand';

const variants = {
  default: 'border-transparent bg-n-brand text-white',
  secondary: 'border-transparent bg-n-alpha-2 text-n-slate-12',
  destructive: 'border-transparent bg-n-ruby-9 text-white',
  outline: 'border-n-weak text-n-slate-12',
};

const classes = computed(() => cn(base, variants[props.variant]));
</script>

<template>
  <span :class="classes">
    <slot />
  </span>
</template>
