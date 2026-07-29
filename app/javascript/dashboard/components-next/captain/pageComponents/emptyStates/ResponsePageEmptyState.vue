<script setup>
import { useBranding } from 'shared/composables/useBranding';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import ResponseCard from 'dashboard/components-next/captain/assistant/ResponseCard.vue';
import { responsesList } from 'dashboard/components-next/captain/pageComponents/emptyStates/captainEmptyStateContent.js';

import { computed } from 'vue';

const props = defineProps({
  variant: {
    type: String,
    default: 'approved',
    validator: value => ['approved', 'pending'].includes(value),
  },
  hasActiveFilters: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['click', 'clearFilters']);

const isApproved = computed(() => props.variant === 'approved');
const isPending = computed(() => props.variant === 'pending');

const { replaceInstallationName } = useBranding();

const onClick = () => {
  emit('click');
};

const onClearFilters = () => {
  emit('clearFilters');
};
</script>

<template>
  <EmptyStateLayout
    :title="
      isPending
        ? $t('CAPTAIN.RESPONSES.EMPTY_STATE.NO_PENDING_TITLE')
        : $t('CAPTAIN.RESPONSES.EMPTY_STATE.TITLE')
    "
    :subtitle="isApproved ? $t('CAPTAIN.RESPONSES.EMPTY_STATE.SUBTITLE') : ''"
    :action-perms="['administrator']"
    :show-backdrop="isApproved"
  >
    <template v-if="isApproved" #empty-state-item>
      <div class="grid grid-cols-1 gap-4 p-px overflow-hidden">
        <ResponseCard
          v-for="(response, index) in responsesList.slice(0, 5)"
          :id="response.id"
          :key="`response-${index}`"
          :question="replaceInstallationName(response.question)"
          :answer="replaceInstallationName(response.answer)"
          :status="response.status"
          :assistant="response.assistant"
          :created-at="response.created_at"
          :updated-at="response.created_at"
        />
      </div>
    </template>
    <template #actions>
      <div class="flex flex-col items-center gap-3">
        <RelayButton v-if="isApproved" @click="onClick">
          <span class="i-lucide-plus size-4" />
          {{ $t('CAPTAIN.RESPONSES.ADD_NEW') }}
        </RelayButton>
        <RelayButton
          v-else-if="isPending && hasActiveFilters"
          variant="link"
          size="sm"
          @click="onClearFilters"
        >
          {{ $t('CAPTAIN.RESPONSES.EMPTY_STATE.CLEAR_SEARCH') }}
        </RelayButton>
      </div>
    </template>
  </EmptyStateLayout>
</template>
