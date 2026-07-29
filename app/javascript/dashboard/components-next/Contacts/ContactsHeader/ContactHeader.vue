<script setup>
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import ContactSortMenu from './components/ContactSortMenu.vue';
import ContactMoreActions from './components/ContactMoreActions.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';

defineProps({
  showSearch: { type: Boolean, default: true },
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, required: true },
  buttonLabel: { type: String, default: '' },
  activeSort: { type: String, default: 'last_activity_at' },
  activeOrdering: { type: String, default: '' },
  isSegmentsView: { type: Boolean, default: false },
  hasActiveFilters: { type: Boolean, default: false },
  isLabelView: { type: Boolean, default: false },
  isActiveView: { type: Boolean, default: false },
});

const emit = defineEmits([
  'search',
  'filter',
  'update:sort',
  'add',
  'import',
  'export',
  'createSegment',
  'deleteSegment',
]);
</script>

<template>
  <header class="sticky top-0 z-20 border-b border-n-weak bg-n-background px-6">
    <div
      class="mx-auto flex min-h-14 w-full max-w-5xl flex-col items-start justify-between gap-3 py-3 sm:flex-row sm:items-center sm:gap-2 sm:py-0"
    >
      <span class="truncate text-base font-medium text-n-slate-12">
        {{ headerTitle }}
      </span>
      <div
        class="flex w-full flex-shrink-0 flex-col items-stretch gap-3 sm:w-auto sm:flex-row sm:items-center sm:gap-3"
      >
        <div v-if="showSearch" class="relative w-full sm:w-56">
          <span
            class="i-lucide-search pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-n-slate-11"
          />
          <RelayInput
            type="search"
            class-name="h-8 pl-8"
            :model-value="searchValue"
            :placeholder="$t('CONTACTS_LAYOUT.HEADER.SEARCH_PLACEHOLDER')"
            @update:model-value="emit('search', $event)"
          />
        </div>
        <div class="flex flex-shrink-0 items-center gap-2">
          <div v-if="!isLabelView && !isActiveView" class="relative">
            <RelayButton
              id="toggleContactsFilterButton"
              variant="ghost"
              size="icon"
              class="relative size-8"
              @click="emit('filter')"
            >
              <span
                :class="
                  isSegmentsView ? 'i-lucide-pen-line' : 'i-lucide-list-filter'
                "
                class="size-4"
              />
              <div
                v-if="hasActiveFilters && !isSegmentsView"
                class="absolute right-0 top-0 size-2 rounded-full bg-n-brand"
              />
            </RelayButton>
            <slot name="filter" />
          </div>
          <RelayButton
            v-if="
              hasActiveFilters &&
              !isSegmentsView &&
              !isLabelView &&
              !isActiveView
            "
            variant="ghost"
            size="icon"
            class="size-8"
            @click="emit('createSegment')"
          >
            <span class="i-lucide-save size-4" />
          </RelayButton>
          <RelayButton
            v-if="isSegmentsView && !isLabelView && !isActiveView"
            variant="ghost"
            size="icon"
            class="size-8"
            @click="emit('deleteSegment')"
          >
            <span class="i-lucide-trash size-4" />
          </RelayButton>
          <ContactSortMenu
            :active-sort="activeSort"
            :active-ordering="activeOrdering"
            @update:sort="emit('update:sort', $event)"
          />
          <ContactMoreActions
            @add="emit('add')"
            @import="emit('import')"
            @export="emit('export')"
          />
          <div class="mx-1 h-4 w-px bg-n-strong" />
          <ComposeConversation>
            <template #trigger>
              <RelayButton size="sm">
                {{ buttonLabel }}
              </RelayButton>
            </template>
          </ComposeConversation>
        </div>
      </div>
    </div>
  </header>
</template>
