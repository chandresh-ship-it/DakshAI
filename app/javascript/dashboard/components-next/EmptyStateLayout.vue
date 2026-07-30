<script setup>
import Policy from 'dashboard/components/policy.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  subtitle: {
    type: String,
    required: true,
  },
  actionPerms: {
    type: Array,
    default: () => [],
  },
  showBackdrop: {
    type: Boolean,
    default: true,
  },
});

defineOptions({
  inheritAttrs: false,
});
</script>

<template>
  <section
    class="relative flex w-full flex-1 flex-col items-center justify-center overflow-hidden py-24 text-center"
  >
    <div
      v-if="showBackdrop"
      class="pointer-events-none absolute inset-0 z-0 flex select-none flex-col gap-4 overflow-hidden"
      aria-hidden="true"
    >
      <div
        class="absolute inset-0 z-10 bg-gradient-to-b from-background/40 via-background/90 to-background"
      />
      <div class="relative z-0 flex w-full flex-col gap-4">
        <slot name="empty-state-item" />
      </div>
    </div>

    <div class="relative z-20 flex flex-col items-center">
      <h2 class="mb-3 text-[20px] font-semibold text-foreground">
        {{ title }}
      </h2>
      <div v-if="subtitle" class="relative mx-auto mb-8 max-w-md">
        <p class="text-[15px] leading-relaxed text-muted-foreground">
          {{ subtitle }}
        </p>
      </div>
      <Policy :permissions="actionPerms">
        <slot name="actions" />
      </Policy>
    </div>
  </section>
</template>
