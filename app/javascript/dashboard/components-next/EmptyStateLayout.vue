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
    class="relative flex min-h-[400px] w-full flex-1 flex-col items-center justify-center overflow-hidden rounded-xl py-20 text-center"
  >
    <div
      v-if="showBackdrop"
      class="pointer-events-none absolute inset-0 z-0 flex select-none flex-col gap-3 overflow-hidden opacity-40"
      aria-hidden="true"
    >
      <div
        class="absolute inset-0 z-10 bg-gradient-to-b from-background/10 via-background/80 to-background"
      />
      <div class="relative z-0 flex w-full flex-col gap-3">
        <slot name="empty-state-item" />
      </div>
    </div>

    <div class="relative z-20 mt-12 flex flex-col items-center px-4">
      <h2 class="mb-3 text-[20px] font-semibold tracking-tight text-foreground">
        {{ title }}
      </h2>
      <div v-if="subtitle" class="relative mx-auto mb-7 max-w-md">
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
