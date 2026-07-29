<script setup>
import { computed } from 'vue';
import { RelayButton, RelayCheckbox } from 'dashboard/components-next/relay';

const props = defineProps({
  allItems: {
    type: Array,
    required: true,
  },
  selectAllLabel: {
    type: String,
    default: '',
  },
  selectedCountLabel: {
    type: String,
    default: '',
  },
  deleteLabel: {
    type: String,
    default: 'Delete',
  },
});

const emit = defineEmits(['bulkDelete']);

const modelValue = defineModel({
  type: Set,
  default: () => new Set(),
});

const selectedCount = computed(() => modelValue.value.size);
const visibleItemIds = computed(() => props.allItems.map(item => item.id));
const visibleItemCount = computed(() => visibleItemIds.value.length);
const selectedVisibleCount = computed(
  () => visibleItemIds.value.filter(id => modelValue.value.has(id)).length
);
const hasSelected = computed(() => selectedCount.value > 0);
const isIndeterminate = computed(
  () =>
    selectedVisibleCount.value > 0 &&
    selectedVisibleCount.value < visibleItemCount.value
);
const allSelected = computed(
  () =>
    visibleItemCount.value > 0 &&
    selectedVisibleCount.value === visibleItemCount.value
);

const bulkCheckboxState = computed({
  get: () => allSelected.value,
  set: shouldSelectAll => {
    if (!visibleItemCount.value) {
      return;
    }

    const updatedSelection = new Set(modelValue.value);
    if (shouldSelectAll) {
      visibleItemIds.value.forEach(id => updatedSelection.add(id));
    } else {
      visibleItemIds.value.forEach(id => updatedSelection.delete(id));
    }
    modelValue.value = updatedSelection;
  },
});
</script>

<template>
  <transition
    name="slide-fade"
    enter-active-class="transition-all duration-300 ease-out"
    enter-from-class="opacity-0 transform ltr:-translate-x-4 rtl:translate-x-4"
    enter-to-class="opacity-100 transform translate-x-0"
    leave-active-class="hidden opacity-0"
  >
    <div
      v-if="hasSelected"
      class="flex w-full items-center justify-between gap-3 rounded-xl border border-n-weak bg-n-solid-2 px-4 py-3 shadow-sm"
    >
      <div class="flex min-w-0 items-center gap-4">
        <div class="flex min-w-0 items-center gap-2.5">
          <RelayCheckbox
            v-model="bulkCheckboxState"
            :indeterminate="isIndeterminate"
          />
          <span
            class="truncate text-sm font-medium tabular-nums text-n-slate-12"
          >
            {{ selectAllLabel }}
          </span>
        </div>
        <span class="truncate text-sm tabular-nums text-n-slate-11">
          {{ selectedCountLabel }}
        </span>
        <div v-if="$slots.primaryActions" class="h-4 w-px bg-n-strong" />
        <slot v-if="$slots.primaryActions" name="primaryActions" />
      </div>
      <div class="flex items-center gap-3">
        <slot v-if="$slots.secondaryActions" name="secondaryActions" />
        <div v-if="$slots.secondaryActions" class="h-4 w-px bg-n-strong" />
        <div class="flex items-center gap-3">
          <slot name="actions" :selected-count="selectedCount">
            <RelayButton
              variant="ghost"
              size="sm"
              class="border border-n-weak text-n-ruby-11 hover:border-transparent hover:bg-n-ruby-9/10 hover:text-n-ruby-11"
              @click="emit('bulkDelete')"
            >
              <span class="i-lucide-trash size-3.5" />
              {{ deleteLabel }}
            </RelayButton>
          </slot>
        </div>
      </div>
    </div>
    <div v-else class="flex items-center gap-3">
      <slot name="default-actions" />
    </div>
  </transition>
</template>
