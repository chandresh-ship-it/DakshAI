<script setup>
import { cn } from '../utils/cn';
</script>

<template>
  <div
    role="tablist"
    :class="
      cn(
        'inline-flex h-9 items-center justify-center rounded-lg bg-n-alpha-1 p-1 text-n-slate-11'
      )
    "
  >
    <slot />
  </div>
</template>
