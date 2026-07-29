<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import BulkLabelActions from 'dashboard/components/widgets/conversation/conversationBulkActions/BulkLabelActions.vue';
import Policy from 'dashboard/components/policy.vue';

const props = defineProps({
  visibleContactIds: {
    type: Array,
    default: () => [],
  },
  selectedContactIds: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'clearSelection',
  'assignLabels',
  'removeLabels',
  'toggleAll',
  'deleteSelected',
]);

const { t } = useI18n();

const selectedCount = computed(() => props.selectedContactIds.length);
const totalVisibleContacts = computed(() => props.visibleContactIds.length);

const selectAllLabel = computed(() => {
  if (!totalVisibleContacts.value) {
    return '';
  }

  return t('CONTACTS_BULK_ACTIONS.SELECT_ALL', {
    count: totalVisibleContacts.value,
  });
});

const selectedCountLabel = computed(() =>
  t('CONTACTS_BULK_ACTIONS.SELECTED_COUNT', {
    count: selectedCount.value,
  })
);

const allItems = computed(() =>
  props.visibleContactIds.map(id => ({
    id,
  }))
);

const selectionModel = computed({
  get: () => new Set(props.selectedContactIds),
  set: newSet => {
    if (!props.visibleContactIds.length) {
      emit('toggleAll', false);
      return;
    }

    const shouldSelectAll = props.visibleContactIds.every(id => newSet.has(id));
    emit('toggleAll', shouldSelectAll);
  },
});

const handleAssignLabels = labels => {
  emit('assignLabels', labels);
};

const handleRemoveLabels = labels => {
  emit('removeLabels', labels);
};
</script>

<template>
  <div
    class="sticky top-0 z-10 bg-gradient-to-b from-n-background from-90% to-transparent pb-2 pt-1"
  >
    <BulkSelectBar
      v-model="selectionModel"
      :all-items="allItems"
      :select-all-label="selectAllLabel"
      :selected-count-label="selectedCountLabel"
      class="justify-between py-2 ltr:!pr-3 rtl:!pl-3"
    >
      <template #primaryActions>
        <RelayButton
          variant="ghost"
          size="sm"
          class="px-1"
          @click="emit('clearSelection')"
        >
          {{ t('CONTACTS_BULK_ACTIONS.CLEAR_SELECTION') }}
        </RelayButton>
      </template>
      <template #actions>
        <div class="ml-auto flex items-center gap-2">
          <BulkLabelActions
            type="contact"
            :is-loading="isLoading"
            :disabled="!selectedCount"
            @assign="handleAssignLabels"
          />
          <BulkLabelActions
            type="contact"
            action="remove"
            :is-loading="isLoading"
            :disabled="!selectedCount"
            @remove="handleRemoveLabels"
          />
          <div class="h-3 w-px rounded-lg bg-n-weak" />
          <Policy :permissions="['administrator']">
            <RelayButton
              v-tooltip.bottom="t('CONTACTS_BULK_ACTIONS.DELETE_CONTACTS')"
              variant="destructive"
              size="sm"
              class="px-2"
              :disabled="!selectedCount || isLoading"
              :aria-label="t('CONTACTS_BULK_ACTIONS.DELETE_CONTACTS')"
              @click="emit('deleteSelected')"
            >
              <span class="i-lucide-trash size-4" />
              <span class="hidden md:inline">
                {{ t('CONTACTS_BULK_ACTIONS.DELETE_CONTACTS') }}
              </span>
            </RelayButton>
          </Policy>
        </div>
      </template>
    </BulkSelectBar>
  </div>
</template>
