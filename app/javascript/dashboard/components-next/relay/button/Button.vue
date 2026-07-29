<script setup>
import { computed, useAttrs } from 'vue';
import { cn } from '../utils/cn';

const props = defineProps({
  variant: {
    type: String,
    default: 'default',
    validator: value =>
      [
        'default',
        'destructive',
        'outline',
        'secondary',
        'ghost',
        'link',
      ].includes(value),
  },
  size: {
    type: String,
    default: 'default',
    validator: value => ['default', 'sm', 'lg', 'icon'].includes(value),
  },
  as: { type: String, default: 'button' },
  disabled: { type: Boolean, default: false },
  type: { type: String, default: 'button' },
});

defineOptions({ inheritAttrs: false });

const attrs = useAttrs();

const base =
  'inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-n-brand disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0';

const variants = {
  default: 'bg-n-brand text-white shadow-sm hover:bg-n-brand/90',
  destructive: 'bg-n-ruby-9 text-white shadow-sm hover:bg-n-ruby-10',
  outline:
    'border border-n-weak bg-n-background shadow-sm hover:bg-n-alpha-2 hover:text-n-slate-12',
  secondary: 'bg-n-alpha-2 text-n-slate-12 hover:bg-n-alpha-3',
  ghost: 'hover:bg-n-alpha-2 hover:text-n-slate-12',
  link: 'text-n-brand underline-offset-4 hover:underline',
};

const sizes = {
  default: 'h-9 px-4 py-2',
  sm: 'h-8 rounded-md px-3 text-xs',
  lg: 'h-10 rounded-md px-6',
  icon: 'size-9',
};

const classes = computed(() =>
  cn(base, variants[props.variant], sizes[props.size], attrs.class)
);
</script>

<template>
  <component
    :is="as"
    v-bind="{ ...attrs, class: undefined }"
    :type="as === 'button' ? type : undefined"
    :disabled="as === 'button' ? disabled : undefined"
    :class="classes"
  >
    <slot />
  </component>
</template>
