<script setup>
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
  <div class="grid grid-cols-[1fr_auto] gap-5">
    <div>
      <span class="text-base font-medium text-foreground">
        {{ title }}
      </span>
      <p class="mt-1 text-sm text-muted-foreground">
        {{ description }}
      </p>
    </div>
    <slot />
  </div>
</template>
