<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import RelayWorkspaceMenu from './RelayWorkspaceMenu.vue';

defineProps({
  title: { type: String, default: 'Dashboard' },
  showDesktopToggle: { type: Boolean, default: true },
});

defineEmits([
  'toggleSidebar',
  'openSearch',
  'toggleCollapse',
  'showCreateAccountModal',
]);

const { t } = useI18n();
const searchShortcut = useKbd(['$mod', 'k']);

const searchLabel = computed(() => t('COMBOBOX.SEARCH_PLACEHOLDER'));
</script>

<template>
  <header
    class="sticky top-0 z-40 flex h-16 w-full shrink-0 items-center justify-between border-b border-n-weak bg-n-background px-4 py-3 sm:px-6"
  >
    <div class="flex min-w-0 flex-none items-center gap-3">
      <button
        type="button"
        class="inline-flex size-8 shrink-0 items-center justify-center rounded-md text-n-slate-11 transition-colors hover:bg-n-alpha-2 hover:text-n-slate-12 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-n-brand md:hidden"
        @click="$emit('toggleSidebar')"
      >
        <span class="i-lucide-panel-left size-4" />
        <span class="sr-only">{{ t('SIDEBAR.TOGGLE_SIDEBAR') }}</span>
      </button>
      <button
        v-if="showDesktopToggle"
        type="button"
        class="hidden size-8 shrink-0 items-center justify-center rounded-md text-n-slate-11 transition-colors hover:bg-n-alpha-2 hover:text-n-slate-12 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-n-brand md:inline-flex"
        @click="$emit('toggleCollapse')"
      >
        <span class="i-lucide-panel-left size-4" />
        <span class="sr-only">{{ t('SIDEBAR.COLLAPSE_SIDEBAR') }}</span>
      </button>
      <h1 class="truncate text-base font-medium text-n-slate-12">
        {{ title }}
      </h1>
    </div>

    <div class="hidden flex-1 justify-center px-4 md:flex">
      <button
        type="button"
        class="flex h-10 w-full max-w-md items-center gap-3 rounded-full border border-n-weak bg-n-background px-4 text-sm text-n-slate-11 shadow-sm transition-colors hover:bg-n-alpha-2 hover:text-n-slate-12"
        @click="$emit('openSearch')"
      >
        <span class="i-lucide-search size-4 shrink-0" />
        <span class="flex-1 text-left">{{ searchLabel }}</span>
        <kbd
          class="rounded border border-n-weak bg-n-alpha-1 px-1.5 py-0.5 text-[10px] font-medium text-n-slate-11"
        >
          {{ searchShortcut }}
        </kbd>
      </button>
    </div>

    <div class="ml-auto flex flex-none items-center justify-end gap-2 sm:gap-3">
      <slot name="actions" />
      <RouterLink
        :to="{ name: 'notifications_index' }"
        class="relative inline-flex size-9 items-center justify-center rounded-full border border-n-weak bg-n-background text-n-slate-11 shadow-sm transition-colors hover:bg-n-alpha-2 hover:text-n-slate-12"
      >
        <span class="i-lucide-bell size-4" />
        <span class="sr-only">{{ t('SIDEBAR.NOTIFICATIONS') }}</span>
      </RouterLink>
      <slot name="profile">
        <RelayWorkspaceMenu
          @show-create-account-modal="$emit('showCreateAccountModal')"
        />
      </slot>
    </div>
  </header>
</template>
