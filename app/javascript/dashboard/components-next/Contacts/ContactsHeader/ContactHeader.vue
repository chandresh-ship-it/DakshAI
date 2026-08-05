<script setup>
import { RelayButton, RelayInput } from 'dashboard/components-next/relay';
import ContactMoreActions from './components/ContactMoreActions.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';

defineProps({
  showSearch: { type: Boolean, default: true },
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, required: true },
  buttonLabel: { type: String, default: '' },
  isSegmentsView: { type: Boolean, default: false },
  hasActiveFilters: { type: Boolean, default: false },
  isLabelView: { type: Boolean, default: false },
  isActiveView: { type: Boolean, default: false },
  showTitle: { type: Boolean, default: false },
});

const emit = defineEmits([
  'search',
  'filter',
  'add',
  'import',
  'export',
  'createSegment',
  'deleteSegment',
]);
</script>

<template>
  <div class="flex flex-col gap-0 border-b border-border/40 bg-background">
    <div v-if="showTitle" class="flex items-center justify-between px-6 pt-4">
      <span class="truncate text-base font-medium text-foreground">
        {{ headerTitle }}
      </span>
    </div>

    <div
      class="flex flex-col items-stretch justify-between gap-3 px-6 py-4 sm:flex-row sm:items-center"
    >
      <div v-if="showSearch" class="relative w-full max-w-sm">
        <span
          class="i-lucide-search pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground"
        />
        <RelayInput
          type="search"
          class-name="h-10 rounded-lg border-border/60 bg-card pl-9 text-sm shadow-sm"
          :model-value="searchValue"
          :placeholder="$t('CONTACTS_LAYOUT.HEADER.SEARCH_PLACEHOLDER')"
          @update:model-value="emit('search', $event)"
        />
      </div>
      <div v-else class="hidden text-sm font-medium text-foreground sm:block">
        {{ headerTitle }}
      </div>

      <div class="flex flex-shrink-0 items-center gap-2 sm:gap-3">
        <slot name="columns" />

        <RelayButton
          v-if="!isLabelView && !isActiveView"
          id="toggleContactsFilterButton"
          variant="outline"
          class="h-10 gap-2 rounded-lg px-3 text-sm font-medium shadow-sm"
          @click="emit('filter')"
        >
          <span
            :class="
              isSegmentsView ? 'i-lucide-pen-line' : 'i-lucide-list-filter'
            "
            class="size-4"
          />
          {{
            isSegmentsView
              ? $t('CONTACTS_LAYOUT.FILTER.EDIT_SEGMENT')
              : $t('CONTACTS_LAYOUT.HEADER.FILTERS_BUTTON')
          }}
          <span
            v-if="hasActiveFilters && !isSegmentsView"
            class="size-1.5 rounded-full bg-primary"
          />
        </RelayButton>

        <RelayButton
          v-if="
            hasActiveFilters && !isSegmentsView && !isLabelView && !isActiveView
          "
          variant="outline"
          size="icon"
          class="size-10 rounded-lg shadow-sm"
          @click="emit('createSegment')"
        >
          <span class="i-lucide-save size-4" />
        </RelayButton>

        <RelayButton
          v-if="isSegmentsView && !isLabelView && !isActiveView"
          variant="outline"
          size="icon"
          class="size-10 rounded-lg shadow-sm"
          @click="emit('deleteSegment')"
        >
          <span class="i-lucide-trash size-4" />
        </RelayButton>

        <ContactMoreActions
          @add="emit('add')"
          @import="emit('import')"
          @export="emit('export')"
        />

        <div class="mx-0.5 hidden h-4 w-px bg-border sm:block" />

        <ComposeConversation>
          <template #trigger>
            <RelayButton
              variant="outline"
              class="h-10 rounded-lg px-3 text-sm font-medium shadow-sm"
            >
              {{ buttonLabel }}
            </RelayButton>
          </template>
        </ComposeConversation>
      </div>
    </div>
  </div>
</template>
