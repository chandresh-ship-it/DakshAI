<script setup>
import BillingHeader from './BillingHeader.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div
    class="space-y-5 overflow-hidden rounded-xl border border-border/60 bg-card py-5 shadow-xs"
  >
    <BillingHeader :title :description class="px-5 sm:px-6">
      <slot name="action" />
    </BillingHeader>
    <slot />
  </div>
</template>
