<script setup>
import CompanyHeader from './CompaniesHeader/CompanyHeader.vue';

defineProps({
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, default: '' },
  headerSubtitle: { type: String, default: '' },
  visibleColumns: {
    type: Object,
    default: () => ({
      company: true,
      industry: true,
      phone: true,
      email: true,
      contacts: true,
      website: true,
      owner: true,
    }),
  },
  activeFilters: { type: Array, default: () => [] },
  showToolbar: { type: Boolean, default: true },
  isEmptyState: { type: Boolean, default: false },
});

const emit = defineEmits([
  'search',
  'create',
  'import',
  'filter',
  'clearFilters',
  'removeFilter',
  'update:visibleColumns',
]);
</script>

<template>
  <section class="relative flex h-full w-full overflow-hidden bg-background/50">
    <div class="flex h-full w-full flex-col">
      <div
        v-if="!isEmptyState"
        class="mx-auto w-full max-w-[1600px] shrink-0 px-8 pt-8"
      >
        <CompanyHeader
          :search-value="searchValue"
          :header-title="headerTitle"
          :header-subtitle="headerSubtitle"
          :visible-columns="visibleColumns"
          :active-filters="activeFilters"
          :show-toolbar="showToolbar"
          @search="emit('search', $event)"
          @create="emit('create')"
          @import="emit('import')"
          @filter="emit('filter')"
          @clear-filters="emit('clearFilters')"
          @remove-filter="emit('removeFilter', $event)"
          @update:visible-columns="emit('update:visibleColumns', $event)"
        />
      </div>

      <main
        class="flex-1 overflow-y-auto"
        :class="isEmptyState ? 'px-4 py-12 md:py-16' : 'px-8 pb-8'"
      >
        <div
          class="mx-auto w-full"
          :class="
            isEmptyState
              ? 'max-w-5xl'
              : 'max-w-[1600px] animate-in fade-in duration-500'
          "
        >
          <slot />
        </div>
      </main>
    </div>
  </section>
</template>
