<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  title: { type: String, required: true },
  description: { type: String, required: true },
  withBorder: { type: Boolean, default: false },
  hideContent: { type: Boolean, default: false },
  beta: { type: Boolean, default: false },
  asCard: { type: Boolean, default: false },
});
const { t } = useI18n();
</script>

<template>
  <section
    class="grid grid-cols-1 gap-5 [interpolate-size:allow-keywords]"
    :class="{
      'border-t border-border pt-8': withBorder && !asCard,
      'overflow-hidden rounded-xl border border-border/60 bg-card shadow-xs':
        asCard,
      'pb-8': !hideContent && !asCard,
    }"
  >
    <header
      class="grid grid-cols-4"
      :class="{ 'border-b border-border/40 p-4 sm:p-6': asCard }"
    >
      <div
        v-if="
          title || beta || $slots.title || description || $slots.description
        "
        class="col-span-3"
      >
        <h4
          v-if="title || beta || $slots.title"
          class="flex items-center gap-2 text-base font-semibold text-foreground"
        >
          <slot name="title">{{ title }}</slot>
          <div
            v-if="beta"
            v-tooltip.top="t('GENERAL.BETA_DESCRIPTION')"
            class="rounded-lg border border-primary/30 px-1 py-0.5 text-xs uppercase leading-none text-primary"
          >
            {{ t('GENERAL.BETA') }}
          </div>
        </h4>
        <p
          v-if="description || $slots.description"
          class="mt-1 text-sm leading-relaxed text-muted-foreground"
        >
          <slot name="description">{{ description }}</slot>
        </p>
      </div>
      <div class="col-span-1">
        <slot name="headerActions" />
      </div>
    </header>
    <div
      class="text-foreground transition-[height] duration-300 ease-in-out"
      :class="{
        'overflow-hidden h-0': hideContent,
        'h-auto': !hideContent,
        'p-4 sm:p-6': asCard && !hideContent,
      }"
    >
      <slot />
    </div>
  </section>
</template>
