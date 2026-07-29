<script setup>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import { RelayButton } from 'dashboard/components-next/relay';
import InboxCard from 'dashboard/components-next/captain/assistant/InboxCard.vue';
import { inboxes } from 'dashboard/components-next/captain/pageComponents/emptyStates/captainEmptyStateContent.js';

const emit = defineEmits(['click']);

const onClick = () => {
  emit('click');
};
</script>

<template>
  <EmptyStateLayout
    :title="$t('CAPTAIN.INBOXES.EMPTY_STATE.TITLE')"
    :subtitle="$t('CAPTAIN.INBOXES.EMPTY_STATE.SUBTITLE')"
    :action-perms="['administrator']"
  >
    <template #empty-state-item>
      <div class="grid grid-cols-1 gap-4 overflow-hidden p-px">
        <InboxCard
          v-for="(inbox, index) in inboxes.slice(0, 5)"
          :id="inbox.id"
          :key="`inbox-${index}`"
          :inbox="inbox"
        />
      </div>
    </template>
    <template #actions>
      <RelayButton @click="onClick">
        <span class="i-lucide-plus size-4" />
        {{ $t('CAPTAIN.INBOXES.ADD_NEW') }}
      </RelayButton>
    </template>
  </EmptyStateLayout>
</template>
