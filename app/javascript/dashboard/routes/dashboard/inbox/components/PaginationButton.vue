<script>
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    totalLength: {
      type: Number,
      default: 0,
    },
    currentIndex: {
      type: Number,
      default: 0,
    },
  },
  emits: ['prev', 'next'],
  computed: {
    isUpDisabled() {
      return this.currentIndex === 1;
    },
    isDownDisabled() {
      return this.currentIndex === this.totalLength || this.totalLength <= 1;
    },
  },
  methods: {
    handleUpClick() {
      if (this.currentIndex > 1) {
        this.$emit('prev');
      }
    },
    handleDownClick() {
      if (this.currentIndex < this.totalLength) {
        this.$emit('next');
      }
    },
  },
};
</script>

<template>
  <div class="flex gap-2.5 items-center">
    <div
      class="flex items-center gap-1 whitespace-nowrap text-xs text-muted-foreground font-medium"
    >
      <span class="tabular-nums text-foreground">
        {{ totalLength <= 1 ? '1' : currentIndex }}
      </span>
      <span v-if="totalLength > 1" class="relative -top-px">/</span>
      <span v-if="totalLength > 1" class="tabular-nums">
        {{ totalLength }}
      </span>
    </div>
    <div class="flex gap-0.5 items-center">
      <NextButton
        icon="i-lucide-chevron-up"
        xs
        slate
        ghost
        :disabled="isUpDisabled"
        @click="handleUpClick"
      />
      <NextButton
        icon="i-lucide-chevron-down"
        xs
        slate
        ghost
        :disabled="isDownDisabled"
        @click="handleDownClick"
      />
    </div>
  </div>
</template>
