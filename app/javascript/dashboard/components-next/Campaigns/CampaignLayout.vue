<script setup>
import { vOnClickOutside } from '@vueuse/components';
import { RelayButton } from 'dashboard/components-next/relay';

defineProps({
  headerTitle: {
    type: String,
    default: '',
  },
  buttonLabel: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['click', 'close']);

const handleButtonClick = () => {
  emit('click');
};
</script>

<template>
  <section class="flex flex-col w-full h-full overflow-hidden bg-background">
    <header
      class="sticky top-0 z-10 px-6 lg:px-10 border-b border-border bg-background/80 backdrop-blur-md"
    >
      <div class="w-full max-w-7xl mx-auto">
        <div class="flex items-center justify-between w-full h-16 gap-2">
          <span class="text-base font-semibold text-foreground">
            {{ headerTitle }}
          </span>
          <div
            v-on-click-outside="[
              () => emit('close'),
              // This will prevent closing the modal when the editor Create link popup is open
              { ignore: ['dialog.ProseMirror-prompt-backdrop'] },
            ]"
            class="relative group/campaign-button"
          >
            <RelayButton
              variant="default"
              size="sm"
              class="group-hover/campaign-button:brightness-110 h-8 gap-2 font-medium"
              @click="handleButtonClick"
            >
              <span class="i-lucide-plus size-4" />
              {{ buttonLabel }}
            </RelayButton>
            <slot name="action" />
          </div>
        </div>
      </div>
    </header>

    <main class="flex-1 px-6 lg:px-10 overflow-y-auto bg-background/50">
      <div class="w-full max-w-7xl mx-auto py-8">
        <slot name="default" />
      </div>
    </main>
  </section>
</template>
