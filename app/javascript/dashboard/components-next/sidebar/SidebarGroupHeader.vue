<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store.js';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  to: { type: [Object, String], default: '' },
  label: { type: String, default: '' },
  icon: { type: [String, Object], default: '' },
  expandable: { type: Boolean, default: false },
  isExpanded: { type: Boolean, default: false },
  isActive: { type: Boolean, default: false },
  hasActiveChild: { type: Boolean, default: false },
  getterKeys: { type: Object, default: () => ({}) },
});

const emit = defineEmits(['toggle']);

const showBadge = useMapGetter(props.getterKeys.badge);
const dynamicCount = useMapGetter(props.getterKeys.count);
const count = computed(() =>
  dynamicCount.value > 99 ? '99+' : dynamicCount.value
);

const isHighlighted = computed(() => props.isActive || props.hasActiveChild);
</script>

<template>
  <component
    :is="to ? 'router-link' : 'button'"
    class="peer/menu-button relative flex h-9 min-w-0 w-full items-center gap-3 rounded-md p-2 py-2 text-left text-sm outline-none transition-colors"
    role="button"
    draggable="false"
    :to="to || undefined"
    :type="to ? undefined : 'button'"
    :title="label"
    :class="{
      'font-medium text-n-brand': isHighlighted,
      'text-n-slate-11 hover:bg-n-alpha-2 hover:text-n-slate-12':
        !isHighlighted,
    }"
    @click.stop="emit('toggle')"
  >
    <span
      v-if="isHighlighted"
      class="absolute inset-y-1.5 ltr:-left-2 rtl:-right-2 w-[3px] rounded-r-md bg-n-brand rtl:rounded-l-md rtl:rounded-r-none"
    />
    <div v-if="icon" class="relative flex shrink-0 items-center">
      <Icon
        :icon="icon"
        class="size-4 shrink-0"
        :class="isHighlighted ? 'text-n-brand' : 'text-n-slate-11'"
      />
      <span
        v-if="showBadge"
        class="absolute -top-px size-2 rounded-full border border-n-solid-1 bg-n-brand ltr:-right-px rtl:-left-px"
      />
    </div>
    <div class="flex min-w-0 flex-1 items-center gap-1.5">
      <span class="truncate">
        {{ label }}
      </span>
      <span
        v-if="dynamicCount && !expandable"
        class="flex-shrink-0 rounded-md px-1 text-center text-xs font-medium leading-5 outline outline-1 capitalize"
        :class="{
          'text-n-brand outline-n-brand/30': isHighlighted,
          'text-n-slate-11 outline-n-strong': !isHighlighted,
        }"
      >
        {{ count }}
      </span>
    </div>
    <span
      v-if="expandable"
      class="i-lucide-chevron-right ml-auto size-4 shrink-0 text-n-slate-11 transition-transform duration-200"
      :class="[{ 'rotate-90': isExpanded }]"
      @click.stop="emit('toggle')"
    />
  </component>
</template>
