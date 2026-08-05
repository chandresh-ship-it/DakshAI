<script setup>
import EmojiOrIcon from 'shared/components/EmojiOrIcon.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  compact: {
    type: Boolean,
    default: false,
  },
  icon: {
    type: String,
    default: '',
  },
  emoji: {
    type: String,
    default: '',
  },
  isOpen: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['toggle']);

const onToggle = () => {
  emit('toggle');
};
</script>

<template>
  <div class="text-sm border rounded-lg border-border bg-card">
    <button
      class="flex items-center select-none w-full m-0 cursor-grab justify-between py-2 px-4 drag-handle"
      @click.stop="onToggle"
    >
      <div class="flex justify-between">
        <EmojiOrIcon class="inline-block w-5" :icon="icon" :emoji="emoji" />
        <h5 class="text-foreground text-sm mb-0 py-0 pr-2 pl-0 font-medium">
          {{ title }}
        </h5>
      </div>
      <div class="flex flex-row items-center">
        <slot name="button" />
        <span
          class="size-4 text-muted-foreground transition-transform duration-200 i-lucide-chevron-down"
          :class="{ 'rotate-180': isOpen }"
        />
      </div>
    </button>
    <div
      v-if="isOpen"
      class="border-t border-border"
      :class="compact ? 'p-0' : 'px-2 py-4'"
    >
      <slot />
    </div>
  </div>
</template>
