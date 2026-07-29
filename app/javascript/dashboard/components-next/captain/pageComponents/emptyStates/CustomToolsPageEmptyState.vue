<script setup>
import { useAccount } from 'dashboard/composables/useAccount';
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import FeatureSpotlight from 'dashboard/components-next/feature-spotlight/FeatureSpotlight.vue';
import { RelayButton } from 'dashboard/components-next/relay';

const emit = defineEmits(['click']);
const { isOnChatwootCloud } = useAccount();

const onClick = () => {
  emit('click');
};
</script>

<template>
  <FeatureSpotlight
    :title="$t('CAPTAIN.CUSTOM_TOOLS.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
    :note="$t('CAPTAIN.CUSTOM_TOOLS.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
    fallback-thumbnail="/assets/images/dashboard/captain/assistant-light.svg"
    fallback-thumbnail-dark="/assets/images/dashboard/captain/assistant-dark.svg"
    learn-more-url="https://newrelay.com/hc/captain-tools"
    class="mb-8"
    :hide-actions="!isOnChatwootCloud"
  />
  <EmptyStateLayout
    :title="$t('CAPTAIN.CUSTOM_TOOLS.EMPTY_STATE.TITLE')"
    :subtitle="$t('CAPTAIN.CUSTOM_TOOLS.EMPTY_STATE.SUBTITLE')"
    :action-perms="['administrator']"
  >
    <template #empty-state-item>
      <div class="min-h-[600px]" />
    </template>
    <template #actions>
      <RelayButton @click="onClick">
        <span class="i-lucide-plus size-4" />
        {{ $t('CAPTAIN.CUSTOM_TOOLS.ADD_NEW') }}
      </RelayButton>
    </template>
  </EmptyStateLayout>
</template>
